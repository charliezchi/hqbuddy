"""Flow execution: generate temp TCL and launch hqfpga -cmd."""

import os
import subprocess
import sys

from . import launcher


def _generate_temp_tcl(hqprj_path: str, output_tcl: str | None = None) -> str:
    """
    Generate a temporary TCL script in the same directory as the .hqprj file.

    Args:
        hqprj_path: Path to the .hqprj file.
        output_tcl: Optional custom output TCL file name.

    Returns:
        Path to the generated temporary TCL file.
    """
    work_dir = os.path.dirname(os.path.abspath(hqprj_path))
    hqprj_abs = os.path.abspath(hqprj_path)

    # Use a fixed temp file name to avoid collisions
    temp_tcl = os.path.join(work_dir, "_hqbuddy_flow_temp.tcl")

    # Use forward slashes in TCL to avoid backslash escaping issues
    hqprj_tcl = hqprj_abs.replace("\\", "/")

    if output_tcl:
        tcl_content = f"hqprj2tcl {hqprj_tcl} {output_tcl}\n"
    else:
        tcl_content = f"hqprj2tcl {hqprj_tcl}\n"

    with open(temp_tcl, "w", encoding="utf-8") as f:
        f.write(tcl_content)

    return temp_tcl


def run_flow(hqprj_path: str, output_tcl: str | None = None) -> None:
    """
    Run the flow command: generate temp TCL and execute via hqfpga.

    Args:
        hqprj_path: Path to the .hqprj file.
        output_tcl: Optional custom output TCL file name.
    """
    if not os.path.isfile(hqprj_path):
        print(f"Error: file not found: {hqprj_path}")
        sys.exit(1)

    work_dir = os.path.dirname(os.path.abspath(hqprj_path))

    # Resolve hqfpga (selected or latest version)
    version = launcher.resolve_hqfpga_version()
    if not version:
        print("Error: no HqFPGA versions found.")
        print("Tip: Use 'hqbuddy -cfg auto' to configure scan roots.")
        sys.exit(1)
    hqfpga_path = version['hqfpga_path']

    # Generate temporary TCL
    temp_tcl = _generate_temp_tcl(hqprj_path, output_tcl)

    try:
        print(f"Generated temp TCL: {temp_tcl}")

        # Build command: hqfpga -cmd <temp_tcl>
        cmd = [hqfpga_path, "-cmd", temp_tcl]

        print(f"Launching: {' '.join(cmd)}")
        print("")

        # Run hqfpga in the .hqprj directory so output TCL is generated there
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
