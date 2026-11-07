# -*- coding: utf-8 -*-
"""Auto-generate clock constraints for projects without an SDC:
hqbuddy -autosdc <src.hqprj> [-period <ns>] [-o out.sdc]

Elaborates the design, runs tc.autogen -print to capture the auto clock
constraint TCL lines, and writes them to a .sdc file ready for -flow/-build.
"""
import os
import re
import subprocess
import sys
import tempfile

from . import launcher


def run_autosdc(args: list) -> None:
    """Entry for 'hqbuddy -autosdc <src.hqprj> [--detect] [-period ns] [-o out.sdc]'."""
    detect = "--detect" in args
    args = [a for a in args if a != "--detect"]
    hqprj = None
    period = None
    out = None
    i = 0
    while i < len(args):
        a = args[i]
        if a == "-period" and i + 1 < len(args):
            period = args[i + 1]; i += 2
        elif a == "-o" and i + 1 < len(args):
            out = args[i + 1]; i += 2
        elif hqprj is None:
            hqprj = a; i += 1
        else:
            print(f"Error: unexpected argument: {a}")
            sys.exit(1)
    if not hqprj:
        print("Usage: hqbuddy -autosdc <src.hqprj> [--detect] [-period ns] [-o out.sdc]")
        print("       --detect: 时钟骨架模式（nl.clock.detect → create_clock 骨架；")
        print("       FT110126 上 tc.autogen 不可用时的替代；骨架周期需人工复核）")
        sys.exit(1)
    hqprj = os.path.abspath(hqprj)
    if not os.path.isfile(hqprj):
        print(f"Error: file not found: {hqprj}")
        sys.exit(1)
    work = os.path.dirname(hqprj)

    top = None
    family = None
    srcs = []
    for ln in open(hqprj, encoding="utf-8", errors="replace"):
        ln = ln.strip()
        if ln.startswith("TOP_MODULE="):
            top = ln.split("=", 1)[1]
        elif ln.startswith("FAMILY="):
            family = ln.split("=", 1)[1]
        elif ln.startswith("FILE_SRC=") and ln != "FILE_SRC=NONE":
            srcs.append(ln.split("=", 1)[1].replace("$WORK_DIR$", work.replace(os.sep, "/") + "/"))
    if not top or top == "NONE":
        print("Error: .hqprj 未设置 TOP_MODULE，无法 elaborate。")
        sys.exit(1)
    if period is not None:
        try:
            float(period)
        except ValueError:
            print(f"Error: -period 需为数值（ns），得到: {period}")
            sys.exit(1)

    version = launcher.require_hqfpga_version()
    hqfpga_path = version["hqfpga_path"]

    vlines = "\n".join(f"lappend vfiles {{{s}}}" for s in srcs)

    if detect:
        # Clock-skeleton mode: nl.clock.detect (FT110126-verified) instead of
        # the broken tc.autogen.  Port-like names become create_clock
        # candidates; hierarchical names are listed for manual review.
        tcl = (f"set vfiles {{}}\n{vlines}\n"
               f"dv.setup -synlib_only {family or 'SEAL'}\n"
               f"design.analyze $vfiles\n"
               f"design.rtlsyn -top {top}\n"
               f'puts "===CK-DETECT==="\n'
               f'if {{[catch {{puts [nl.clock.detect]}} e]}} {{ puts "CK-ERR: $e" }}\n'
               f'puts "===CK-END==="\n')
        tf = tempfile.NamedTemporaryFile("w", suffix=".tcl", delete=False,
                                         encoding="utf-8")
        tf.write(tcl)
        tf.close()
        try:
            proc = subprocess.run(launcher.side_session_cmd(hqfpga_path, tf.name),
                                  cwd=work, capture_output=True, text=True,
                                  errors="replace", timeout=600)
        except subprocess.TimeoutExpired:
            print("Error: hqfpga elaborate 超时（600s）。")
            sys.exit(1)
        finally:
            try:
                os.unlink(tf.name)
            except OSError:
                pass
        out_txt = proc.stdout or ""
        if "===CK-DETECT===" not in out_txt or "===CK-END===" not in out_txt:
            print("Error: nl.clock.detect 无输出。尾部：\n" +
                  "\n".join(out_txt.splitlines()[-6:]))
            sys.exit(1)
        seg = out_txt.split("===CK-DETECT===", 1)[1].split("===CK-END===", 1)[0]
        names = [n for n in seg.replace("\r", "").split("\n")
                 for n in ([n] if n.strip() else [])
                 for n in n.split()]
        if "CK-ERR" in seg or not names:
            print("Error: nl.clock.detect 未检测到时钟（或执行失败）。")
            sys.exit(1)
        per = period or "10.0"
        out_path = out or os.path.join(work, "clock_skeleton.sdc")
        port_like, internal = [], []
        for n in names:
            (internal if re.search(r"[./]", n) else port_like).append(n)
        with open(out_path, "w", encoding="utf-8", newline="\n") as f:
            f.write("# Clock skeleton by hqbuddy -autosdc --detect "
                    f"(nl.clock.detect)\n")
            f.write(f"# top={top}  clocks={len(names)}  "
                    f"period={per}ns (REVIEW BEFORE USE)\n")
            f.write("# 骨架周期为占位值——按实际时钟规格修改后再用！\n\n")
            for n in port_like:
                f.write(f"create_clock -name {n} -period {per} "
                        f"[get_ports {{{n}}}]\n")
            if internal:
                f.write("\n# 内部/衍生时钟候选（层次名，需人工确认源与时钟定义方式）:\n")
                for n in internal:
                    f.write(f"# create_clock -name {n} -period {per} "
                            f"[get_nets {{{n}}}]\n")
        print(f"[OK] clock skeleton written: {out_path}")
        print(f"     端口时钟 {len(port_like)} 个 → create_clock 骨架；"
              f"内部/衍生 {len(internal)} 个 → 注释待人工确认")
        print("Next: 复核周期后 hqbuddy -add <sdc> 挂工程。")
        return

    auto_line = f"tc.autogen -period {period}" if period else "tc.autogen -print"
    tcl = (f"set WORK_DIR {{{work.replace(os.sep, '/')}}}\n"
           f"set vfiles {{}}\n{vlines}\n"
           f"dv.setup -synlib_only {family or 'SEAL'}\n"
           f"rtl.analyze $vfiles\n"
           f"rtl.elaborate -top {top}\n"
           f'puts "===SDC-BEgin==="\n'
           f"{auto_line}\n"
           f'puts "===SDC-End==="\n')

    tf = tempfile.NamedTemporaryFile("w", suffix=".tcl", delete=False, encoding="utf-8")
    tf.write(tcl)
    tf.close()
    try:
        proc = subprocess.run(launcher.side_session_cmd(hqfpga_path, tf.name),
                              cwd=work,
                              capture_output=True, text=True,
                              errors="replace", timeout=600)
    except subprocess.TimeoutExpired:
        print("Error: hqfpga elaborate 超时（600s）——设计可能过大或工具挂起。")
        sys.exit(1)
    finally:
        try:
            os.unlink(tf.name)
        except OSError:
            pass
    out_txt = proc.stdout or ""

    if "===SDC-BEgin===" not in out_txt or "===SDC-End===" not in out_txt:
        tail = "\n".join(out_txt.splitlines()[-8:])
        print(f"Error: tc.autogen 未产出约束行。hqfpga 输出尾部：\n{tail}")
        sys.exit(1)

    seg = out_txt.split("===SDC-BEgin===", 1)[1].split("===SDC-End===", 1)[0]
    sdc_lines = [l for l in seg.splitlines()
                 if l.strip() and not l.strip().startswith("===")]
    if not sdc_lines:
        print("Error: tc.autogen 未产出任何约束行。")
        print("       FT110126 实测：tc.* 命令族在批处理会话（-cmd 脚本）中对本版本静默")
        print("       无输出（与早期版本/手册行为不符，疑厂商变更）。替代路径：")
        print("       hqbuddy -analyze <工程> 查看时钟清单后手写 SDC，或向智多晶反馈。")
        sys.exit(1)

    out_path = out or os.path.join(work, "auto_generated.sdc")
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("# Auto-generated by hqbuddy -autosdc (tc.autogen)\n")
        f.write(f"# top={top}  period={period or 'auto'}\n")
        f.write("\n".join(sdc_lines) + "\n")
    print(f"[OK] SDC written: {out_path} ({len(sdc_lines)} lines)")
    print("Next: hqbuddy -add <sdc> 或加入 FILE_TC 后 -build。")
