"""Launch HqFpga tools and resolve tool paths."""

import os
import subprocess
import sys

from . import config, scanner


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
    except Exception as e:
        print(f"Error launching {tool}: {e}")
        sys.exit(1)


def open_path(path: str) -> None:
    """Open a file or directory with the default application."""
    if not os.path.exists(path):
        print(f"Error: Path not found: {path}")
        sys.exit(1)
    try:
        os.startfile(path)
    except Exception as e:
        print(f"Error opening path: {e}")
        sys.exit(1)
