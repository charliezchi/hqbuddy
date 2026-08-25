"""Simulation library management: compile XiST primitives into ModelSim/QuestaSim."""

import os
import shutil
import subprocess
import sys
import importlib.resources as pkg_resources

from . import launcher


def _check_vsim() -> str | None:
    """Check if vsim is available in PATH."""
    return shutil.which("vsim")


def _get_hqfpga_root(user_root: str | None = None) -> str:
    """
    Resolve the HQFPGA installation root directory.

    Args:
        user_root: Optional user-specified HQFPGA root.

    Returns:
        Absolute path to the HQFPGA root directory.
    """
    if user_root:
        root = os.path.abspath(user_root)
        if not os.path.isdir(root):
            print(f"Error: directory not found: {root}")
            sys.exit(1)
        return root

    # Use internal scanner/launcher to find the selected version
    root = launcher.resolve_hqfpga_root()
    if root:
        return os.path.abspath(root)

    # Try common environment variables as fallback
    for env_var in ["HQ", "XIST", "HQFPGA_ROOT"]:
        env_root = os.environ.get(env_var)
        if env_root and os.path.isdir(env_root):
            return os.path.abspath(env_root)

    print("Error: could not determine HQFPGA root directory.")
    print("")
    print("Please specify the HQFPGA installation root directory:")
    print("  hqbuddy -simlib C:/hqv3_xist_3.1.1_FT053026_win64")
    print("")
    print("Or use 'hqbuddy -cfg' to edit the scan roots in config.json.")
    sys.exit(1)


def _get_xist_dir(hqfpga_root: str) -> str:
    """Get the XIST simulation library directory."""
    xist_dir = os.path.join(hqfpga_root, "build", "common", "sim", "verilog", "XIST")
    if not os.path.isdir(xist_dir):
        print(f"Error: XIST directory not found: {xist_dir}")
        print("Please verify the HQFPGA installation root directory.")
        sys.exit(1)
    return xist_dir


def _get_models_root(vsim_path: str) -> str:
    """Get ModelSim/QuestaSim installation root from vsim path."""
    # vsim is typically at <ms_root>/win64/vsim.exe or <ms_root>/win32/vsim.exe
    return os.path.dirname(os.path.dirname(vsim_path))


def _ensure_writable(path: str) -> bool:
    """Ensure the file is writable. On Windows, try to clear the read-only attribute."""
    if os.access(path, os.W_OK):
        return True

    if sys.platform == "win32":
        # Use attrib command to remove read-only attribute
        try:
            subprocess.run(["attrib", "-R", path], check=True, capture_output=True, text=True)
            return os.access(path, os.W_OK)
        except Exception:
            return False

    return False


def _update_modelsim_ini(models_root: str) -> None:
    """Add XiST library mapping to modelsim.ini."""
    ini_path = os.path.join(models_root, "modelsim.ini")

    if not os.path.isfile(ini_path):
        print(f"Warning: modelsim.ini not found: {ini_path}")
        print("Please add the following line manually to modelsim.ini:")
        print("  XiST = $MODEL_TECH/../XiST")
        return

    # Ensure modelsim.ini is writable
    if not _ensure_writable(ini_path):
        print(f"Error: cannot write to modelsim.ini: {ini_path}")
        print("Please remove the read-only attribute manually and re-run.")
        print("Or add the following line manually:")
        print("  XiST = $MODEL_TECH/../XiST")
        return

    # Check if already present
    with open(ini_path, "r", encoding="utf-8") as f:
        content = f.read()

    if "XiST = $MODEL_TECH/../XiST" in content:
        print("modelsim.ini already contains XiST mapping.")
        return

    # Try to insert under [Library] section
    lines = content.splitlines(keepends=True)
    new_lines = []
    inserted = False

    for i, line in enumerate(lines):
        new_lines.append(line)
        if not inserted and line.strip().lower() == "[library]":
            # Insert after the section header
            new_lines.append("XiST = $MODEL_TECH/../XiST\n")
            inserted = True

    if not inserted:
        # Append at the end
        if new_lines and not new_lines[-1].endswith("\n"):
            new_lines.append("\n")
        new_lines.append("[Library]\n")
        new_lines.append("XiST = $MODEL_TECH/../XiST\n")

    with open(ini_path, "w", encoding="utf-8") as f:
        f.writelines(new_lines)

    print(f"Updated modelsim.ini: {ini_path}")
    print("  Added: XiST = $MODEL_TECH/../XiST")


def run_simlib(hqfpga_root: str | None = None) -> None:
    """
    Compile XiST primitives into ModelSim/QuestaSim.

    Args:
        hqfpga_root: Optional HQFPGA installation root. If None, auto-detect.
    """
    # Check vsim availability
    vsim_path = _check_vsim()
    if not vsim_path:
        print("Error: vsim not found in PATH.")
        print("")
        print("Please install ModelSim or QuestaSim and ensure 'vsim' is in PATH.")
        sys.exit(1)

    # Resolve HQFPGA root
    root = _get_hqfpga_root(hqfpga_root)
    print(f"HQFPGA root: {root}")

    # Locate XIST directory
    xist_dir = _get_xist_dir(root)
    print(f"XIST directory: {xist_dir}")

    # Copy bundled compile_xist.tcl to XIST directory
    script_dst = os.path.join(xist_dir, "compile_xist.tcl")

    try:
        # Read bundled script from package resources (works for both source and PyInstaller)
        script_content = pkg_resources.read_text("scripts", "compile_xist.tcl")
        with open(script_dst, "w", encoding="utf-8") as f:
            f.write(script_content)
        print(f"Copied compile script to: {script_dst}")
    except Exception as e:
        print(f"Error: failed to extract bundled compile_xist.tcl: {e}")
        sys.exit(1)

    # Ensure modelsim.ini is writable before running vsim
    # because vmap inside compile_xist.tcl needs to modify it
    models_root = _get_models_root(vsim_path)
    ini_path = os.path.join(models_root, "modelsim.ini")
    if os.path.isfile(ini_path):
        if not _ensure_writable(ini_path):
            print(f"Error: cannot write to modelsim.ini: {ini_path}")
            print("Please remove the read-only attribute manually and re-run.")
            sys.exit(1)
        print(f"Ensured modelsim.ini is writable: {ini_path}")

    # Run vsim -c -do compile_xist.tcl in XIST directory
    cmd = [vsim_path, "-c", "-do", "compile_xist.tcl"]
    print(f"")
    print(f"Launching: {' '.join(cmd)}")
    print(f"Working directory: {xist_dir}")
    print("")

    proc = subprocess.Popen(cmd, cwd=xist_dir)
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
        print(f"Warning: vsim exited with code {proc.returncode}")

    # Update modelsim.ini (in case TCL script did not handle it)
    print(f"")
    _update_modelsim_ini(models_root)
