"""CLI entry point for hqbuddy."""

import glob
import os
import sys

from . import __version__
from .hqprj_parser import extract_filelist
from .flow import run_flow
from .xpn import run_xpn
from .xpn2bin import run_xpn2bin


def show_help():
    """Print help message."""
    print("""Usage: hqbuddy [options]

Options:
  -h              Show this help message
  -v              Show version
  -filelist [<file>] [-o <file>]
                  Extract FILE_SRC filelist from an .hqprj file
                  If <file> is omitted, auto-detects the first .hqprj in current directory
                  The $WORK_DIR$ placeholder is resolved to the .hqprj directory
                  Default output: filelist.f in the .hqprj directory
                  Use -o to specify a custom output file (e.g. custom.f)
  -flow [<file>] [-o <file>]
                  Run hqprj2tcl flow via hqlauncher
                  If <file> is omitted, auto-detects the first .hqprj in current directory
                  Default output: run_hqprj.tcl in the .hqprj directory
                  Use -o to specify a custom output file (e.g. my_output.tcl)
  -xpn [<file>] [-o <file>]
                  Generate XPN file from routed design (normal mode)
                  If <file> is omitted, auto-detects the first .hqprj in current directory
                  Default output: hq.xpn in the .hqprj directory
                  Use -o to specify a custom output file (e.g. my_design.xpn)
  -xpn -ins [<file>] [-o <file>]
                  Generate XPN file from routed design (hqinsight mode)
                  If <file> is omitted, auto-detects the first .hqprj in current directory
                  Default output: hq_ins.xpn in the .hqprj directory
                  Use -o to specify a custom output file (e.g. my_ins_design.xpn)
  -xpn2bin [<file>] [-o <file>]
                  Convert XPN file to BIN file via hqlauncher
                  If <file> is omitted, auto-detects the first .xpn in current directory
                  Default output: <input>.bin in the same directory as the .xpn
                  Use -o to specify a custom output file (e.g. my_output.bin)

Examples:
  hqbuddy -v
  hqbuddy -filelist
  hqbuddy -filelist example/ddrc_native_demo.hqprj
  hqbuddy -filelist example/ddrc_native_demo.hqprj -o custom.f
  hqbuddy -flow
  hqbuddy -flow example/ddrc_native_demo.hqprj
  hqbuddy -flow example/ddrc_native_demo.hqprj -o my_output.tcl
  hqbuddy -xpn
  hqbuddy -xpn example/ddrc_native_demo.hqprj
  hqbuddy -xpn -o my_design.xpn
  hqbuddy -xpn -ins
  hqbuddy -xpn -ins example/ddrc_native_demo.hqprj
  hqbuddy -xpn -ins -o my_ins_design.xpn
  hqbuddy -xpn2bin
  hqbuddy -xpn2bin debug.xpn
  hqbuddy -xpn2bin -o my_output.bin
  hqbuddy -xpn2bin debug.xpn -o my_output.bin
""")


def show_version():
    """Print version."""
    print(__version__)


def _find_hqprj() -> str | None:
    """Auto-detect the first .hqprj file in the current directory."""
    matches = glob.glob("*.hqprj")
    return matches[0] if matches else None


def _find_xpn() -> str | None:
    """Auto-detect the first .xpn file in the current directory."""
    matches = glob.glob("*.xpn")
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


def _parse_args_with_output(args: list[str]) -> tuple[str | None, str | None]:
    """
    Parse args to extract hqprj path and -o output option.

    Returns:
        Tuple of (hqprj_path, output_name). Either may be None.
    """
    output_name = None
    hqprj_path = None

    if not args:
        hqprj_path = _resolve_hqprj(None)
    elif args[0] == '-o':
        if len(args) < 2:
            print("Error: -o requires an output name")
            sys.exit(1)
        output_name = args[1]
        hqprj_path = _resolve_hqprj(None)
    elif args[0].startswith('-o'):
        output_name = args[0][2:]
        hqprj_path = _resolve_hqprj(None)
    else:
        hqprj_path = args[0]
        if len(args) >= 3 and args[1] == '-o':
            output_name = args[2]
        elif len(args) >= 2 and args[1].startswith('-o'):
            output_name = args[1][2:]

    return hqprj_path, output_name


def cmd_filelist(args):
    """Extract and save FILE_SRC filelist."""
    hqprj_path, output_file = _parse_args_with_output(args)

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
    hqprj_path, output_tcl = _parse_args_with_output(args)
    run_flow(hqprj_path, output_tcl)


def cmd_xpn(args):
    """Generate XPN file from routed design."""
    # Check for -ins flag first
    hqinsight = False
    if args and args[0] == '-ins':
        hqinsight = True
        args = args[1:]

    hqprj_path, output_name = _parse_args_with_output(args)
    run_xpn(hqprj_path, output_name, hqinsight)


def cmd_xpn2bin(args):
    """Convert XPN file to BIN file."""
    xpn_path = None
    bin_path = None

    if not args:
        detected = _find_xpn()
        if not detected:
            print("Error: no .xpn file specified and none found in current directory.")
            sys.exit(1)
        xpn_path = detected
    elif args[0] == '-o':
        if len(args) < 2:
            print("Error: -o requires an output name")
            sys.exit(1)
        bin_path = args[1]
        detected = _find_xpn()
        if not detected:
            print("Error: no .xpn file specified and none found in current directory.")
            sys.exit(1)
        xpn_path = detected
    elif args[0].startswith('-o'):
        bin_path = args[0][2:]
        detected = _find_xpn()
        if not detected:
            print("Error: no .xpn file specified and none found in current directory.")
            sys.exit(1)
        xpn_path = detected
    else:
        xpn_path = args[0]
        if len(args) >= 3 and args[1] == '-o':
            bin_path = args[2]
        elif len(args) >= 2 and args[1].startswith('-o'):
            bin_path = args[1][2:]

    run_xpn2bin(xpn_path, bin_path)


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

    # XPN (normal and hqinsight modes)
    if args[0] == '-xpn':
        cmd_xpn(args[1:])
        return

    # XPN to BIN
    if args[0] == '-xpn2bin':
        cmd_xpn2bin(args[1:])
        return

    print(f"Error: unknown option: {args[0]}")
    show_help()
    sys.exit(1)


if __name__ == '__main__':
    main()
