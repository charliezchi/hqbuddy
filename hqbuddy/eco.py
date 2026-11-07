# -*- coding: utf-8 -*-
"""Batch ECO on a routed XPN: hqbuddy -eco <routed.xpn> --script <eco.tcl> [-o <out.xpn>]

Runs the vendor eco.* command family (the backend of build/eco_editor) in a
plain batch session — no eval server, no GUI:

    xpn.read <routed.xpn> -> eco.init -> <script body> -> xpn.write <out> -> eco.end

The script body contains ONLY the ECO modifications (eco.set_route_points /
eco.forbid_route_node / program-attribute edits / eco.route ...); read, init,
write and end are handled here.  Verified on FT110126 (probe: routed XPN ->
eco.route -> rewritten XPN).  NOTE the two-tier recipe (see skill
references/install_tree.md): program-field edits (LUT equations, IO attrs,
FFMUX picks) do NOT need eco.route at all — text-edit the XPN and run
hqbuddy -xpn2bin directly (bitgen consumes the XPN config); eco.route is
only for structural edits (nets/sites/cells).
"""
import os
import subprocess
import sys
import tempfile

from . import launcher


def _usage() -> None:
    print("Usage: hqbuddy -eco <routed.xpn> --script <eco.tcl> [-o <out.xpn>]")
    print("       在批处理会话内对布线后 XPN 执行 ECO（厂商 eco.* 命令族）：")
    print("       xpn.read → eco.init → <你的 eco.tcl（只写 ECO 修改）> → xpn.write → eco.end")
    print("  -o <out.xpn>   输出 XPN（缺省 <原名>_eco.xpn；已存在则报错，-o 显式覆盖）")
    print("便捷子命令（文本级 program 修改，免重布，改后用 -xpn2bin 出 bin）：")
    print("  hqbuddy -eco --query <routed.xpn> [comp关键字]")
    print("                 列出 comp（PIO/SLICEL/IOLOGIC 分组+site）与指定 comp 的完整 program")
    print("  hqbuddy -eco --force-signal <xpn> <comp> <实例名> <0|1>")
    print("                 把某 SLICE FF 钉死为常值（AFFMUX+A*LUT 两处协同修改，实板配方）")
    print("  hqbuddy -eco --set-lut <xpn> <comp> <方程>")
    print("                 改写该 comp 的宽 LUT（A6LUT）方程，如 (A1@(A2*A4))")
    sys.exit(1)


def _run_query(args: list) -> None:
    """-eco --query <xpn> [comp关键字]: comp_index + program_detail dump.

    Two sessions: (1) comp_index JSON → python filters names by keyword;
    (2) program_detail per matched comp (the vendor query wants exact names)."""
    import json as _json
    if not args:
        print("Usage: hqbuddy -eco --query <routed.xpn> [comp关键字]")
        sys.exit(1)
    xpn = args[0]
    keyword = args[1] if len(args) > 1 else ""
    if not os.path.isfile(xpn):
        print(f"Error: file not found: {xpn}")
        sys.exit(1)
    version = launcher.require_hqfpga_version()
    xpn_tcl = os.path.abspath(xpn).replace("\\", "/")
    work = os.path.dirname(os.path.abspath(xpn))

    def _session(body: str) -> str:
        tf = tempfile.NamedTemporaryFile("w", suffix=".tcl", delete=False,
                                         encoding="utf-8")
        tf.write(body)
        tf.close()
        try:
            proc = subprocess.run([version["hqfpga_path"], "-outdir",
                                   launcher.side_log_dir(), "-log", "hqfpga.log",
                                   "-cmd", tf.name],
                                  cwd=work, capture_output=True, timeout=900)
        except subprocess.TimeoutExpired:
            print("Error: eco.query 超时（900s）。")
            sys.exit(1)
        finally:
            try:
                os.unlink(tf.name)
            except OSError:
                pass
        out = (proc.stdout or b"").decode("gbk", errors="replace")
        if "@@ECO-DONE@@" not in out:
            print("Error: eco.query 会话失败。尾部：\n" +
                  "\n".join(out.splitlines()[-6:]))
            sys.exit(1)
        return out

    out1 = _session(f"xpn.read {{{xpn_tcl}}}\n"
                    f"eco.init\n"
                    f'puts "@@CI@@"\n'
                    f'if {{[catch {{puts [eco.query.comp_index]}} e]}} '
                    f'{{ puts "CI-ERR: $e" }}\n'
                    f"eco.end\n"
                    f'puts "@@ECO-DONE@@"\n')
    ci = out1.split("@@CI@@", 1)[1].split("@@ECO-DONE@@", 1)[0].strip()
    print("== comp_index ==")
    print(ci or "(empty)")
    if not keyword or ci.startswith("CI-ERR") or not ci.startswith("{"):
        return
    try:
        data = _json.loads(ci)
    except _json.JSONDecodeError:
        print("Warning: comp_index 非 JSON，跳过明细查询。")
        return
    names = [c["name"] for g in data.get("groups", [])
             for c in g.get("comps", [])]
    low = keyword.lower()
    matches = [n for n in names if low in n.lower()][:3]
    if not matches:
        print(f"== program_detail ==（无 comp 匹配 '{keyword}'；"
              f"共 {len(names)} 个 comp）")
        return
    pd_lines = []
    for n in matches:
        out2 = _session(f"xpn.read {{{xpn_tcl}}}\n"
                        f"eco.init\n"
                        f'if {{[catch {{puts [eco.query.program_detail {{{n}}}]}} e]}} '
                        f'{{ puts "PD-ERR: $e" }}\n'
                        f"eco.end\n"
                        f'puts "@@ECO-DONE@@"\n')
        pd = out2.split("@@ECO-DONE@@", 1)[0]
        pd = pd.split("eco.init", 1)[-1].strip() if "PD-ERR" in pd else \
            "\n".join(l for l in out2.splitlines()
                      if l.strip() and not l.startswith(("Info:", "=", "#", "<", "-"))
                      and "@@" not in l and "Launching" not in l
                      and "Program terminating" not in l
                      and "Peak memory" not in l and "Total runtime" not in l
                      and "HqFpga is ready" not in l and "Loading" not in l
                      and "Device data loaded" not in l)
        pd_lines.append(f"--- {n} ---\n{pd}")
    print(f"== program_detail（匹配 '{keyword}' ×{len(matches)}）==")
    print("\n".join(pd_lines))


def _run_text_edit(args: list, mode: str) -> None:
    """-eco --force-signal <xpn> <comp> <instance> <0|1> / --set-lut <xpn> <comp> <eq>."""
    from . import ecoedit
    if mode == "force":
        if len(args) != 4:
            print("Usage: hqbuddy -eco --force-signal <xpn> <comp> <实例名> <0|1>")
            print("       实例名=SLICE FF 例化名（如 bus_b_raw_reg[0]）；可用 --query 先查。")
            sys.exit(1)
        xpn, comp, instance, val = args
        if val not in ("0", "1"):
            print(f"Error: 常值只能是 0|1，得到: {val}")
            sys.exit(1)
        old = ecoedit.load_xpn_text(xpn)
        new = ecoedit.edit_force_ff(old, comp, instance, int(val))
    else:  # set-lut
        if len(args) != 3:
            print("Usage: hqbuddy -eco --set-lut <xpn> <comp> <方程>")
            print("       例: hqbuddy -eco --set-lut d.xpn bus_b_raw[2] '(A1@(A2*A4))'")
            sys.exit(1)
        xpn, comp, equation = args
        old = ecoedit.load_xpn_text(xpn)
        new = ecoedit.edit_set_lut(old, comp, equation)
    out = os.path.splitext(os.path.abspath(xpn))[0] + "_eco.xpn"
    if os.path.exists(out):
        print(f"Error: output already exists: {out}")
        print("       删除/改名后重试，或直接对副本操作。")
        sys.exit(1)
    with open(out, "w", encoding="utf-8", newline="") as f:
        f.write(new)
    print(f"[OK] ECO XPN written: {out}")
    print("Next: hqbuddy -xpn2bin <out> 出 bin（方程/属性类修改无需重布）。")


def run_eco(args: list) -> None:
    """Entry for 'hqbuddy -eco ...'."""
    if args and args[0] == "--query":
        _run_query(args[1:])
        return
    if args and args[0] == "--force-signal":
        _run_text_edit(args[1:], "force")
        return
    if args and args[0] == "--set-lut":
        _run_text_edit(args[1:], "set-lut")
        return
    xpn = None
    script = None
    out = None
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--script":
            if i + 1 >= len(args):
                print("Error: --script requires a value")
                sys.exit(1)
            script = args[i + 1]
            i += 2
        elif a == "-o":
            if i + 1 >= len(args):
                print("Error: -o requires a value")
                sys.exit(1)
            out = args[i + 1]
            i += 2
        elif a.startswith("-"):
            print(f"Error: unknown -eco option: {a}")
            _usage()
        elif xpn is None:
            xpn = a
            i += 1
        else:
            print(f"Error: unexpected argument: {a}")
            _usage()
    if not xpn or not script:
        _usage()
    if not os.path.isfile(xpn):
        print(f"Error: file not found: {xpn}")
        sys.exit(1)
    if not os.path.isfile(script):
        print(f"Error: file not found: {script}")
        sys.exit(1)
    if not out:
        out = os.path.splitext(xpn)[0] + "_eco.xpn"
    out_abs = os.path.abspath(out)
    if os.path.exists(out_abs):
        print(f"Error: output already exists: {out_abs}")
        print("       用 -o 显式指定输出以覆盖。")
        sys.exit(1)

    body = open(script, encoding="utf-8", errors="replace").read()
    version = launcher.require_hqfpga_version()
    xpn_tcl = os.path.abspath(xpn).replace("\\", "/")
    out_tcl = out_abs.replace("\\", "/")
    tcl = (f"xpn.read {{{xpn_tcl}}}\n"
           f'if {{[catch {{eco.init}} e]}} {{ puts "ECO-FAIL: eco.init: $e"; exit 1 }}\n'
           f"# ---- user ECO body ----\n"
           f"{body}\n"
           f"# ----------------------\n"
           f'if {{[catch {{xpn.write {{{out_tcl}}}}} e]}} {{ puts "ECO-FAIL: xpn.write: $e"; exit 1 }}\n'
           f'if {{[catch {{eco.end}} e]}} {{ puts "ECO-WARN: eco.end: $e" }}\n'
           f'puts "@@ECO-DONE@@"\n')

    import tempfile
    tf = tempfile.NamedTemporaryFile("w", suffix=".tcl", delete=False,
                                     encoding="utf-8")
    tf.write(tcl)
    tf.close()
    work = os.path.dirname(os.path.abspath(xpn))
    print(f"ECO: {os.path.abspath(xpn)}")
    print(f"  script: {os.path.abspath(script)}")
    print(f"  output: {out_abs}")
    try:
        proc = subprocess.run([version["hqfpga_path"], "-outdir",
                               launcher.side_log_dir(), "-log", "hqfpga.log",
                               "-cmd", tf.name],
                              cwd=work, capture_output=True, timeout=3600)
    except subprocess.TimeoutExpired:
        print("Error: hqfpga ECO 超时（3600s）。")
        sys.exit(1)
    finally:
        try:
            os.unlink(tf.name)
        except OSError:
            pass
    out_txt = (proc.stdout or b"").decode("gbk", errors="replace")
    tail = "\n".join(out_txt.splitlines()[-8:])
    if proc.returncode != 0 or "@@ECO-DONE@@" not in out_txt \
            or "ECO-FAIL" in out_txt:
        print(f"Error: ECO 会话失败（exit {proc.returncode}）。输出尾部：\n{tail}")
        sys.exit(1)
    if not os.path.isfile(out_abs):
        print(f"Error: ECO 会话正常结束但未产出 XPN：{out_abs}")
        sys.exit(1)
    print(f"[OK] ECO XPN written: {out_abs}  "
          f"({os.path.getsize(out_abs):,} bytes)")
    print("Next: hqbuddy -xpn2bin <out.xpn> 出 bin，或继续 -eco 迭代。")
