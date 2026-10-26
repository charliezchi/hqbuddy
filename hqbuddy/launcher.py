"""Launch HqFpga tools and resolve tool paths."""

import os
import subprocess
import sys

from . import config, scanner
from .utils import wait_process


def resolve_hqfpga_version() -> dict | None:
    """
    Resolve the selected (or latest) HqFPGA version dict.

    Returns:
        Version dict, or None if no versions found.
    """
    cfg = config.load_config()
    versions = scanner.scan_all(cfg)
    if not versions:
        return None
    return scanner.get_selected_version(versions, cfg.get("selected_build"))


def resolve_hqfpga_root() -> str | None:
    """Resolve the selected (or latest) HqFPGA install root path."""
    v = resolve_hqfpga_version()
    return v['path'] if v else None


def die_no_versions() -> None:
    """Print the standard 'no versions' error and exit."""
    print("Error: no HqFPGA versions found.")
    print("Tip: Use 'hqbuddy -cfg' to edit the scan roots in config.json.")
    sys.exit(1)


def require_hqfpga_version() -> dict:
    """resolve_hqfpga_version() or exit with the standard error."""
    version = resolve_hqfpga_version()
    if not version:
        die_no_versions()
    return version


def launch_tool(version: dict, tool: str, extra_args: list) -> None:
    """
    Launch hqfpga, hqui, hqdnload, or cable for a given version.

    Args:
        version: Version dict from scanner.
        tool: 'hqfpga', 'hqui', 'hqdnload', or 'cable'.
        extra_args: Additional command-line arguments to pass to the tool.
    """
    tool_key = f'{tool}_path'
    has_key = f'has_{tool}'

    if tool_key not in version:
        print(f"Error: Unknown tool '{tool}'")
        sys.exit(1)

    if not version.get(has_key, False):
        print(f"Error: {tool}.exe not found in {version['path']}")
        sys.exit(1)

    exe_path = version[tool_key]
    if not os.path.exists(exe_path):
        print(f"Error: Executable not found: {exe_path}")
        sys.exit(1)

    cmd = [exe_path] + extra_args

    try:
        if tool in ('hqui', 'hqdnload'):
            # GUI tools: detach so we don't block the terminal
            creationflags = subprocess.DETACHED_PROCESS | subprocess.CREATE_NEW_PROCESS_GROUP
            subprocess.Popen(cmd, creationflags=creationflags, close_fds=True)
            print(f"Launched {tool} v{version['semver']} (build {version['build']})")
        else:
            # CLI tool: run in foreground, inherit stdin/stdout/stderr
            proc = subprocess.Popen(cmd)
            wait_process(proc)
    except Exception as e:
        print(f"Error launching {tool}: {e}")
        sys.exit(1)
