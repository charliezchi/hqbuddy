"""Interactive build selection with keyboard navigation and search."""

import msvcrt
import sys

from . import config, scanner


def _clear_lines(n: int):
    """Move cursor up n lines and clear them."""
    for _ in range(n):
        sys.stdout.write('\033[F\033[K')
    sys.stdout.flush()


def _draw_menu(versions: list, selected_idx: int, current_build: str | None,
               search: str, show_latest: bool) -> int:
    """Draw the build selection menu. Returns number of lines printed."""
    lines = 0
    print(f"Type to search: {search}")
    lines += 1

    if show_latest:
        cursor = " \u25b6" if selected_idx == 0 else "  "
        marker = ">" if current_build is None else " "
        print(f"{cursor} {marker} [latest]  Auto-select newest version")
        lines += 1

    total = len(versions)
    ver_offset = 1 if show_latest else 0
    start = max(0, selected_idx - ver_offset - 10)
    end = min(total, start + 20)
    if end - start < 20 and start > 0:
        start = max(0, end - 20)

    for i in range(start, end):
        ver_sel = (selected_idx - ver_offset) == i
        cursor = " \u25b6" if ver_sel else "  "
        marker = ">" if versions[i]['build'] == current_build else " "
        print(f"{cursor} {marker} v{versions[i]['semver']}  (build {versions[i]['build']})")
        lines += 1

    if total > end:
        print(f"  ... and {total - end} more")
        lines += 1
    if total == 0 and not show_latest:
        print("  (no matches)")
        lines += 1

    sys.stdout.flush()
    return lines


def run_build_selector() -> str | None:
    """
    Run interactive build selection with search.

    Returns:
        Selected build string, None for latest, or None if cancelled.
    """
    cfg = config.load_config()
    all_versions = scanner.scan_all(cfg)
    if not all_versions:
        print("No HqFPGA versions found.")
        print("Tip: Use 'hqbuddy -cfg auto' or 'hqbuddy -cfg set-root' to configure.")
        return None

    current_build = cfg.get("selected_build")
    filtered = list(all_versions)
    search = ""
    show_latest = True
    selected_idx = 0 if current_build is None else 1

    lines_printed = _draw_menu(filtered, selected_idx, current_build, search, show_latest)

    while True:
        key = msvcrt.getch()

        if key == b'\xe0':  # Arrow keys
            key = msvcrt.getch()
            total_items = len(filtered) + (1 if show_latest else 0)
            if key == b'H':  # Up
                selected_idx = max(0, selected_idx - 1)
            elif key == b'P':  # Down
                selected_idx = min(total_items - 1, selected_idx + 1)
            _clear_lines(lines_printed)
            lines_printed = _draw_menu(filtered, selected_idx, current_build, search, show_latest)

        elif key == b'\r':  # Enter
            _clear_lines(lines_printed)
            if show_latest and selected_idx == 0:
                cfg['selected_build'] = None
                config.save_config(cfg)
                print("Selected: latest version (auto)")
                return None
            else:
                ver_idx = selected_idx - (1 if show_latest else 0)
                if 0 <= ver_idx < len(filtered):
                    b = filtered[ver_idx]
                    cfg['selected_build'] = b['build']
                    config.save_config(cfg)
                    print(f"Selected: v{b['semver']} (build {b['build']})")
                    return b['build']

        elif key == b'\x08':  # Backspace
            if search:
                search = search[:-1]
                filtered = [v for v in all_versions
                           if search.upper() in v['build'].upper()
                           or search.upper() in v['semver'].upper()]
                show_latest = len(filtered) > 0
                selected_idx = min(selected_idx, len(filtered) + (1 if show_latest else 0) - 1)
                if selected_idx < 0:
                    selected_idx = 0
            _clear_lines(lines_printed)
            lines_printed = _draw_menu(filtered, selected_idx, current_build, search, show_latest)

        elif key == b'\x1b':  # Esc
            _clear_lines(lines_printed)
            return None

        elif key == b'\x03':  # Ctrl+C
            print("")
            return None

        else:  # Regular character (for search)
            try:
                ch = key.decode('utf-8')
                if ch.isprintable():
                    search += ch
                    filtered = [v for v in all_versions
                               if search.upper() in v['build'].upper()
                               or search.upper() in v['semver'].upper()]
                    show_latest = len(filtered) > 0
                    selected_idx = min(selected_idx, len(filtered) + (1 if show_latest else 0) - 1)
                    if selected_idx < 0:
                        selected_idx = 0
                _clear_lines(lines_printed)
                lines_printed = _draw_menu(filtered, selected_idx, current_build, search, show_latest)
            except UnicodeDecodeError:
                pass
