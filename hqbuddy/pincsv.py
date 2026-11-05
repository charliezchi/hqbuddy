# -*- coding: utf-8 -*-
"""Pin-table exchange between .upc physical constraints and CSV (Excel workflow).

hqbuddy -pin2csv [<.hqprj>] [-o <out.csv>]
    UPC pin assignments + the device package-pin table ('udev.pkg.report,
    one design-free hqfpga session) -> fully joined CSV: every package pin
    with bank / pad location / function, plus Signal Name and IO attributes
    for assigned pins.

hqbuddy -csv2upc <in.csv> [-o <out.upc>] [-device <part>|<.hqprj>]
    CSV back to a phycst.pin.set UPC.  Reads the -pin2csv format (header
    driven; extra non-fixed columns are carried back as -attr entries);
    when a device is resolvable every ball is checked against dv.get_pin_bank
    in one session first.

Vendor note (verified on 3.1.1 FT110126): the native TCL pair pin2csv/csv2upc
is unusable for round-trips — pin2csv leaves Pad Location empty for assigned
user IOs (pre- and post-pack) and csv2upc silently emits an empty .upc for
pin2csv's own output (PTC006 without the NOTE header).  Both directions are
therefore implemented locally.

A .upc is a TCL script; conditional pin tables (set/if board-variant
switching) are resolved by EVALUATING the UPC in a throwaway session with
recorder stubs in place of the phycst.* commands.  -pin2csv therefore
exports the evaluated branch; -csv2upc emits a flat unconditional UPC of
phycst.pin.set lines only (vccio.set etc. are out of the CSV round-trip).
"""

import csv
import glob
import os
import subprocess
import sys

from . import device, launcher
from .hqprj_parser import parse_hqprj

_PIN_SET = "phycst.pin.set"


def _eval_upc(upc_path: str) -> list:
    """Evaluate a .upc in a real TCL session and record the phycst.* calls.

    A .upc is a TCL script — board-variant switching via set/if (e.g.
    `set psram_sel PSRAM0`) is routine, so line-grepping pin.set picks up
    BOTH branches and produces conflicting assignments.  Instead, every
    phycst.* command is renamed away and replaced by a recorder proc, the
    UPC is sourced, and the evaluated calls come back as PHYCST-CALL/ARG
    lines.  Needs no design and no dv.setup (pure TCL evaluation).

    Returns [{cmd, args}] in evaluation order."""
    version = launcher.require_hqfpga_version()
    upc_tcl = upc_path.replace("\\", "/")
    tcl = (
        'set __saved {}\n'
        'foreach fam {phycst ioh} {\n'
        '    foreach c [info commands ${fam}.*] {\n'
        '        lappend __saved $c\n'
        '        rename $c __hqbuddy_orig__$c\n'
        '        proc ::$c {args} {\n'
        '            puts "PHYCST-CALL: [lindex [info level 0] 0]"\n'
        '            foreach __a $args { puts "PHYCST-ARG: $__a" }\n'
        '        }\n'
        '    }\n'
        '}\n'
        'catch {rename unknown __hqbuddy_orig_unknown}\n'
        'proc unknown {args} {\n'
        '    puts "UNKNOWN-CALL: [lindex [info level 0] 0]"\n'
        '    foreach __a $args { puts "UNKNOWN-ARG: $__a" }\n'
        '}\n'
        f'if {{[catch {{source {{{upc_tcl}}}}} e]}} {{ puts "UPC-EVAL-FAIL: $e" }}\n'
        'puts "@@UPC-EVAL-DONE@@"\n'
    )
    import tempfile
    tf = tempfile.NamedTemporaryFile("w", suffix=".tcl", delete=False,
                                     encoding="utf-8")
    tf.write(tcl)
    tf.close()
    try:
        proc = subprocess.run(launcher.side_session_cmd(version["hqfpga_path"],
                                                        tf.name),
                              capture_output=True, timeout=300)
    finally:
        try:
            os.unlink(tf.name)
        except OSError:
            pass
    out = (proc.stdout or b"").decode("gbk", errors="replace")
    if "UPC-EVAL-FAIL" in out or "@@UPC-EVAL-DONE@@" not in out:
        tail = "\n".join(out.splitlines()[-6:])
        print(f"Error: UPC 求值失败（TCL 语法/引用了未定义变量？）：\n{tail}")
        sys.exit(1)

    calls = []
    cur = None
    unknown_cmds = set()
    for ln in out.splitlines():
        if ln.startswith("PHYCST-CALL: "):
            cur = {"cmd": ln[len("PHYCST-CALL: "):].strip(), "args": []}
            calls.append(cur)
        elif ln.startswith("PHYCST-ARG: ") and cur is not None:
            cur["args"].append(ln[len("PHYCST-ARG: "):])
        elif ln.startswith("UNKNOWN-CALL: "):
            unknown_cmds.add(ln[len("UNKNOWN-CALL: "):].strip())
    if unknown_cmds:
        print(f"Warning: UPC 使用的非 phycst/ioh 命令被跳过（不进 CSV 往返）: "
              + ", ".join(sorted(unknown_cmds)))
    return calls


def _pin_entries(calls: list) -> list:
    """Filter recorded calls down to phycst.pin.set entries
    [{signal, ball, attrs, force, soft}]."""
    entries = []
    for c in calls:
        if c["cmd"] != _PIN_SET:
            continue
        e = {"signal": None, "ball": None, "attrs": [], "force": False,
             "soft": False}
        pending_attr = False
        for a in c["args"]:
            if pending_attr:
                e["attrs"].extend(_parse_attr_string(a))
                pending_attr = False
            elif a == "-attr":
                pending_attr = True
            elif a == "-force":
                e["force"] = True
            elif a == "-soft":
                e["soft"] = True
            elif e["signal"] is None:
                e["signal"] = a
            elif e["ball"] is None:
                e["ball"] = a
        if e["signal"] and e["ball"]:
            entries.append(e)
    return entries


def parse_upc(upc_path: str) -> tuple:
    """Evaluated pin entries + all recorded phycst/ioh calls of a .upc."""
    calls = _eval_upc(upc_path)
    return _pin_entries(calls), calls


FIXED_COLS = ("Bank", "Pin Name", "Pad Location", "Function", "Signal Name")


def _parse_attr_string(s: str) -> list:
    """'IO_TYPE=LVCMOS33 PULLMODE=NONE' -> [('IO_TYPE','LVCMOS33'), ...]."""
    out = []
    for tok in (s or "").split():
        k, _, v = tok.partition("=")
        out.append((k, v))
    return out


def _load_pkg_table(family: str, part: str) -> dict:
    """Device package-pin table via 'udev.pkg.report.

    The pkg CSV columns are IO,site,tile,bank,desc where IO is the ball
    (e.g. H4), tile the pad location (e.g. PT79A), site the pad type
    (PIO) — returns {ball: (pad_location, bank, function)}."""
    import tempfile
    from . import udev
    table = {}
    with tempfile.TemporaryDirectory(prefix="hqbuddy_pincsv_") as td:
        base = os.path.join(td, part)
        sections = udev._run_hqfpga_sections(family, part, ["pkg"], base)
        for row in udev._pkg_csv(sections["pkg"]).splitlines()[1:]:
            io, _site, tile, bank, desc = (row.split(",") + [""] * 5)[:5]
            table[io] = (tile, bank, desc)
    return table


def _resolve_out(path: str, default: str, what: str) -> str:
    out = os.path.abspath(path or default)
    if os.path.exists(out):
        print(f"Error: {what} already exists: {out}")
        print("       用 -o 显式指定输出以覆盖。")
        sys.exit(1)
    return out


def run_pin2csv(args: list) -> None:
    """Entry for 'hqbuddy -pin2csv [<.hqprj>] [-o <out.csv>]'."""
    hqprj_arg = None
    out = None
    consumed = set()
    if "-o" in args:
        i = args.index("-o")
        if i + 1 >= len(args):
            print("Error: -o requires a value")
            sys.exit(1)
        out = args[i + 1]
        consumed.update({i, i + 1})
    for i, a in enumerate(args):
        if i in consumed:
            continue
        if a.startswith("-"):
            print(f"Error: unknown -pin2csv option: {a}")
            print("Usage: hqbuddy -pin2csv [<.hqprj>] [-o <out.csv>]")
            sys.exit(1)
        if hqprj_arg is None:
            hqprj_arg = a
        else:
            print(f"Error: unexpected argument: {a}")
            sys.exit(1)

    if hqprj_arg:
        if not os.path.isfile(hqprj_arg):
            print(f"Error: file not found: {hqprj_arg}")
            sys.exit(1)
    else:
        cands = sorted(glob.glob("*.hqprj"))
        if len(cands) != 1:
            print("Error: 未指定 .hqprj 且当前目录不是唯一工程目录，请显式指定。")
            sys.exit(1)
        hqprj_arg = cands[0]
    prj = parse_hqprj(hqprj_arg)
    if not prj["pc"]:
        print("Error: 工程无 FILE_PC（物理约束）——没有可导出的管脚分配。")
        print("       先用 GUI 或 phycst.pin.set 生成 .upc 并在工程中挂载。")
        sys.exit(1)
    upc_path = prj["pc"][0]
    part = device.get_device(hqprj_arg)
    family = device.get_family_for_device(part)
    if not family:
        print(f"Error: unknown part '{part}' (not in this version's dv_list.xml).")
        sys.exit(1)

    entries, all_calls = parse_upc(upc_path)
    if not entries:
        print(f"Error: {upc_path} 求值后没有 phycst.pin.set 管脚分配。")
        sys.exit(1)
    skipped = sum(1 for c in all_calls if c["cmd"] != _PIN_SET)

    print(f"Device: {part} (family {family})")
    print(f"UPC: {upc_path}  ({len(entries)} 条 pin.set，已按 TCL 求值："
          f"条件分支取实际值)")
    if skipped:
        print(f"       另有 {skipped} 条非 pin.set 约束（vccio/ioh 等）不在 CSV 往返范围")
    print("Reading device package-pin table ('udev.pkg.report) ...")
    sys.stdout.flush()
    pkg = _load_pkg_table(family, part)

    by_ball = {}
    for e in entries:
        if e["ball"] in by_ball:
            print(f"Warning: 球 {e['ball']} 被分配多次，保留第一条: "
                  f"{by_ball[e['ball']]['signal']} (丢弃 {e['signal']})")
            continue
        by_ball[e["ball"]] = e
    attr_keys = []
    for e in by_ball.values():
        for k, _ in e["attrs"]:
            if k not in attr_keys:
                attr_keys.append(k)

    unknown = [b for b in by_ball if b not in pkg]
    if unknown:
        print(f"Warning: {len(unknown)} 个球不在器件封装表中（仍会写出，供人工核对）: "
              + " ".join(sorted(unknown)))

    out_path = _resolve_out(out, os.path.join(
        prj["work_dir"], os.path.splitext(os.path.basename(prj["path"]))[0] + "_pins.csv"),
        "CSV")
    cols = list(FIXED_COLS) + attr_keys
    n_assigned = 0
    with open(out_path, "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(cols)
        for ball in sorted(pkg):
            pad, bank, desc = pkg[ball]
            e = by_ball.get(ball)
            if e:
                n_assigned += 1
                amap = dict(e["attrs"])
                row = [bank, ball, pad, desc, e["signal"]] + [amap.get(k, "") for k in attr_keys]
            else:
                row = [bank, ball, pad, desc, ""] + [""] * len(attr_keys)
            w.writerow(row)
        # balls assigned in the UPC but missing from the package table
        for ball in sorted(unknown):
            e = by_ball[ball]
            amap = dict(e["attrs"])
            w.writerow(["", ball, "", "", e["signal"]] + [amap.get(k, "") for k in attr_keys])

    print(f"[OK] CSV written: {out_path}")
    print(f"     封装管脚 {len(pkg)}，已分配 {n_assigned}，属性列: "
          f"{', '.join(attr_keys) or '-'}")
    if unknown:
        print(f"     器件表外球 {len(unknown)} 个（行尾追加，Bank/Pad Location 为空）")


def _read_csv_rows(csv_path: str) -> tuple:
    """Read the CSV; return (headers, rows, attr_keys).  Requires the
    -pin2csv header contract (Signal Name + Pin Name columns)."""
    with open(csv_path, "r", encoding="utf-8-sig", newline="") as f:
        rows = list(csv.reader(f))
    if not rows:
        print(f"Error: empty CSV: {csv_path}")
        sys.exit(1)
    headers = [h.strip() for h in rows[0]]
    for need in ("Signal Name", "Pin Name"):
        if need not in headers:
            print(f"Error: CSV 缺少列 '{need}'（-csv2upc 消费 -pin2csv 生成的表头格式）")
            print(f"       表头: {','.join(headers)}")
            sys.exit(1)
    attr_keys = [h for h in headers if h not in FIXED_COLS]
    return headers, rows[1:], attr_keys


def _resolve_target_device(args: list, consumed: set) -> tuple:
    """Optional -device <part>|<.hqprj> for ball validation -> (part, family)."""
    part = None
    if "-device" in args:
        i = args.index("-device")
        if i + 1 >= len(args):
            print("Error: -device requires a value")
            sys.exit(1)
        part = args[i + 1]
        consumed.update({i, i + 1})
    if part is None:
        cands = sorted(glob.glob("*.hqprj"))
        if len(cands) == 1:
            part = device.get_device(cands[0])
        else:
            return None, None
    if part.lower().endswith(".hqprj"):
        if not os.path.isfile(part):
            print(f"Error: file not found: {part}")
            sys.exit(1)
        part = device.get_device(part)
    family = device.get_family_for_device(part)
    if not family:
        print(f"Error: unknown part '{part}' (not in this version's dv_list.xml).")
        sys.exit(1)
    return part, family


def _validate_balls(balls: list, family: str, part: str) -> list:
    """One design-free hqfpga session: dv.get_pin_bank per ball. Returns bad balls."""
    version = launcher.require_hqfpga_version()
    vlines = "\n".join(f"lappend balls {{{b}}}" for b in balls)
    tcl = (f"set balls {{}}\n{vlines}\n"
           f"dv.setup {family} {part}\n"
           f"foreach b $balls {{\n"
           f"  if {{[catch {{dv.get_pin_bank $b}} r]}} {{ puts \"BADBALL $b\"\n"
           f"  }} else {{ puts \"OKBALL $b $r\" }}\n"
           f"}}\n")
    import tempfile
    tf = tempfile.NamedTemporaryFile("w", suffix=".tcl", delete=False,
                                     encoding="utf-8")
    tf.write(tcl)
    tf.close()
    try:
        proc = subprocess.run(launcher.side_session_cmd(version["hqfpga_path"],
                                                        tf.name),
                              capture_output=True, timeout=300)
    finally:
        try:
            os.unlink(tf.name)
        except OSError:
            pass
    out = (proc.stdout or b"").decode("gbk", errors="replace")
    ok = {ln.split()[1] for ln in out.splitlines() if ln.startswith("OKBALL ")}
    return [b for b in balls if b not in ok]


def run_csv2upc(args: list) -> None:
    """Entry for 'hqbuddy -csv2upc <in.csv> [-o <out.upc>] [-device <part>|<.hqprj>]'."""
    csv_arg = None
    out = None
    consumed = set()
    if "-device" in args:
        i = args.index("-device")
        consumed.update({i, i + 1})
    if "-o" in args:
        i = args.index("-o")
        if i + 1 >= len(args):
            print("Error: -o requires a value")
            sys.exit(1)
        out = args[i + 1]
        consumed.update({i, i + 1})
    for i, a in enumerate(args):
        if i in consumed:
            continue
        if a.startswith("-"):
            print(f"Error: unknown -csv2upc option: {a}")
            print("Usage: hqbuddy -csv2upc <in.csv> [-o <out.upc>] [-device <part>|<.hqprj>]")
            sys.exit(1)
        if csv_arg is None:
            csv_arg = a
        else:
            print(f"Error: unexpected argument: {a}")
            sys.exit(1)
    if not csv_arg:
        print("Usage: hqbuddy -csv2upc <in.csv> [-o <out.upc>] [-device <part>|<.hqprj>]")
        sys.exit(1)
    if not os.path.isfile(csv_arg):
        print(f"Error: file not found: {csv_arg}")
        sys.exit(1)

    headers, rows, attr_keys = _read_csv_rows(csv_arg)
    i_sig = headers.index("Signal Name")
    i_ball = headers.index("Pin Name")
    i_force = headers.index("Force") if "Force" in headers else None

    entries = []
    for r in rows:
        r = (r + [""] * len(headers))[:len(headers)]
        sig = r[i_sig].strip()
        if not sig:
            continue
        ball = r[i_ball].strip()
        if not ball:
            print(f"Error: 信号 {sig} 已分配但 Pin Name 为空——请补球名。")
            sys.exit(1)
        attrs = [(k, r[headers.index(k)].strip()) for k in attr_keys
                 if r[headers.index(k)].strip()]
        entries.append({"force": bool(i_force is not None and r[i_force].strip()),
                        "signal": sig, "ball": ball, "attrs": attrs})
    if not entries:
        print("Error: CSV 中没有已分配的信号（Signal Name 列全空）。")
        sys.exit(1)

    part, family = _resolve_target_device(args, consumed)
    if part:
        print(f"Validating {len(entries)} ball(s) against {part} ...")
        bad = _validate_balls(sorted({e["ball"] for e in entries}), family, part)
        if bad:
            print(f"Error: {len(bad)} 个球名在器件 {part} 上不存在: {' '.join(bad)}")
            print("       用 hqbuddy -udev --pkg 查看合法球名。")
            sys.exit(1)
        print(f"[OK] 球名校验通过 ({len(entries)} 个)")
    else:
        print("Note: 未找到器件（无 -device / cwd .hqprj），跳过球名校验。")

    out_path = _resolve_out(out, os.path.splitext(os.path.abspath(csv_arg))[0] + ".upc",
                            "UPC")
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("# Generated by hqbuddy -csv2upc from " +
                os.path.basename(csv_arg) + "\n")
        for e in entries:
            force = "-force " if e["force"] else ""
            attr = ""
            if e["attrs"]:
                attr = ' -attr "' + " ".join(f"{k}={v}" for k, v in e["attrs"]) + '"'
            f.write(f"phycst.pin.set {force}{{{e['signal']}}} {e['ball']}{attr}\n")

    print(f"[OK] UPC written: {out_path}  ({len(entries)} 条 phycst.pin.set)")
    print("Next: hqbuddy -add <out.upc> [<.hqprj>] 挂到工程（或替换原 FILE_PC）。")
