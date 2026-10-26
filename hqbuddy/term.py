"""Console capability setup: VT processing for ANSI escape sequences.

The interactive pickers (-build_sel / -set_device / -gen_hqip / -udev)
redraw in place via \\033[F\\033[K cursor sequences. Classic conhost does
not interpret them unless ENABLE_VIRTUAL_TERMINAL_PROCESSING is set, so on
Windows 10's legacy console every keypress would print the whole menu again
as literal garbage. Pickers call ansi_ok() before emitting the sequences and
degrade to append-redraw when VT is unavailable.
"""

import sys

_VT_ENABLED = False


def enable_vt_processing() -> bool:
    """Enable VT processing on the console; True when available.

    Silently returns False when stdout is redirected, on non-Windows, or on
    pre-1607 Windows without VT support."""
    global _VT_ENABLED
    if _VT_ENABLED:
        return True
    if sys.platform != "win32" or not sys.stdout.isatty():
        return False
    try:
        import ctypes
        kernel32 = ctypes.windll.kernel32
        handle = kernel32.GetStdHandle(-11)  # STD_OUTPUT_HANDLE
        mode = ctypes.c_uint32()
        if not kernel32.GetConsoleMode(handle, ctypes.byref(mode)):
            return False
        ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004
        if not kernel32.SetConsoleMode(
                handle, mode.value | ENABLE_VIRTUAL_TERMINAL_PROCESSING):
            return False
        _VT_ENABLED = True
        return True
    except Exception:
        return False


def ansi_ok() -> bool:
    """Whether ANSI cursor sequences can be used right now (enables VT on
    first use)."""
    if not sys.stdout.isatty():
        return False
    return _VT_ENABLED or enable_vt_processing()


def clear_lines(n: int) -> None:
    """Move cursor up n lines and clear them (no-op without VT support)."""
    if not ansi_ok():
        return
    for _ in range(n):
        sys.stdout.write('\033[F\033[K')
    sys.stdout.flush()


def interactive_pick(items: list, row_fn, match_fn, start_idx: int = 0) -> "int | None":
    """Shared arrow-key/search picker behind -build_sel/-set_device/-gen_hqip.

    items     full candidate list (never mutated)
    row_fn    item -> display text (the ' ▶' cursor is added here)
    match_fn  (item, NEEDLE) -> bool; NEEDLE is the uppercased search text
    start_idx initial selection index into items

    Returns the selected index into items, or None when cancelled
    (Esc / Ctrl+C).  Enter on an empty match list just redraws."""
    import msvcrt

    def draw(filtered, idx, search):
        lines = 1
        print(f"Type to search: {search}")
        total = len(filtered)
        start = max(0, idx - 10)
        end = min(total, start + 20)
        if end - start < 20 and start > 0:
            start = max(0, end - 20)
        for i in range(start, end):
            cursor = " \u25b6" if i == idx else "  "
            print(f"{cursor} {row_fn(items[filtered[i]])}")
            lines += 1
        if total > end:
            print(f"  ... and {total - end} more")
            lines += 1
        if total == 0:
            print("  (no matches)")
            lines += 1
        sys.stdout.flush()
        return lines

    def clamp_idx(filtered, idx):
        return max(0, min(idx, len(filtered) - 1)) if filtered else 0

    filtered = list(range(len(items)))
    search = ""
    idx = clamp_idx(filtered, start_idx)
    n = draw(filtered, idx, search)
    while True:
        key = msvcrt.getch()
        if key == b'\xe0':  # arrow keys
            key = msvcrt.getch()
            if key == b'H':  # Up
                idx = max(0, idx - 1)
            elif key == b'P':  # Down
                idx = clamp_idx(filtered, idx + 1)
            clear_lines(n)
            n = draw(filtered, idx, search)
        elif key == b'\r':  # Enter
            clear_lines(n)
            if 0 <= idx < len(filtered):
                return filtered[idx]
            n = draw(filtered, idx, search)
        elif key == b'\x08':  # Backspace
            if search:
                search = search[:-1]
                needle = search.upper()
                filtered = [j for j in range(len(items))
                            if match_fn(items[j], needle)]
                idx = clamp_idx(filtered, idx)
            clear_lines(n)
            n = draw(filtered, idx, search)
        elif key == b'\x1b':  # Esc
            clear_lines(n)
            return None
        elif key == b'\x03':  # Ctrl+C
            print("")
            return None
        else:
            try:
                ch = key.decode('utf-8')
                if ch.isprintable():
                    search += ch
                    needle = search.upper()
                    filtered = [j for j in range(len(items))
                                if match_fn(items[j], needle)]
                    idx = clamp_idx(filtered, idx)
                clear_lines(n)
                n = draw(filtered, idx, search)
            except UnicodeDecodeError:
                pass
