"""CLI entry point for hqbuddy."""

import glob
import json
import os
import subprocess
import sys


from . import __version__
from . import config, launcher, build_selector
from .hqprj_parser import extract_filelist
from .flow import run_flow
from .xpn import run_xpn
from .xpn2bin import run_xpn2bin
from .device import run_device
from .simlib import run_simlib


def show_help():
    """Print help message."""
    print("""Usage: hqbuddy [options]

Options:
  -h              Show this help message
  -v              Show version
  -build          Interactive HqFPGA version selection
  -install        Register .hqprj file association with hqbuddy

  -filelist [<.hqprj>] [-o <file>]
                  Extract FILE_SRC filelist from an .hqprj file
  -flow [<.hqprj>] [-o <file>]
                  Generate TCL script via hqprj2tcl
  -xpn [<.hqprj>] [-o <file>]
                  Generate XPN file from routed design (normal mode)
  -xpn -ins [<.hqprj>] [-o <file>]
                  Generate XPN file (hqinsight mode)
  -xpn2bin [<.xpn>] [-o <file>]
                  Convert XPN file to BIN bitstream
  -device [<.hqprj>]
                  Show device part used by the .hqprj project
  -device -set <part> [<.hqprj>]
                  Set device part for the .hqprj project
  -simlib [<dir>]
                  Compile XiST simulation library into ModelSim/QuestaSim

  -gui [<.hqprj>]
                  Launch HqFPGA GUI (hqui), optionally open a project
  -cmd <file>     Launch hqfpga CLI with a TCL script
  -dl [-f <file>]
                  Launch hqdnload downloader
  -cable [args]   Launch cable.exe, pass through all arguments

  -cfg [action]   Manage configuration
                  Actions: show, set-root <path>, remove-root <path>,
                           init, auto
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
        work_dir = os.path.dirname(os.path.abspath(hqprj_path))
        output_file = os.path.join(work_dir, "filelist.f")

    with open(output_file, "w", encoding="utf-8") as f:
        for path in files:
            f.write(path + "\n")
    print(f"Filelist saved to: {os.path.abspath(output_file)} ({len(files)} files)")


def cmd_flow(args):
    """Run hqprj2tcl flow via hqfpga."""
    hqprj_path, output_tcl = _parse_args_with_output(args)
    run_flow(hqprj_path, output_tcl)


def cmd_xpn(args):
    """Generate XPN file from routed design."""
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


def cmd_device(args):
    """Get or set device part for .hqprj."""
    if args and args[0] == '-set':
        if len(args) < 2:
            print("Error: -set requires a device part")
            sys.exit(1)
        part = args[1]
        remaining = args[2:]
        hqprj_path = _resolve_hqprj(remaining[0] if remaining else None)
        run_device(hqprj_path, part)
    else:
        hqprj_path = _resolve_hqprj(args[0] if args else None)
        run_device(hqprj_path, None)


def cmd_simlib(args):
    """Compile XiST simulation library."""
    hqfpga_root = None
    if args:
        hqfpga_root = args[0]
    run_simlib(hqfpga_root)


def cmd_build():
    """Interactive build selection."""
    build_selector.run_build_selector()


def cmd_gui(args):
    """Launch hqfpga GUI (hqui)."""
    version = launcher.resolve_hqfpga_version()
    if not version:
        print("Error: no HqFPGA versions found.")
        print("Tip: Use 'hqbuddy -cfg auto' to configure scan roots.")
        sys.exit(1)
    launcher.launch_tool(version, 'hqui', args)


def cmd_launch_cmd(args):
    """Launch hqfpga CLI with a TCL script."""
    if not args:
        print("Error: -cmd requires a TCL script file")
        sys.exit(1)
    version = launcher.resolve_hqfpga_version()
    if not version:
        print("Error: no HqFPGA versions found.")
        print("Tip: Use 'hqbuddy -cfg auto' to configure scan roots.")
        sys.exit(1)
    launcher.launch_tool(version, 'hqfpga', ['-cmd'] + args)


def cmd_dl(args):
    """Launch hqdnload downloader."""
    version = launcher.resolve_hqfpga_version()
    if not version:
        print("Error: no HqFPGA versions found.")
        print("Tip: Use 'hqbuddy -cfg auto' to configure scan roots.")
        sys.exit(1)

    # Build hqdnload args
    extra_args = []
    if args:
        extra_args = list(args)
    else:
        # Auto-detect latest .bin in current directory
        bin_files = [f for f in os.listdir('.') if f.lower().endswith('.bin')]
        if bin_files:
            bin_files.sort(key=lambda f: os.path.getmtime(f), reverse=True)
            latest_bin = bin_files[0]
            print(f"Auto-selected download file: {latest_bin}")
            extra_args = ['-f', latest_bin]

    launcher.launch_tool(version, 'hqdnload', extra_args)


def cmd_cable(args):
    """Launch cable.exe with passthrough arguments."""
    version = launcher.resolve_hqfpga_version()
    if not version:
        print("Error: no HqFPGA versions found.")
        print("Tip: Use 'hqbuddy -cfg auto' to configure scan roots.")
        sys.exit(1)
    launcher.launch_tool(version, 'cable', args)


def cmd_config(args):
    """Configuration management."""
    cfg = config.load_config()
    cfg_path = config.get_config_path()

    action = args[0] if args else 'show'
    value = args[1] if len(args) > 1 else None

    if action == 'show':
        print(f"Config file: {cfg_path}")
        print(json.dumps(cfg, indent=2, ensure_ascii=False))

    elif action == 'set-root':
        if not value:
            print("Usage: hqbuddy -cfg set-root <path>")
            sys.exit(1)
        path = os.path.abspath(value)
        if 'scan_roots' not in cfg:
            cfg['scan_roots'] = []
        if path not in cfg['scan_roots']:
            cfg['scan_roots'].append(path)
        config.save_config(cfg)
        print(f"Config file: {cfg_path}")
        print(f"Added scan root: {path}")

    elif action == 'remove-root':
        if not value:
            print("Usage: hqbuddy -cfg remove-root <path>")
            sys.exit(1)
        path = os.path.abspath(value)
        if 'scan_roots' in cfg:
            norm_roots = [os.path.normpath(os.path.normcase(r)) for r in cfg['scan_roots']]
            norm_path = os.path.normpath(os.path.normcase(path))
            if norm_path in norm_roots:
                idx = norm_roots.index(norm_path)
                cfg['scan_roots'].pop(idx)
                config.save_config(cfg)
                print(f"Config file: {cfg_path}")
                print(f"Removed scan root: {path}")
                return
        print(f"Config file: {cfg_path}")
        print(f"Root not found in config: {path}")

    elif action == 'init':
        config.save_config(config.DEFAULT_CONFIG)
        print(f"Config file: {cfg_path}")
        print("Configuration reset to defaults.")

    elif action == 'auto':
        # Scan all roots, auto-select latest as selected_build
        from .scanner import scan_all
        versions = scan_all(cfg)
        if not versions:
            print("No HqFPGA versions found. Please check scan roots.")
            sys.exit(1)
        latest = versions[0]
        cfg['selected_build'] = latest['build']
        config.save_config(cfg)
        print(f"Config file: {cfg_path}")
        print(f"Auto-configured: selected v{latest['semver']} (build {latest['build']})")

    else:
        print(f"Unknown config action: {action}")
        print("Valid actions: show, set-root, remove-root, init, auto")
        sys.exit(1)


def cmd_install():
    """Register .hqprj file association with hqbuddy."""
    import winreg

    exe_path = os.path.abspath(sys.argv[0])
    if not exe_path.lower().endswith('.exe'):
        print("Warning: hqbuddy is running as a script, not an .exe.")
        print("File association will work only after building with 'build.ps1 build'.")

    try:
        # Register under HKCU (no admin required)
        with winreg.CreateKey(winreg.HKEY_CURRENT_USER,
                              r'Software\Classes\.hqprj') as key:
            winreg.SetValue(key, '', winreg.REG_SZ, 'HqBuddy.hqprj')

        with winreg.CreateKey(winreg.HKEY_CURRENT_USER,
                              r'Software\Classes\HqBuddy.hqprj') as key:
            winreg.SetValue(key, '', winreg.REG_SZ, 'HqFPGA Project File')

        with winreg.CreateKey(winreg.HKEY_CURRENT_USER,
                              r'Software\Classes\HqBuddy.hqprj\shell\open\command') as key:
            winreg.SetValue(key, '', winreg.REG_SZ, f'"{exe_path}" "%1"')

        print(f"File association registered: .hqprj -> {exe_path}")
        print("Double-clicking a .hqprj file will open it with hqbuddy.")
    except Exception as e:
        print(f"Error: failed to register file association: {e}")
        sys.exit(1)


def main():
    """Main entry point."""
    args = sys.argv[1:]

    # No arguments: print HqFPGA root path
    if not args:
        root = launcher.resolve_hqfpga_root()
        if root:
            print(root)
        else:
            print("Error: no HqFPGA versions found.")
            print("Tip: Use 'hqbuddy -cfg auto' to configure scan roots.")
        return

    # Handle file association: first arg is a .hqprj file path
    first = args[0]
    if not first.startswith('-') and first.lower().endswith('.hqprj') and os.path.isfile(first):
        cmd_gui([first])
        return

    # Help
    if first == '-h':
        show_help()
        return

    # Version
    if first == '-v':
        show_version()
        return

    # Build selector
    if first == '-build':
        cmd_build()
        return

    # Install file association
    if first == '-install':
        cmd_install()
        return

    # Config management
    if first == '-cfg':
        cmd_config(args[1:])
        return

    # Filelist
    if first == '-filelist':
        cmd_filelist(args[1:])
        return

    # Flow
    if first == '-flow':
        cmd_flow(args[1:])
        return

    # XPN (normal and hqinsight modes)
    if first == '-xpn':
        cmd_xpn(args[1:])
        return

    # XPN to BIN
    if first == '-xpn2bin':
        cmd_xpn2bin(args[1:])
        return

    # Device
    if first == '-device':
        cmd_device(args[1:])
        return

    # Simlib
    if first == '-simlib':
        cmd_simlib(args[1:])
        return

    # GUI
    if first == '-gui':
        cmd_gui(args[1:])
        return

    # Cmd
    if first == '-cmd':
        cmd_launch_cmd(args[1:])
        return

    # Downloader
    if first == '-dl':
        cmd_dl(args[1:])
        return

    # Cable
    if first == '-cable':
        cmd_cable(args[1:])
        return

    print(f"Error: unknown option: {first}")
    show_help()
    sys.exit(1)


if __name__ == '__main__':
    main()
