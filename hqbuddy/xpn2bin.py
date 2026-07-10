"""XPN to BIN conversion: generate temp TCL and launch hqfpga -cmd."""

import os
import subprocess
import sys

from . import launcher


def _generate_xpn2bin_tcl(work_dir: str, xpn_name: str, bin_name: str) -> str:
    """
    Generate a temporary TCL script for xpn2bin conversion.

    Args:
        work_dir: The directory where the .xpn file resides.
        xpn_name: The input .xpn file name.
        bin_name: The output .bin file name.

    Returns:
        Path to the generated temporary TCL file.
    """
    temp_tcl = os.path.join(work_dir, "_hqbuddy_xpn2bin.tcl")

    tcl_content = f"""xpn.read {xpn_name}
design.bitgen -bin {bin_name} -compress
"""

    with open(temp_tcl, "w", encoding="utf-8") as f:
        f.write(tcl_content)

    return temp_tcl


def run_xpn2bin(xpn_path: str, bin_path: str | None = None) -> None:
    """
    Run the xpn2bin conversion command.

    Args:
        xpn_path: Path to the input .xpn file.
        bin_path: Optional path to the output .bin file.
    """
    if not os.path.isfile(xpn_path):
        print(f"Error: file not found: {xpn_path}")
        sys.exit(1)

    xpn_abs = os.path.abspath(xpn_path)
    work_dir = os.path.dirname(xpn_abs)
    xpn_name = os.path.basename(xpn_abs)

    # Resolve output bin path
    if bin_path:
        bin_abs = os.path.abspath(bin_path)
    else:
        bin_abs = os.path.splitext(xpn_abs)[0] + ".bin"

    bin_name = os.path.basename(bin_abs)

    # Resolve hqfpga (selected or latest version)
    version = launcher.resolve_hqfpga_version()
    if not version:
        print("Error: no HqFPGA versions found.")
        print("Tip: Use 'hqbuddy -cfg auto' to configure scan roots.")
        sys.exit(1)
    hqfpga_path = version['hqfpga_path']

    # Generate temporary TCL
    temp_tcl = _generate_xpn2bin_tcl(work_dir, xpn_name, bin_name)

    try:
        print(f"Generated temp TCL: {temp_tcl}")
        print(f"Input:  {xpn_abs}")
        print(f"Output: {bin_abs}")

        # Build command: hqfpga -cmd <temp_tcl>
        cmd = [hqfpga_path, "-cmd", temp_tcl]

        print(f"Launching: {' '.join(cmd)}")
        print("")

        # Run hqfpga in the .xpn directory
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
