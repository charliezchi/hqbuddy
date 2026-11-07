# -*- coding: utf-8 -*-
"""Gate-level timing simulation: hqbuddy -gatesim <routed.xpn> --tb <tb.v>

One command from a routed XPN to an SDF-annotated ModelSim run:
  xpn.read -> nl.write <netlist>.v -loc -sdf   (FT110126-verified)
  -> vlog netlist + U_PRIM + TB -> vsim -t 1ps -L XiST -sdf<mode> -voptargs=+acc
  -> parse SDF annotation stats into gatesim.rpt

The TB must instantiate the DUT plus xsGSR/xsPWR (see skill
references/modelsim.md); SystemVerilog TBs need a .sv suffix.
"""
import glob
import os
import re
import shutil
import subprocess
import sys

from . import launcher
from .simlib import _check_vsim


def _usage() -> None:
    print("Usage: hqbuddy -gatesim <routed.xpn> --tb <tb.v|tb.sv> [options]")
    print("  --top <name>          DUT 模块名（缺省从 XPN/SDF 的 DESIGN 字段取）")
    print("  --sdf-instance <path> SDF 注解实例路径（如 /tb/dut；缺省注解顶层）")
    print("  --sdfmax|--sdfmin|--sdftyp  SDF 延迟档位（缺省 sdfmax）")
    print("  --time <dur>          run 时长（缺省 25us）")
    print("  --work <dir>          工作目录（缺省 <xpn 目录>/gatesim/，重跑清空重建）")
    print("  --no_run              只导出网表+SDF 并生成 do 文件，不启动 vsim")
    sys.exit(1)


def _export_netlist_sdf(xpn: str, work: str) -> tuple:
    version = launcher.require_hqfpga_version()
    xpn_tcl = os.path.abspath(xpn).replace("\\", "/")
    v_tcl = os.path.join(work, "gs_net.v").replace("\\", "/")
    tcl = (f"xpn.read {{{xpn_tcl}}}\n"
           f"nl.write {{{v_tcl}}} -loc -sdf\n"
           f'puts "@@GS-DONE@@"\n')
    import tempfile
    tf = tempfile.NamedTemporaryFile("w", suffix=".tcl", delete=False,
                                     encoding="gbk")
    tf.write(tcl)
    tf.close()
    try:
        proc = subprocess.run(
            [version["hqfpga_path"], "-outdir", launcher.side_log_dir(),
             "-log", "hqfpga.log", "-cmd", tf.name],
            cwd=work, capture_output=True, timeout=900)
    except subprocess.TimeoutExpired:
        print("Error: 网表/SDF 导出超时（900s）。")
        sys.exit(1)
    finally:
        try:
            os.unlink(tf.name)
        except OSError:
            pass
    out = (proc.stdout or b"").decode("gbk", errors="replace")
    v = os.path.join(work, "gs_net.v")
    sdf = os.path.join(work, "gs_net.sdf")
    if "@@GS-DONE@@" not in out or not os.path.isfile(v) or not os.path.isfile(sdf):
        print(f"Error: 网表/SDF 导出失败（exit {proc.returncode}）。尾部：\n" +
              "\n".join(out.splitlines()[-6:]))
        sys.exit(1)
    return v, sdf


def _sdf_design_name(sdf: str) -> str:
    for ln in open(sdf, encoding="utf-8", errors="replace"):
        m = re.search(r'\(DESIGN\s+"([^"]+)"\)', ln)
        if m:
            return m.group(1)
    return ""


def _tb_dut_instance(tb_path: str, top: str) -> str | None:
    """Find the DUT instance name in the TB (the ` <top> <inst> (` line)."""
    for ln in open(tb_path, encoding="utf-8", errors="replace"):
        m = re.search(r"\b" + re.escape(top) + r"\s+(\w+)\s*\(", ln)
        if m and m.group(1) != top:
            return m.group(1)
    return None


def run_gatesim(args: list) -> None:
    """Entry for 'hqbuddy -gatesim <routed.xpn> --tb <tb.v> [options]'."""
    xpn = None
    tb = None
    top = None
    sdf_instance = None
    sdf_mode = "sdfmax"
    run_time = "25us"
    work = None
    no_run = False
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--tb":
            tb = args[i + 1] if i + 1 < len(args) else None
            if not tb:
                print("Error: --tb requires a value")
                sys.exit(1)
            i += 2
        elif a == "--top":
            top = args[i + 1] if i + 1 < len(args) else None
            i += 2
        elif a == "--sdf-instance":
            sdf_instance = args[i + 1] if i + 1 < len(args) else None
            i += 2
        elif a in ("--sdfmax", "--sdfmin", "--sdftyp"):
            sdf_mode = a[2:]
            i += 1
        elif a == "--time":
            run_time = args[i + 1] if i + 1 < len(args) else "25us"
            i += 2
        elif a == "--work":
            work = args[i + 1] if i + 1 < len(args) else None
            i += 2
        elif a == "--no_run":
            no_run = True
            i += 1
        elif a.startswith("-"):
            print(f"Error: unknown -gatesim option: {a}")
            _usage()
        elif xpn is None:
            xpn = a
            i += 1
        else:
            print(f"Error: unexpected argument: {a}")
            _usage()
    if not xpn or not tb:
        _usage()
    if not os.path.isfile(xpn):
        print(f"Error: file not found: {xpn}")
        sys.exit(1)
    if not os.path.isfile(tb):
        print(f"Error: file not found: {tb}")
        sys.exit(1)
    if sdf_mode not in ("sdfmax", "sdfmin", "sdftyp"):
        print(f"Error: bad SDF mode: {sdf_mode}")
        sys.exit(1)

    vsim_path = _check_vsim()
    if not vsim_path and not no_run:
        print("Error: vsim not found in PATH（先装 ModelSim/QuestaSim 并加 PATH，")
        print("      或先跑 hqbuddy -simlib 编译原语库）。")
        sys.exit(1)

    if not work:
        work = os.path.join(os.path.dirname(os.path.abspath(xpn)), "gatesim")
    work = os.path.abspath(work)
    if os.path.isdir(work):
        shutil.rmtree(work)
    os.makedirs(work, exist_ok=True)

    print(f"Gatesim work dir: {work}")
    v, sdf = _export_netlist_sdf(xpn, work)
    print(f"[OK] gate netlist: {v} ({os.path.getsize(v):,} B)")
    print(f"[OK] SDF:          {sdf} ({os.path.getsize(sdf):,} B)")

    design = top or _sdf_design_name(sdf) or "dut"
    tb_abs = os.path.abspath(tb)
    if not sdf_instance:
        inst = _tb_dut_instance(tb_abs, design)
        if inst:
            sdf_instance = f"/{inst}"
            print(f"[i] SDF instance auto-detected: {sdf_instance} "
                  f"(override with --sdf-instance)")
    sdf_spec = (f"{sdf_instance}={sdf}" if sdf_instance else sdf)
    if not sdf_instance:
        print("Warning: 未提供 --sdf-instance 且 TB 中未找到 DUT 实例——"
              "SDF 将注解到顶层，多半失败。")

    do_lines = [
        "onerror {quit -f}",
        "vlib work",
        f"vlog +define+SIM -work work {{{v.replace(os.sep, '/')}}}",
        f"vlog -work work {{{tb_abs.replace(os.sep, '/')}}}",
        (f"vsim -t 1ps -L XiST -{sdf_mode} {{{sdf_spec}}} "
         f"-voptargs=+acc work.tb"),
        f"run {run_time}",
        "quit",
    ]
    do_path = os.path.join(work, "run_gatesim.do")
    with open(do_path, "w", encoding="gbk", newline="\n") as f:
        f.write("\n".join(do_lines) + "\n")
    print(f"[OK] do file: {do_path}")
    if no_run:
        print("Next: vsim -c -do run_gatesim.do（--work 目录下）")
        return

    print("")
    print(f"Running: vsim -c -do run_gatesim.do")
    log_path = os.path.join(work, "gatesim.log")
    try:
        proc = subprocess.Popen([vsim_path, "-c", "-do", do_path], cwd=work,
                                stdout=open(log_path, "w", encoding="utf-8",
                                            errors="replace"),
                                stderr=subprocess.STDOUT)
        proc.wait(timeout=3600)
    except subprocess.TimeoutExpired:
        proc.kill()
        print("Error: vsim 仿真超时（3600s）——已终止。")
        sys.exit(1)
    finally:
        try:
            f = open(log_path, "r", encoding="utf-8", errors="replace")
        except OSError:
            f = None
        if f:
            f.close()

    log = open(log_path, encoding="utf-8", errors="replace").read()
    sdf_errs = re.findall(r"(\d+)\s+SDF error", log, re.I)
    annot = re.findall(r" SDF annotated (\d+) instance", log, re.I) or \
        re.findall(r"annotated (\d+)", log, re.I)
    hard = [l for l in log.splitlines()
            if ("Error:" in l or "Error-" in l or "Error loading design" in l)][:5]
    displays = re.findall(r"GATESIM-\S+", log)
    rpt = os.path.join(work, "gatesim.rpt")
    with open(rpt, "w", encoding="utf-8") as f:
        f.write(f"design : {design}\n")
        f.write(f"mode   : {sdf_mode}\n")
        f.write(f"sdf    : {sdf}\n")
        f.write(f"netlist: {v}\n")
        f.write(f"tb     : {tb_abs}\n")
        f.write(f"sdf errors lines: {sdf_errs or '-'}\n")
        f.write(f"annotated: {annot or '-'}\n")
        for l in hard:
            f.write(l + "\n")
    print(f"[i] SDF error counts: {sdf_errs or '(vsim 输出无 SDF error 统计行，人工看 log)'}")
    if annot:
        print(f"[i] SDF annotated: {annot[0]} instances")
    if displays:
        print(f"[i] TB displays: {' '.join(displays)}")
    if hard:
        print("Error: vsim 输出含 Error 行：")
        for l in hard:
            print(f"  {l}")
        print(f"Log: {log_path}\nRpt: {rpt}")
        sys.exit(1)
    print(f"[OK] gatesim done — log: {log_path}\n     rpt: {rpt}")
