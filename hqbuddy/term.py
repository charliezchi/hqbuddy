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
