"""CLI entry point for hqbuddy."""

import glob
import os
import sys

from . import __version__
from .hqprj_parser import extract_filelist
from .flow import run_flow


def show_help():
    """Print help message."""
    print("""Usage: hqbuddy [options]

Options:
  -h              Show this help message
  -v              Show version
  -filelist [<file>]
                  Extract FILE_SRC filelist from an .hqprj file
                  If <file> is omitted, auto-detects the first .hqprj in current directory
                  The $WORK_DIR$ placeholder is resolved to the .hqprj directory
                  Output is saved to filelist.f in the same directory as the .hqprj
                  Use -o to specify a custom output path
  -flow [<file>]
                  Run hqprj2tcl flow via hqlauncher
                  If <file> is omitted, auto-detects the first .hqprj in current directory
                  Generates run_hqprj.tcl in the .hqprj directory by default
                  Use -o to specify a custom output TCL file

Examples:
  hqbuddy -v
  hqbuddy -filelist
  hqbuddy -filelist example/ddrc_native_demo.hqprj
  hqbuddy -filelist example/ddrc_native_demo.hqprj -o custom.f
  hqbuddy -flow
  hqbuddy -flow example/ddrc_native_demo.hqprj
  hqbuddy -flow example/ddrc_native_demo.hqprj -o my_output.tcl
""")


def show_version():
    """Print version."""
    print(__version__)


def _find_hqprj() -> str | None:
    """Auto-detect the first .hqprj file in the current directory."""
    matches = glob.glob("*.hqprj")
    return matches[0] if matches else None


def _resolve_hqprj(arg: str | None) -> str:
    """Resolve .hqprj path from argument or auto-detect."""
    if arg:
        return arg

    detected = _find_hqprj()
    if detected:
        return detected

    print("Error: no .hqprj file specified and none found in current directory.")
    sys.exit(1)


def cmd_filelist(args):
    """Extract and save FILE_SRC filelist."""
    # Check for -o output option before resolving hqprj
    output_file = None
    hqprj_path = None

    if not args:
        hqprj_path = _resolve_hqprj(None)
    elif args[0] == '-o':
        if len(args) < 2:
            print("Error: -o requires an output file path")
            sys.exit(1)
        output_file = args[1]
        hqprj_path = _resolve_hqprj(None)
    elif args[0].startswith('-o'):
        output_file = args[0][2:]
        hqprj_path = _resolve_hqprj(None)
    else:
        hqprj_path = args[0]
        if len(args) >= 3 and args[1] == '-o':
            output_file = args[2]
        elif len(args) >= 2 and args[1].startswith('-o'):
            output_file = args[1][2:]

    if not os.path.isfile(hqprj_path):
        print(f"Error: file not found: {hqprj_path}")
        sys.exit(1)

    files = extract_filelist(hqprj_path)

    if not output_file:
        # Default: filelist.f in the same directory as the .hqprj
        work_dir = os.path.dirname(os.path.abspath(hqprj_path))
        output_file = os.path.join(work_dir, "filelist.f")

    with open(output_file, "w", encoding="utf-8") as f:
        for path in files:
            f.write(path + "\n")
    print(f"Filelist saved to: {os.path.abspath(output_file)} ({len(files)} files)")


def cmd_flow(args):
    """Run hqprj2tcl flow via hqlauncher."""
    # Check for -o output option before resolving hqprj
    output_tcl = None
    hqprj_path = None

    if not args:
        hqprj_path = _resolve_hqprj(None)
    elif args[0] == '-o':
        if len(args) < 2:
            print("Error: -o requires an output file path")
            sys.exit(1)
        output_tcl = args[1]
        hqprj_path = _resolve_hqprj(None)
    elif args[0].startswith('-o'):
        output_tcl = args[0][2:]
        hqprj_path = _resolve_hqprj(None)
    else:
        hqprj_path = args[0]
        if len(args) >= 3 and args[1] == '-o':
            output_tcl = args[2]
        elif len(args) >= 2 and args[1].startswith('-o'):
            output_tcl = args[1][2:]

    run_flow(hqprj_path, output_tcl)


def main():
    """Main entry point."""
    args = sys.argv[1:]

    if not args:
        show_help()
        return

    # Help
    if args[0] == '-h':
        show_help()
        return

    # Version
    if args[0] == '-v':
        show_version()
        return

    # Filelist
    if args[0] == '-filelist':
        cmd_filelist(args[1:])
        return

    # Flow
    if args[0] == '-flow':
        cmd_flow(args[1:])
        return

    print(f"Error: unknown option: {args[0]}")
    show_help()
    sys.exit(1)


if __name__ == '__main__':
    main()
