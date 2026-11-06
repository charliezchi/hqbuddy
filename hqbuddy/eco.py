# -*- coding: utf-8 -*-
"""Batch ECO on a routed XPN: hqbuddy -eco <routed.xpn> --script <eco.tcl> [-o <out.xpn>]

Runs the vendor eco.* command family (the backend of build/eco_editor) in a
plain batch session — no eval server, no GUI:

    xpn.read <routed.xpn> -> eco.init -> <script body> -> xpn.write <out> -> eco.end

The script body contains ONLY the ECO modifications (eco.set_route_points /
eco.forbid_route_node / program-attribute edits / eco.route ...); read, init,
write and end are handled here.  Verified on FT110126 (probe: routed XPN ->
eco.route -> rewritten XPN; CmdCcdRegFix-style crashes belong to
lo.cdc_sync_reg.insert, a different family).
"""
import os
import subprocess
import sys

from . import launcher


def _usage() -> None:
    print("Usage: hqbuddy -eco <routed.xpn> --script <eco.tcl> [-o <out.xpn>]")
    print("       在批处理会话内对布线后 XPN 执行 ECO（厂商 eco.* 命令族）：")
    print("       xpn.read → eco.init → <你的 eco.tcl（只写 ECO 修改）> → xpn.write → eco.end")
    print("  -o <out.xpn>   输出 XPN（缺省 <原名>_eco.xpn；已存在则报错，-o 显式覆盖）")
    sys.exit(1)


def run_eco(args: list) -> None:
    """Entry for 'hqbuddy -eco <routed.xpn> --script <eco.tcl> [-o <out.xpn>]'."""
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
