"""XPN generation: generate temp TCL and launch hqfpga -cmd."""

import glob
import os
import re
import subprocess
import sys
import webbrowser

from . import launcher


def _hqprj_source_files(hqprj_path: str) -> list:
    """FILE_SRC/FILE_TC/FILE_PC entries resolved to existing absolute paths."""
    files = []
    work = os.path.dirname(os.path.abspath(hqprj_path)) + os.sep
    for line in open(hqprj_path, encoding="utf-8", errors="replace"):
        line = line.strip()
        if line.startswith(("FILE_SRC=", "FILE_TC=", "FILE_PC=")):
            val = line.split("=", 1)[1]
            if not val or val == "NONE":
                continue
            p = val.replace("$WORK_DIR$", work).replace("/", os.sep)
            if os.path.isfile(p):
                files.append(p)
    return files


def _stale_sources(hqprj_path: str, work_dir: str, dump_abs: str) -> list:
    """Source/constraint files newer than the route dump (relative paths)."""
    dump_mt = os.path.getmtime(dump_abs)
    newer = []
    for p in _hqprj_source_files(hqprj_path):
        try:
            if os.path.getmtime(p) > dump_mt:
                newer.append(os.path.relpath(p, work_dir))
        except OSError:
            pass
    return sorted(newer)


def _generate_xpn_tcl(work_dir: str, dump_path: str, output_xpn: str) -> str:
    """
    Generate a temporary TCL script for xpn.write in the work directory.

    Args:
        work_dir: The project working directory.
        dump_path: Relative path to the route dump file.
        output_xpn: Output XPN file name.

    Returns:
        Path to the generated temporary TCL file.
    """
    temp_tcl = os.path.join(work_dir, "_hqbuddy_genxpn.tcl")

    tcl_content = f"""design.load {dump_path}
xpn.write {output_xpn}
"""

    with open(temp_tcl, "w", encoding="utf-8") as f:
        f.write(tcl_content)

    return temp_tcl


def run_xpn(hqprj_path: str, output_name: str | None = None, hqinsight: bool = False,
            open_file: bool = True, from_src: bool = False) -> None:
    """
    Run the xpn generation command.

    Args:
        hqprj_path: Path to the .hqprj file.
        output_name: Optional custom output XPN file name.
        hqinsight: If True, use hqinsight mode path; otherwise normal mode.
        open_file: Auto-open the generated XPN after generation (default True;
            pass False for agent/silent workflows via -xpn -no_open).
        from_src: With -ins, auto-run the insight implementation flow when the
            route dump is missing (source-to-XPN in one command).  The HqInsight
            project must already exist (-insight -init + -add).
    """
    if not os.path.isfile(hqprj_path):
        print(f"Error: file not found: {hqprj_path}")
        sys.exit(1)

    work_dir = os.path.dirname(os.path.abspath(hqprj_path))

    # Determine dump path based on mode
    if hqinsight:
        dump_path = "./hqins_run/hq_import/hqins_impl/hq_temp/_step_run_route.dump"
        default_name = "hq_ins"
    else:
        dump_path = "./hq_run/hq_temp/_step_run_route.dump"
        default_name = "hq"

    # Resolve output XPN name
    if not output_name:
        output_xpn = f"{default_name}.xpn"
    else:
        # Allow user to specify full name with or without .xpn extension
        output_xpn = output_name if output_name.lower().endswith(".xpn") else f"{output_name}.xpn"

    # Pre-flight: dump existence + freshness.  The route dump is a cleanable
    # intermediate — finished P&R is proven by bin/xpn artifacts, so a missing
    # dump after a build means "re-run the flow", not "never routed".  A dump
    # older than any source file means the XPN would silently reflect the OLD
    # design (ddrc_fifo_demo case, 2026-10-10).
    dump_abs = os.path.join(work_dir, dump_path.lstrip("./").replace("/", os.sep))
    if not os.path.isfile(dump_abs):
        # -xpn reads a SPECIFIC flow's route result; the two flows' DBs are NOT
        # interchangeable (product: hq_run — insight: hqins_impl).
        if from_src and hqinsight:
            print("route dump 不存在——按 -from_src 自动执行 insight 实现流程"
                  "（等价 -insight -run，实现现有插桩网表，不重新探针插入）...")
            from . import insight as _insight
            proj = _insight.resolve_insight_project(hqprj_path, require_hqins=True)
            _insight.run_flow(proj, require_bin=False)
        if not os.path.isfile(dump_abs):
            mode_str = "hqinsight" if hqinsight else "normal"
            print(f"Error: route dump file not found for {mode_str} mode.")
            print(f"  Expected: {dump_abs}")
            has_bin = (glob.glob(os.path.join(work_dir, "hq_run", "*.bin"))
                       or glob.glob(os.path.join(work_dir, "*.bin")))
            if hqinsight and from_src:
                print(f"")
                print(f"  insight 实现流程已执行但 route dump 仍未生成——"
                      f"请检查上方流程日志中的 ERROR。")
            elif has_bin:
                names = ", ".join(os.path.basename(b) for b in has_bin[:2])
                print(f"")
                print(f"  工程存在布线产物（{names}），但那属于另一条流的数据库——"
                      f"两条流的布线结果不通用。")
                if hqinsight:
                    print(f"  insight 流的库在 hqins_impl：先 -insight -run，"
                          f"或直接 -xpn -ins -from_src 源码直达。")
                else:
                    print(f"  产品流的库在 hq_run：先 -build（或 -flow），"
                          f"或用 -xpn2bin 直接转换现成 XPN。")
            else:
                print(f"")
                print(f"  工程尚无任何布线产物——请先完成布局布线。")
                if hqinsight:
                    print(f"  insight 模式：先 -insight -init/-add 登记信号，再 -insight -run；"
                          f"或 -xpn -ins -from_src 源码直达。")
                else:
                    print(f"  产品模式：先 -build（或 -flow）。")
            sys.exit(1)

    stale = _stale_sources(hqprj_path, work_dir, dump_abs)
    if stale:
        print(f"Warning: 布线 dump 落后于 {len(stale)} 个更新的源文件——生成的 XPN 将基于旧设计：")
        for p in stale[:5]:
            print(f"  {p}")
        if len(stale) > 5:
            print(f"  ... 共 {len(stale)} 个")
        print(f"  如需反映最新设计，先重跑实现流程（hqbuddy -build 或 -flow）再 -xpn。", flush=True)

    # Resolve hqfpga (selected or latest version)
    version = launcher.require_hqfpga_version()
    hqfpga_path = version['hqfpga_path']

    # Generate temporary TCL
    temp_tcl = _generate_xpn_tcl(work_dir, dump_path, output_xpn)

    try:
        print(f"Generated temp TCL: {temp_tcl}")
        print(f"Mode: {'hqinsight' if hqinsight else 'normal'}")
        print(f"Dump: {dump_path}")
        print(f"Output: {output_xpn}")

        # Build command: hqfpga -cmd <temp_tcl>
        cmd = [hqfpga_path, "-cmd", temp_tcl]

        print(f"Launching: {' '.join(cmd)}")
        print("")

        # Run hqfpga in the work directory
        proc = subprocess.Popen(cmd, cwd=work_dir)
        try:
            proc.wait()
        except KeyboardInterrupt:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
            raise

        if proc.returncode != 0:
            print(f"")
            print(f"Warning: hqfpga exited with code {proc.returncode}")

    finally:
        # Clean up temporary TCL file
        if os.path.exists(temp_tcl):
            os.remove(temp_tcl)
            print(f"")
            print(f"Cleaned up temp TCL: {temp_tcl}")

    # Auto-open the generated XPN file
    output_abs = os.path.join(work_dir, output_xpn)
    if not os.path.isfile(output_abs):
        print(f"")
        print(f"Warning: XPN file was not generated: {output_abs}")
    elif open_file:
        print(f"")
        print(f"Opening XPN file: {output_abs}")
        try:
            webbrowser.open(f"file:///{output_abs.replace(os.sep, '/')}")
        except Exception as e:
            print(f"Warning: failed to open XPN file: {e}")
    else:
        print(f"")
        print(f"XPN ready: {output_abs}")


def run_xpn_inspect(xpn_path: str) -> None:
    """Parse an XPN physical netlist and print a structural summary."""
    if not os.path.isfile(xpn_path):
        print(f"Error: file not found: {xpn_path}")
        sys.exit(1)
    txt = open(xpn_path, encoding="utf-8", errors="replace").read()

    design = re.search(r"design\s+(\S+)", txt)
    arch = re.search(r"architecture\s+(\w+);", txt)
    dev = re.search(r"device\s+(\S+);", txt)
    pkg = re.search(r"package\s+(\S+);", txt)
    print(f"Design : {design.group(1) if design else '?'}")
    print(f"Device : {arch.group(1) if arch else '?'} {dev.group(1) if dev else '?'} {pkg.group(1) if pkg else '?'}")

    comps = re.findall(r'comp\s+"([^"]+)"\s*\{([^}]+)\}', txt)
    print(f"Comps  : {len(comps)}")
    models = {}
    for _, body in comps:
        cm = re.search(r"cellmodel-name\s+(\S+)\s*;", body)
        if cm:
            models[cm.group(1)] = models.get(cm.group(1), 0) + 1
    for k in sorted(models, key=models.get, reverse=True):
        print(f"  {k:20s} x{models[k]}")
    pinnames = re.findall(r'"PINNAME:\d+"\s+string\s+"([^"]+)"', txt)
    pintypes = re.findall(r'"PINTYPE:\d+"\s+string\s+"([^"]+)"', txt)
    print(f"IO     : {len(pinnames)}")
    for pn, pt in zip(pinnames, pintypes):
        print(f"  {pt:3s} {pn}")
    print(f"Size   : {os.path.getsize(xpn_path)} bytes")
