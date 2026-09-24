"""XPN to BIN conversion: generate temp TCL and launch hqfpga -cmd."""

import glob
import os
import re
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


def _download_bin(version: dict, bin_abs: str) -> int:
    """
    Download a .bin file to the connected board via cable.exe.

    Detects the board model first, then downloads with --Burst.

    Returns:
        0 on success, 1 on failure.
    """
    cable = version.get('cable_path')
    if not cable or not os.path.isfile(cable):
        print("Error: cable.exe not found in this HqFpga installation.")
        return 1

    print("")
    print("Detecting board model ...")
    r = subprocess.run([cable, '--detect_model'],
                       capture_output=True, text=True, errors='replace',
                       timeout=60)
    m = re.search(r'Device Model\s*:\s*(\S+)', r.stdout or '')
    if not m:
        print("Error: failed to detect board model, download aborted. cable output:")
        print((r.stdout or '').strip() or '(no output)')
        return 1
    model = m.group(1)
    print(f"Board model: {model}")

    cmd = [cable, '--sealion', bin_abs, '--model', model, '--Burst']
    print(f"Downloading: {bin_abs}")
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                          text=True, errors='replace')
    print(proc.stdout)
    # cable.exe prints errors like "Error : The file ID is unmatched"
    # but may still exit 0 — scan the output, don't trust the exit code
    has_error = re.search(r'^\s*(error|fail)', proc.stdout or '', re.M | re.I)
    if proc.returncode != 0 or has_error:
        print(f"Error: download failed (exit {proc.returncode})")
        return 1
    print("Download OK.")
    return 0


def _convert_one(version: dict, xpn_abs: str, bin_path: str | None,
                 download: bool) -> tuple[bool, str | None, str | None]:
    """
    Convert one .xpn file to .bin, optionally downloading it to the board.

    Args:
        version: Resolved HqFpga version info dict.
        xpn_abs: Absolute path to the input .xpn file.
        bin_path: Optional output .bin path (only the basename is used;
            bitgen always writes next to the .xpn).
        download: Download the bin to the board after conversion.

    Returns:
        (ok, bin_abs, error) — bin_abs is the produced file on success,
        error is a failure description otherwise.
    """
    work_dir = os.path.dirname(xpn_abs)
    xpn_name = os.path.basename(xpn_abs)
    bin_name = os.path.basename(bin_path) if bin_path \
        else os.path.splitext(xpn_name)[0] + ".bin"

    temp_tcl = _generate_xpn2bin_tcl(work_dir, xpn_name, bin_name)
    try:
        # bitgen runs with cwd=work_dir and a bare -bin name, so the output
        # always lands next to the .xpn regardless of the caller's cwd
        bin_abs = os.path.join(work_dir, bin_name)
        print(f"Input:  {xpn_abs}")
        print(f"Output: {bin_abs}")

        cmd = [version['hqfpga_path'], "-cmd", temp_tcl]
        print(f"Launching: {' '.join(cmd)}")
        print("")

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
            return False, None, f"hqfpga exited with code {proc.returncode}"

        if not os.path.isfile(bin_abs):
            return False, None, f"expected output not found: {bin_abs}"

        if download and _download_bin(version, bin_abs) != 0:
            return False, bin_abs, "download failed"

        return True, bin_abs, None
    finally:
        if os.path.exists(temp_tcl):
            os.remove(temp_tcl)
            print(f"")
            print(f"Cleaned up temp TCL: {temp_tcl}")


def run_xpn2bin(xpn_path: str | None = None, bin_path: str | None = None,
                download: bool = True) -> None:
    """
    Run the xpn2bin conversion command.

    With xpn_path, converts just that file (bin_path optionally overrides the
    output name) and downloads the bin to the board. Without xpn_path,
    converts every .xpn in the current directory and prints a summary report;
    with multiple targets the bins are NOT downloaded one by one — the GUI
    downloader (-dl) is launched instead. download=False (-no_dl) skips any
    download step.
    """
    if xpn_path:
        if not os.path.isfile(xpn_path):
            print(f"Error: file not found: {xpn_path}")
            sys.exit(1)
        targets = [(os.path.abspath(xpn_path), bin_path)]
    else:
        xpns = sorted(glob.glob("*.xpn"))
        if not xpns:
            print("Error: no .xpn file specified and none found in current directory.")
            sys.exit(1)
        targets = [(os.path.abspath(x), None) for x in xpns]

    # Resolve hqfpga (selected or latest version)
    version = launcher.require_hqfpga_version()

    batch = len(targets) > 1
    results = []  # (xpn_abs, ok, bin_abs, error)
    for xpn_abs, bp in targets:
        if batch:
            print(f"===== {os.path.basename(xpn_abs)} =====")
        # Batch mode never downloads per file; the GUI downloader is
        # launched after the report instead
        ok, bin_abs, error = _convert_one(version, xpn_abs, bp,
                                          download and not batch)
        results.append((xpn_abs, ok, bin_abs, error))
        if batch:
            print(f"[{'OK' if ok else 'FAIL'}] {os.path.basename(xpn_abs)}"
                  + ("" if ok else f": {error}"))
            print("")

    if batch:
        print("===== xpn2bin report =====")
        for xpn_abs, ok, bin_abs, error in results:
            name = os.path.basename(xpn_abs)
            if ok:
                print(f"[OK]   {name} -> {os.path.basename(bin_abs)}")
            else:
                print(f"[FAIL] {name}: {error}")
        n_ok = sum(1 for _, ok, _, _ in results if ok)
        print(f"{n_ok}/{len(results)} succeeded")

        if download and n_ok > 0:
            cable = version.get('cable_path')
            if not cable or not os.path.isfile(cable):
                print("Error: cable.exe not found in this HqFpga installation, "
                      "skipping downloader GUI.")
                sys.exit(1)
            from . import downloader
            downloader.spawn_gui_detached()
            print("Downloader GUI launched (detached) — pick a bin to download.")
    elif not results[0][1]:
        print(f"Error: {results[0][3]}")

    if not all(ok for _, ok, _, _ in results):
        sys.exit(1)
