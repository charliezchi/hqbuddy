"""CLI entry point for hqbuddy."""

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
  -filelist <file>
                  Extract FILE_SRC filelist from an .hqprj file
                  The $WORK_DIR$ placeholder is resolved to the .hqprj directory
                  Output is saved to filelist.f in the same directory as the .hqprj
                  Use -o to specify a custom output path
  -flow <file>    Run hqprj2tcl flow via hqlauncher
                  Generates run_hqprj.tcl in the .hqprj directory by default
                  Use -o to specify a custom output TCL file

Examples:
  hqbuddy -v
  hqbuddy -filelist example/ddrc_native_demo.hqprj
  hqbuddy -filelist example/ddrc_native_demo.hqprj -o custom.f
  hqbuddy -flow example/ddrc_native_demo.hqprj
  hqbuddy -flow example/ddrc_native_demo.hqprj -o my_output.tcl
""")


def show_version():
    """Print version."""
    print(__version__)


def cmd_filelist(args):
    """Extract and save FILE_SRC filelist."""
    if not args:
        print("Error: -filelist requires an .hqprj file path")
        sys.exit(1)

    hqprj_path = args[0]
    if not os.path.isfile(hqprj_path):
        print(f"Error: file not found: {hqprj_path}")
        sys.exit(1)

    files = extract_filelist(hqprj_path)

    # Check for -o output option
    output_file = None
    if len(args) >= 3 and args[1] == '-o':
        output_file = args[2]
    elif len(args) >= 2 and args[1].startswith('-o'):
        # Handle -o<file> without space
        output_file = args[1][2:]

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
    if not args:
        print("Error: -flow requires an .hqprj file path")
        sys.exit(1)

    hqprj_path = args[0]

    # Check for -o output option
    output_tcl = None
    if len(args) >= 3 and args[1] == '-o':
        output_tcl = args[2]
    elif len(args) >= 2 and args[1].startswith('-o'):
        # Handle -o<file> without space
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
