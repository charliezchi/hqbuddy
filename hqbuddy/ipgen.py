"""IP generation: resolve ipgen executable and run it for a .hqip file."""

import glob
import os
import subprocess
import sys

from . import launcher


def _find_hqip(arg: str | None) -> str:
    """Resolve .hqip path from argument or auto-detect in current directory."""
    if arg:
        if not os.path.isfile(arg):
            print(f"Error: file not found: {arg}")
            sys.exit(1)
        return os.path.abspath(arg)

    matches = glob.glob("*.hqip")
    if not matches:
        print("Error: no .hqip file specified and none found in current directory.")
        sys.exit(1)
    return os.path.abspath(matches[0])


def _parse_meta_file(hqip_path: str) -> str:
    """Extract meta_file path from .hqip file."""
    with open(hqip_path, "r", encoding="utf-8") as f:
        for line in f:
            stripped = line.strip()
            if stripped.startswith("meta_file="):
                return stripped[len("meta_file="):]
    print(f"Error: no meta_file= found in {hqip_path}")
    sys.exit(1)


def _extract_xml_relative(meta_file: str) -> str:
    """Extract the path portion after the first '/build/' segment."""
    normalized = meta_file.replace("\\", "/")
    marker = "/build/"
    idx = normalized.find(marker)
    if idx < 0:
        print(f"Error: meta_file does not contain '/build/': {meta_file}")
        sys.exit(1)
    return normalized[idx + len(marker):]


def _resolve_local_xml(hqfpga_root: str, rel: str) -> str:
    """Join HqFPGA root with the relative XML path and verify it exists."""
    xml_path = os.path.join(hqfpga_root, "build", rel.replace("/", os.sep))
    if not os.path.isfile(xml_path):
        print(f"Error: local meta_xml not found: {xml_path}")
        sys.exit(1)
    return xml_path.replace("\\", "/")


def _parse_ipgen_desc(xml_dir: str) -> str:
    """Parse _ipgen_.desc in the XML directory and return the raw EXE line."""
    desc_path = os.path.join(xml_dir, "_ipgen_.desc")
    if not os.path.isfile(desc_path):
        print(f"Error: _ipgen_.desc not found in {xml_dir}")
        sys.exit(1)

    with open(desc_path, "r", encoding="utf-8") as f:
        for line in f:
            stripped = line.strip()
            if stripped.startswith("EXE="):
                return stripped[len("EXE="):]

    print(f"Error: no EXE= found in {desc_path}")
    sys.exit(1)


def _resolve_hqfpga_exe(hqfpga_root: str) -> str:
    """Resolve hqfpga.exe under the selected build."""
    exe = os.path.join(hqfpga_root, "build", "win_x64", "bin", "hqfpga.exe")
    if not os.path.isfile(exe):
        print(f"Error: hqfpga.exe not found: {exe}")
        sys.exit(1)
    return exe.replace("\\", "/")


def _run_ipgen_cmd(ipgen_exe: str, xml: str, hqip: str, hq_exe: str, lang: str, cwd: str) -> None:
    """Run the IP generator."""
    cmd = [ipgen_exe, "-meta_xml", xml, "-ini_file", hqip, "-hq_exe", hq_exe, "-lang", lang]
    print(f"Launching: {' '.join(cmd)}")
    print("")

    proc = subprocess.Popen(cmd, cwd=cwd)
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
        print(f"Warning: ipgen exited with code {proc.returncode}")


def run_ipgen(hqip_path: str | None = None, lang: str = "chs") -> None:
    """
    Run the IP generator for a .hqip file.

    Args:
        hqip_path: Optional path to .hqip file. If None, auto-detect in cwd.
        lang: Language passed to ipgen -lang (default: chs).
    """
    hqip_abs = _find_hqip(hqip_path)
    hqip_dir = os.path.dirname(hqip_abs)

    # Parse meta_file from .hqip
    meta_file = _parse_meta_file(hqip_abs)
    xml_rel = _extract_xml_relative(meta_file)

    # Resolve local HqFPGA root
    hqfpga_root = launcher.resolve_hqfpga_root()
    if not hqfpga_root:
        print("Error: no HqFPGA versions found.")
        print("Tip: Use 'hqbuddy -cfg auto' to configure scan roots.")
        sys.exit(1)

    # Resolve local XML
    xml_path = _resolve_local_xml(hqfpga_root, xml_rel)
    xml_dir = os.path.dirname(xml_path)

    # Resolve ipgen executable from _ipgen_.desc
    exe_line = _parse_ipgen_desc(xml_dir)
    ipcreator_root = os.path.join(hqfpga_root, "build", "ipcreator").replace("\\", "/")
    ipgen_exe = exe_line.replace("<ROOT>", ipcreator_root)
    if not os.path.isfile(ipgen_exe):
        print(f"Error: ipgen executable not found: {ipgen_exe}")
        sys.exit(1)

    # Resolve hqfpga.exe
    hq_exe = _resolve_hqfpga_exe(hqfpga_root)

    # Execute
    _run_ipgen_cmd(ipgen_exe, xml_path, hqip_abs, hq_exe, lang, hqip_dir)
