"""Third-party EDIF netlist flows: EDF-to-Verilog conversion and netlist P&R bitgen.

TCL chains verified on FT091226 (see skills/hqfpga/references/thirdparty_synthesis.md):
  EDF->Verilog: dv.setup SEAL <dev> + edif.read + nl.write <out.v> -eqn
  Netlist P&R:  dv.setup SEAL <dev> + edif.read + design.flatten + upc.read
                + sdc.read + impl.pack + impl.place + impl.route
                + impl.bitgen.xist.seal <bin> -bin

Known pitfalls guarded here:
  - hqfpga -cmd exit code does NOT reflect TCL errors (ERROR(...) can still
    exit 0) -> scan captured output for "ERROR(".
  - bitgen silently fakes success when the output directory does not exist
    -> makedirs the output dir and verify the artifact afterwards.
"""

import os
import subprocess
import sys
import tempfile

from . import launcher

# Family is fixed to SEAL for the third-party netlist flow; -device only
# selects the part within the SEAL family.
DEFAULT_DEVICE = "SA5Z-50-D0-7F484C"


def _resolve_hqfpga() -> str:
    """Resolve hqfpga path or exit with error."""
    version = launcher.resolve_hqfpga_version()
    if not version:
        print("Error: no HqFPGA versions found.")
        print("Tip: Use 'hqbuddy -cfg' to edit the scan roots in config.json.")
        sys.exit(1)
    return version['hqfpga_path']


def _tcl_path(path: str) -> str:
    """Forward-slash absolute path for TCL consumption."""
    return os.path.abspath(path).replace(os.sep, "/")


def _run_tcl_streamed(hqfpga_path: str, cmds: list, work_dir: str) -> list:
    """Write cmds to a temp TCL, run hqfpga -cmd with cwd=work_dir.

    Output is streamed to the console and captured line by line; the
    captured lines are returned so the caller can scan for ERROR(...).
    The temp TCL is always removed.
    """
    tcl_text = "\n".join(cmds) + "\nexit\n"
    fd, tcl_path = tempfile.mkstemp(suffix=".tcl", prefix="hqbuddy_netlist_")
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        f.write(tcl_text)

    lines = []
    try:
        proc = subprocess.Popen(
            [hqfpga_path, "-cmd", tcl_path], cwd=work_dir,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, errors="replace",
        )
        try:
            for raw in proc.stdout:
                sys.stdout.write(raw)
                lines.append(raw.rstrip("\n"))
            proc.wait()
        except KeyboardInterrupt:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
            raise
    finally:
        try:
            os.remove(tcl_path)
        except OSError:
            pass
    return lines


def _fail_on_tcl_errors(lines: list) -> None:
    """hqfpga -cmd exits 0 even when TCL raises ERROR(...); surface them."""
    errs = [ln.strip() for ln in lines if "ERROR(" in ln]
    if errs:
        print("")
        print(f"Error: hqfpga 输出中出现 {len(errs)} 处 ERROR（-cmd 退出码不反映 TCL 错误）:")
        for e in errs:
            print(f"  {e}")
        sys.exit(1)


def run_edf2v(edif_path: str | None, output_v: str | None = None,
              device: str | None = None) -> None:
    """
    Convert a third-party EDIF netlist to a Verilog netlist (nl.write -eqn).

    Args:
        edif_path: Path to the input .edif netlist.
        output_v: Optional output .v path (default: alongside the .edif).
        device: Optional SEAL-family device part (default SA5Z-50-D0-7F484C).
    """
    if not edif_path:
        print("Error: -edf2v requires an EDIF netlist file")
        print("Usage: hqbuddy -edf2v <a.edif> [-o <file.v>] [-device <part>]")
        sys.exit(1)
    if not os.path.isfile(edif_path):
        print(f"Error: file not found: {edif_path}")
        sys.exit(1)

    edif_abs = os.path.abspath(edif_path)
    work_dir = os.path.dirname(edif_abs)
    v_abs = os.path.abspath(output_v) if output_v else os.path.splitext(edif_abs)[0] + ".v"
    dev = device or DEFAULT_DEVICE
    hqfpga_path = _resolve_hqfpga()

    cmds = [
        f"dv.setup SEAL {dev}",
        f"edif.read {_tcl_path(edif_abs)}",
        f"nl.write {_tcl_path(v_abs)} -eqn",
    ]

    print(f"EDIF -> Verilog: {edif_abs}")
    print(f"Device: {dev} (family SEAL)")
    print(f"Output: {v_abs}")
    print("")

    lines = _run_tcl_streamed(hqfpga_path, cmds, work_dir)
    _fail_on_tcl_errors(lines)

    if not os.path.isfile(v_abs) or os.path.getsize(v_abs) == 0:
        print("")
        print("Error: EDF→Verilog 转换失败，未产出 .v（检查输出中 ERROR）")
        sys.exit(1)

    print(f"[OK] Verilog netlist written: {v_abs}")


def run_netlist_build(edif_path: str | None, upc_path: str | None = None,
                      sdc_path: str | None = None, output_bin: str | None = None,
                      device: str | None = None) -> None:
    """
    Run P&R + bitgen on a third-party EDIF netlist (Seal family).

    design.flatten must run before impl.pack (third-party netlists fail
    packing otherwise), and .upc/.sdc constraints are mandatory (bitgen
    reports BIT-11 without pin constraints).

    Args:
        edif_path: Path to the input .edif netlist.
        upc_path: Path to the pin constraint .upc (required).
        sdc_path: Path to the timing constraint .sdc (required).
        output_bin: Optional output .bin path (default: alongside the .edif).
        device: Optional SEAL-family device part (default SA5Z-50-D0-7F484C).
    """
    if not edif_path:
        print("Error: -netlist_build requires an EDIF netlist file")
        print("Usage: hqbuddy -netlist_build <a.edif> --upc <u.upc> --sdc <s.sdc>"
              " [-o <out.bin>] [-device <part>]")
        sys.exit(1)
    if not upc_path or not sdc_path:
        print("Error: -netlist_build requires both --upc and --sdc constraints")
        print("Usage: hqbuddy -netlist_build <a.edif> --upc <u.upc> --sdc <s.sdc>"
              " [-o <out.bin>] [-device <part>]")
        print("  第三方网表 bitgen 前必须有引脚约束(.upc)与时序约束(.sdc)，"
              "缺 .upc 会报 ERROR(BIT-11)")
        sys.exit(1)
    if not os.path.isfile(edif_path):
        print(f"Error: file not found: {edif_path}")
        sys.exit(1)
    for label, p in (("--upc", upc_path), ("--sdc", sdc_path)):
        if not os.path.isfile(p):
            print(f"Error: file not found: {p} ({label})")
            sys.exit(1)

    edif_abs = os.path.abspath(edif_path)
    work_dir = os.path.dirname(edif_abs)
    bin_abs = os.path.abspath(output_bin) if output_bin else os.path.splitext(edif_abs)[0] + ".bin"
    # bitgen silently fakes success when the output directory does not exist
    bin_dir = os.path.dirname(bin_abs) or "."
    os.makedirs(bin_dir, exist_ok=True)

    dev = device or DEFAULT_DEVICE
    hqfpga_path = _resolve_hqfpga()

    cmds = [
        f"dv.setup SEAL {dev}",
        f"edif.read {_tcl_path(edif_abs)}",
        "design.flatten",
        f"upc.read {_tcl_path(upc_path)}",
        f"sdc.read {_tcl_path(sdc_path)}",
        "impl.pack",
        "impl.place",
        "impl.route",
        f"impl.bitgen.xist.seal {_tcl_path(bin_abs)} -bin",
    ]

    print(f"Netlist P&R + bitgen: {edif_abs}")
    print(f"Device: {dev} (family SEAL)")
    print(f"UPC: {os.path.abspath(upc_path)}")
    print(f"SDC: {os.path.abspath(sdc_path)}")
    print(f"Output: {bin_abs}")
    print("")

    lines = _run_tcl_streamed(hqfpga_path, cmds, work_dir)
    _fail_on_tcl_errors(lines)

    if not os.path.isfile(bin_abs) or os.path.getsize(bin_abs) == 0:
        print("")
        print("Error: 网表编译未产出 bin（bitgen 可能静默假成功：检查输出目录与输出中 ERROR）")
        sys.exit(1)

    size = os.path.getsize(bin_abs)
    print(f"[OK] Netlist bitstream written: {bin_abs} ({size} bytes)")
