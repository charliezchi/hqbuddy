"""Simulation library management: compile XiST primitives into ModelSim/QuestaSim.

Since 3.45.0 each device family gets its own library (XiST_SEAL / XiST_SEALION /
XiST_SHARK) because same-name primitives differ between families (e.g. xsLUT4);
compiling them into one library silently overwrites one family's models with
another's depending on compile order.
"""

import os
import re
import shutil
import subprocess
import sys

from . import launcher

# Family source dir (under build/common/sim/verilog/XIST/) -> ModelSim library name
FAMILY_LIBS = {
    "seal": "XiST_SEAL",
    "sealion": "XiST_SEALION",
    "shark": "XiST_SHARK",
}

# Pre-3.45.0 single library name; its modelsim.ini mapping is removed on re-run
LEGACY_LIB = "XiST"


def _check_vsim() -> str | None:
    """Check if vsim is available in PATH."""
    return shutil.which("vsim")


def _get_hqfpga_root(user_root: str | None = None) -> str:
    """
    Resolve the HQFPGA installation root directory.

    Args:
        user_root: Optional user-specified HQFPGA root.

    Returns:
        Absolute path to the HQFPGA installation root.
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
    """Ensure the file is writable. os.access on Windows only reflects the
    read-only attribute (not ACLs), so probe by opening for append."""

    def _probe() -> bool:
        try:
            with open(path, "a"):
                return True
        except OSError:
            return False

    if _probe():
        return True

    if sys.platform == "win32":
        # Use attrib command to remove read-only attribute
        try:
            subprocess.run(["attrib", "-R", path], check=True, capture_output=True, text=True)
        except Exception:
            return False
        return _probe()

    return False


def _mapping_lines() -> list:
    """modelsim.ini mapping lines for the per-family libraries."""
    return [f"{lib} = $MODEL_TECH/../{lib}" for lib in FAMILY_LIBS.values()]


def _manual_hint() -> None:
    print("Please add the following lines manually to modelsim.ini:")
    for m in _mapping_lines():
        print(f"  {m}")


def _update_modelsim_ini(models_root: str) -> None:
    """Add per-family XiST_* library mappings to modelsim.ini and drop the
    legacy single-library XiST mapping (superseded by family libraries)."""
    ini_path = os.path.join(models_root, "modelsim.ini")

    if not os.path.isfile(ini_path):
        print(f"Warning: modelsim.ini not found: {ini_path}")
        _manual_hint()
        return

    # Ensure modelsim.ini is writable
    if not _ensure_writable(ini_path):
        print(f"Error: cannot write to modelsim.ini: {ini_path}")
        print("Please remove the read-only attribute manually and re-run "
              "(installs under Program Files need an administrator terminal).")
        _manual_hint()
        return

    with open(ini_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Drop legacy single-library mapping line ("XiST = ..."); per-family lines
    # (XiST_SEAL = ...) never match this pattern.
    new_lines = [ln for ln in content.splitlines(keepends=True)
                 if not re.match(r"^XiST\s*=", ln.strip("\r\n"))]
    dropped = len(content.splitlines(keepends=True)) - len(new_lines)
    if dropped:
        print(f"Removed legacy single-library mapping ({LEGACY_LIB}); "
              f"use XiST_SEAL / XiST_SEALION / XiST_SHARK instead.")

    # Insert missing family mappings right after the [Library] section header
    inserted_all = True
    out_lines = []
    for ln in new_lines:
        out_lines.append(ln)
        if ln.strip().lower() == "[library]":
            for m in _mapping_lines():
                key = m.split(" = ")[0]
                if not any(l.strip().startswith(key + " ") or l.strip() == key
                           for l in new_lines):
                    out_lines.append(m + "\n")
                    print(f"  Added: {m}")
                else:
                    inserted_all = False
    if inserted_all and not dropped:
        if all(any(l.strip().startswith(m.split(" = ")[0] + " ")
                   for l in new_lines) for m in _mapping_lines()):
            print("modelsim.ini already contains XiST_* family mappings.")
            return
    if not any(ln.strip().lower() == "[library]" for ln in new_lines):
        # No [Library] section: append one
        if out_lines and not out_lines[-1].endswith("\n"):
            out_lines.append("\n")
        out_lines.append("[Library]\n")
        for m in _mapping_lines():
            out_lines.append(m + "\n")
            print(f"  Added: {m}")

    with open(ini_path, "w", encoding="utf-8") as f:
        f.writelines(out_lines)

    print(f"Updated modelsim.ini: {ini_path}")


def run_simlib(hqfpga_root: str | None = None) -> None:
    """
    Compile XiST primitives into ModelSim/QuestaSim, one library per device
    family: XiST_SEAL / XiST_SEALION / XiST_SHARK.

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
        # Read the bundled script from the templates dir (repo tree or PyInstaller bundle)
        bundled = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                               'templates', 'compile_xist.tcl')
        with open(bundled, 'r', encoding='utf-8') as f:
            script_content = f.read()
        with open(script_dst, "w", encoding="utf-8", newline="") as f:
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
            print("Please remove the read-only attribute manually and re-run "
                  "(installs under Program Files need an administrator terminal).")
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
        proc.wait(timeout=900)
    except subprocess.TimeoutExpired:
        proc.kill()
        proc.wait()
        print("")
        print("Error: vsim 库编译超时（900s）——进程已终止。")
        print("Tip: 重跑 hqbuddy -simlib；若持续超时检查 ModelSim 授权与磁盘。")
        sys.exit(1)
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
