"""Interactive build selection using keyboard navigation."""

import msvcrt
import sys

from . import config, scanner


def _clear_lines(n: int):
    """Move cursor up n lines and clear them."""
    for _ in range(n):
        sys.stdout.write('\033[F\033[K')
    sys.stdout.flush()


def _draw_menu(versions: list, selected_idx: int, current_build: str | None):
    """Draw the version selection menu."""
    lines = len(versions) + 2  # header + versions + prompt
    print("Available HqFPGA versions:")
    print("")
    for i, v in enumerate(versions):
        marker = ">" if v['build'] == current_build else " "
        cursor = " \u25b6" if i == selected_idx else "  "
        print(f" {cursor} {marker} v{v['semver']}  (build {v['build']})")
    sys.stdout.flush()


def run_build_selector() -> str | None:
    """
    Run interactive build selection.

    Returns:
        Selected build string, or None if user cancelled / no versions.
    """
    cfg = config.load_config()
    versions = scanner.scan_all(cfg)
    if not versions:
        print("No HqFPGA versions found.")
        print("Tip: Use 'hqbuddy -cfg auto' or 'hqbuddy -cfg set-root' to configure.")
        return None

    current_build = cfg.get("selected_build")
    current_idx = 0
    # Find current build index, default to 0 (latest)
    if current_build:
        for i, v in enumerate(versions):
            if v['build'] == current_build:
                current_idx = i
                break

    selected_idx = current_idx

    _draw_menu(versions, selected_idx, current_build)

    while True:
        key = msvcrt.getch()
        if key == b'\xe0':  # Arrow keys
            key = msvcrt.getch()
            if key == b'H':  # Up
                selected_idx = max(0, selected_idx - 1)
                _clear_lines(len(versions) + 2)
                _draw_menu(versions, selected_idx, current_build)
            elif key == b'P':  # Down
                selected_idx = min(len(versions) - 1, selected_idx)
                _clear_lines(len(versions) + 2)
                _draw_menu(versions, selected_idx, current_build)
        elif key == b'\r':  # Enter
            break
        elif key == b'\x03':  # Ctrl+C
            print("")
            return None

    selected_build = versions[selected_idx]['build']
    cfg['selected_build'] = selected_build
    config.save_config(cfg)

    print("")
    print(f"Selected: v{versions[selected_idx]['semver']} (build {selected_build})")
    return selected_build
