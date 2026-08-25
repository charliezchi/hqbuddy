"""XPN generation: generate temp TCL and launch hqfpga -cmd."""

import os
import subprocess
import sys
import webbrowser

from . import launcher


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


def run_xpn(hqprj_path: str, output_name: str | None = None, hqinsight: bool = False) -> None:
    """
    Run the xpn generation command.

    Args:
        hqprj_path: Path to the .hqprj file.
        output_name: Optional custom output XPN file name.
        hqinsight: If True, use hqinsight mode path; otherwise normal mode.
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

    # Check if dump file exists
    dump_abs = os.path.join(work_dir, dump_path.lstrip("./").replace("/", os.sep))
    if not os.path.isfile(dump_abs):
        mode_str = "hqinsight" if hqinsight else "normal"
        print(f"Error: route dump file not found for {mode_str} mode.")
        print(f"  Expected: {dump_abs}")
        print(f"")
        print(f"Please ensure the design has been routed before generating XPN.")
        sys.exit(1)

    # Resolve hqfpga (selected or latest version)
    version = launcher.resolve_hqfpga_version()
    if not version:
        print("Error: no HqFPGA versions found.")
        print("Tip: Use 'hqbuddy -cfg' to edit the scan roots in config.json.")
        sys.exit(1)
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
    if os.path.isfile(output_abs):
        print(f"")
        print(f"Opening XPN file: {output_abs}")
        try:
            webbrowser.open(f"file:///{output_abs.replace(os.sep, '/')}")
        except Exception as e:
            print(f"Warning: failed to open XPN file: {e}")
    else:
        print(f"")
        print(f"Warning: XPN file was not generated: {output_abs}")
