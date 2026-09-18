# -*- coding: utf-8 -*-
"""Pin planning helper: hqbuddy -pinplan <src.hqprj> -board <name> [-o out.upc]

Elaborates the project, lists output ports via ioh.get_ports O, matches them
against the board reference tables (skills/hqfpga/references/boards/), and
emits a .upc skeleton: matched ports get phycst.pin.set lines with the board
default IO_TYPE; unmatched ports get TODO markers.  Input/clock ports are left
as TODO hints (ioh.get_ports I is not populated pre-implementation).
"""
import os
import re
import sys

from . import launcher


def _board_table(board: str) -> list:
    """Parse boards/<board>.md tables into [(net, pin)] pairs."""
    home = os.path.expanduser("~")
    candidates = [
        # source checkout
        os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(
            os.path.dirname(os.path.abspath(__file__))))),
            "skills", "hqfpga", "references"),
        # installed skill copies (install_skill.py targets)
        os.path.join(home, ".zcode", "skills", "hqfpga", "references"),
        os.path.join(home, ".claude", "skills", "hqfpga", "references"),
        os.path.join(home, ".kimi-code", "skills", "hqfpga", "references"),
    ]
    md = None
    for d in candidates:
        cand = os.path.join(d, "boards", f"{board}.md")
        if os.path.isfile(cand):
            md = cand
            break
    if md is None:
        print(f"Error: boards/{board}.md 未找到（检索了仓库与已安装 skill 目录）")
        sys.exit(1)
    if not os.path.isfile(md):
        print(f"Error: board reference not found: {md}")
        print(f"       可选: {', '.join(sorted(os.listdir(os.path.dirname(md))))}")
        sys.exit(1)
    pairs = []
    for ln in open(md, encoding="utf-8", errors="replace"):
        m = re.match(r"^\|\s*([A-Za-z0-9_\-\.]+)\s*\|\s*([A-Za-z0-9_]+)\s*(\||$)", ln)
        if m and m.group(1).upper() not in ("NET",):
            pairs.append((m.group(1), m.group(2)))
    return pairs


def _elab_ports(hqfpga_path: str, work: str, hqprj: str, top: str) -> list:
    """rtl.analyze+elaborate then ioh.get_ports O; returns port name list."""
    import tempfile
    import subprocess
    fields = {}
    for line in open(hqprj, encoding="utf-8", errors="replace"):
        if "=" in line:
            k, v = line.split("=", 1)
            fields.setdefault(k.strip(), v.strip())
    srcs = [f for f in (fields.get("FILE_SRC", "")).split()
            ] if False else []
    srcs = []
    for ln in open(hqprj, encoding="utf-8", errors="replace"):
        ln = ln.strip()
        if ln.startswith("FILE_SRC=") and ln != "FILE_SRC=NONE":
            srcs.append(ln.split("=", 1)[1].replace("$WORK_DIR$", work.replace(os.sep, "/") + "/"))
    vlines = "\n".join(f'lappend vfiles {s}' for s in srcs)
    tcl = (f'set WORK_DIR {work.replace(os.sep, "/")}\n'
           f'set vfiles {{}}\n{vlines}\n'
           f'dv.setup -synlib_only SEAL\n'
           f'rtl.analyze $vfiles\n'
           f'rtl.elaborate -top {top}\n'
           f'puts "===PORTS-O==="\n'
           f'ioh.get_ports O\n')
    tf = tempfile.NamedTemporaryFile("w", suffix=".tcl", delete=False, encoding="utf-8")
    tf.write(tcl)
    tf.close()
    proc = subprocess.run([hqfpga_path, "-cmd", tf.name], cwd=work,
                          capture_output=True, text=True,
                          errors="replace", timeout=600)
    os.unlink(tf.name)
    out = proc.stdout or ""
    if "===PORTS-O===" not in out:
        tail = "\n".join((proc.stdout or "").splitlines()[-6:])
        print(f"Error: ioh.get_ports 未产出端口列表。hqfpga 输出尾部：\n{tail}")
        sys.exit(1)
    seg = out.split("===PORTS-O===", 1)[1]
    first_line = seg.splitlines()[1] if len(seg.splitlines()) > 1 else ""
    ports = []
    for tok in first_line.split():
        name = tok.replace("\\", "")
        if name and name not in ports:
            ports.append(name)
    return ports


def run_pinplan(args: list) -> None:
    """Entry for 'hqbuddy -pinplan <src.hqprj> -board <name> [-o out.upc]'."""
    hqprj = None
    board = None
    out = None
    i = 0
    while i < len(args):
        a = args[i]
        if a == "-board" and i + 1 < len(args):
            board = args[i + 1]; i += 2
        elif a == "-o" and i + 1 < len(args):
            out = args[i + 1]; i += 2
        elif hqprj is None:
            hqprj = a; i += 1
        else:
            print(f"Error: unexpected argument: {a}")
            sys.exit(1)
    if not hqprj or not board:
        print("Usage: hqbuddy -pinplan <src.hqprj> -board <板卡名，如 SA5Z-50> [-o out.upc]")
        sys.exit(1)
    hqprj = os.path.abspath(hqprj)
    if not os.path.isfile(hqprj):
        print(f"Error: file not found: {hqprj}")
        sys.exit(1)
    work = os.path.dirname(hqprj)
    top = None
    for ln in open(hqprj, encoding="utf-8", errors="replace"):
        if ln.startswith("TOP_MODULE="):
            top = ln.split("=", 1)[1].strip()
    if not top:
        print("Error: TOP_MODULE 为空——先 hqbuddy -set_top")
        sys.exit(1)

    version = launcher.require_hqfpga_version()
    ports = _elab_ports(version["hqfpga_path"], work, hqprj, top)
    print(f"输出端口 ({len(ports)}): {', '.join(ports)}")

    pairs = _board_table(board)
    lines = [f"# {board} pin plan (hqbuddy -pinplan); 未匹配端口需人工核对 boards/{board}.md"]
    matched, unmatched = [], []
    used_nets: set = set()
    for port in ports:
        base = re.sub(r"\[.*\]", "", port).lower()
        # extract alpha tokens (led -> LED nets; clk -> CLK nets; ...)
        toks = re.findall(r"[a-z]+", base)
        hit = None
        for net, pin in pairs:
            if net in used_nets:
                continue
            nu = net.lower()
            if toks and all(t in nu for t in toks):
                hit = (net, pin)
                used_nets.add(net)
                break
        if hit:
            matched.append((port, hit))
            lines.append(f"phycst.pin.set {port} {hit[1]} -attr {{IO_TYPE=LVCMOS33}}  # {hit[0]}")
        else:
            unmatched.append(port)
            lines.append(f"# TODO {port}: boards/{board}.md 中未找到匹配 net，人工分配")
    for net, pin in pairs:
        if net.upper().startswith(("REF_", "GPHY", "PCLK")) and "CLK" in net.upper():
            lines.append(f"# 时钟候选: {net} = {pin}")
            break
    out_path = out or os.path.join(work, "pinplan.upc")
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"[OK] 引脚规划骨架: {out_path}（匹配 {len(matched)}/{len(ports)}，"
          f"未匹配 {len(unmatched)}）")
    if unmatched:
        print(f"     未匹配: {', '.join(unmatched)}")


def _board_table_unused():
    pass


from . import launcher  # noqa: E402
