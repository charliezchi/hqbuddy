"""CLI entry point for hqbuddy."""

import fnmatch
import glob
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time


from . import __version__
from . import config, launcher, build_selector
from .hqprj_parser import extract_filelist
from .flow import run_flow, run_flow_bin_only, run_flow_looptdo
from .xpn import run_xpn
from .xpn2bin import run_xpn2bin
from .device import run_device
from .ipgen import run_ipgen
from .ipmgr import list_ip_files
from .simlib import run_simlib
from .insight import run_insight
from .encrypt import run_encrypt
from .hqip_gen import run_gen_hqip


def show_help():
    """Print help message."""
    print("""Usage: hqbuddy [options]

Global:
  -h                      Show this help message
  -v                      Show version
  -root                   Print HqFPGA root directory path
  -build_sel              Interactive HqFPGA version selection
  -cfg [action]           Manage configuration (show/set-root/remove-root/init/auto)

Project:
  -filelist [<.hqprj>] [-o <file>]     Extract FILE_SRC filelist
  -flow [<.hqprj>] [-o <file>]         Generate TCL via hqprj2tcl
    -looptdo                            Looptdo mode (synthesis + looptdo)
    -bin_only [<name>]                  Bin-only mode (synthesis -> bitgen, no intermediate files)
  -xpn [<.hqprj>] [-o <file>]          Generate XPN (normal mode)
    -ins                                Generate XPN (hqinsight mode)
  -xpn2bin [<.xpn>] [-o <file>]        Convert XPN to BIN
  -device [<.hqprj>]                   Show device part
    -set [<part>] [<.hqprj>]           Set device part (interactive if no part)
  -new_prj <name> [-device <part>]     Create .hqprj project from template
  -add <file1> [<file2> ...]           Add source/constraint files to project
  -set_top <name>                      Set top module name
  -clean [-force]                       Clean files/dirs listed in configs/clean_list.json

Tools:
  -ipgen [<.hqip>] [-lang <lang>]       Generate IP netlist via ipgen
  -gen_hqip [<meta.xml>] [-device <part>]  Generate default .hqip (interactive IP picker if omitted)
  -update_ip [<.hqprj>]                 Regenerate all IP netlists for project
  -encrypt [<files...>] [-d dir] [-m m] [-po]  Encrypt HDL sources (.v/.vh/.f, default: all .v in cwd)
  -simlib [<dir>]                       Compile XiST simulation library
  -cmd [<file>]                         Launch hqfpga CLI (with TCL script, or interactive if omitted)
  -cmd -e "<tcl>" [-q]                  Execute a single TCL command string
                                        (-q: hide banner and Info: lines)
  -dl [-f <file>]                       Launch hqdnload downloader
  -cable [args...]                      Launch cable.exe

Debug:
  -insight [<.hqprj>]                   HqInsight online logic analyzer (status)
  -insight -trig [<expr>]               Set trigger condition (wizard if omitted)
                                        e.g. "sig EQ 5", "sig RANGE 1 10", "sig RISE",
                                        "a GT 0 AND b FALL", NOT <cond>, --negate
  -insight -capture [-force] [-timeout N]
                                        Arm trigger and capture waveform to VCD
                                        (-force: capture immediately; default timeout 60s)
  -insight -run                         Run the instrumented implementation flow
  -insight -init                        Init HqInsight project (no GUI needed)
  -insight -ls [keyword]                List design signals (* = already selected)
  -insight -add <sig> [-clk c] [-type sample|trigger|both] [-module m]
                                        Add a signal to the HqInsight project
  -insight -del <sig>                   Remove a signal from the HqInsight project
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
    # Scan for mode flags (recognized anywhere after -flow)
    looptdo = False
    bin_only_mode = False
    bin_only_name = None
    filtered = []
    i = 0
    while i < len(args):
        if args[i] == '-looptdo':
            looptdo = True
            i += 1
        elif args[i] == '-bin_only':
            bin_only_mode = True
            # Optional bin name: only consume if next arg does not look like a flag
            if i + 1 < len(args) and not args[i + 1].startswith('-'):
                bin_only_name = args[i + 1]
                i += 2
            else:
                i += 1
        else:
            filtered.append(args[i])
            i += 1

    if looptdo and bin_only_mode:
        print("Error: -looptdo and -bin_only cannot be used together")
        sys.exit(1)

    hqprj_path, output_tcl = _parse_args_with_output(filtered)

    if looptdo:
        run_flow_looptdo(hqprj_path, output_tcl)
    elif bin_only_mode:
        run_flow_bin_only(hqprj_path, bin_only_name, output_tcl)
    else:
        run_flow(hqprj_path, output_tcl)


def _get_resource_path(relative_path):
    """Locate a bundled resource file relative to the hqbuddy package root."""
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    return os.path.join(base, relative_path)


def _remove_empty_dirs(root: str) -> int:
    """Recursively remove empty directories under root; return count deleted."""
    deleted = 0
    for dirpath, dirnames, filenames in os.walk(root, topdown=False):
        # Do not remove the project root itself
        if os.path.samefile(dirpath, root):
            continue
        try:
            if not os.listdir(dirpath):
                os.rmdir(dirpath)
                print(f"  [EMPTY DIR] {os.path.relpath(dirpath, root)}")
                deleted += 1
        except Exception as e:
            print(f"  [FAIL] {os.path.relpath(dirpath, root)}: {e}")
    return deleted


def cmd_clean(force: bool = False):
    """Clean current directory using configs/clean_list.json."""
    cwd = os.getcwd()

    # Check if .hqprj exists
    hqprj_files = glob.glob(os.path.join(cwd, "*.hqprj"))
    if not hqprj_files:
        print(f"Error: no .hqprj file found in {cwd}")
        print("Tip: -clean only works in a project directory with .hqprj files.")
        sys.exit(1)

    # Load clean list
    clean_list_path = _get_resource_path(os.path.join("configs", "clean_list.json"))
    try:
        with open(clean_list_path, "r", encoding="utf-8") as f:
            clean_list = json.load(f)
    except Exception as e:
        print(f"Error: cannot load clean list from {clean_list_path}: {e}")
        sys.exit(1)

    dirs_to_clean = clean_list.get("dir", [])
    file_patterns = clean_list.get("file", [])

    to_delete = []

    # Match directories
    for entry in sorted(os.listdir(cwd)):
        full_path = os.path.join(cwd, entry)
        if os.path.isdir(full_path) and entry in dirs_to_clean:
            to_delete.append(entry)

    # Match files by pattern (fnmatch includes hidden dotfiles)
    for pattern in file_patterns:
        for entry in os.listdir(cwd):
            if fnmatch.fnmatch(entry, pattern):
                full_path = os.path.join(cwd, entry)
                if os.path.isfile(full_path) and entry not in to_delete:
                    to_delete.append(entry)

    if not to_delete:
        print("Nothing to clean — no matching files or directories found.")
        # Still remove empty directories even if no listed items match
        empty_deleted = _remove_empty_dirs(cwd)
        if empty_deleted:
            print(f"Deleted {empty_deleted} empty directory/directories.")
        return

    print(f"The following will be deleted from {cwd}:")
    for entry in to_delete:
        full_path = os.path.join(cwd, entry)
        if os.path.isdir(full_path):
            print(f"  [DIR]  {entry}")
        else:
            print(f"  [FILE] {entry}")

    if not force:
        try:
            confirm = input(f"\nDelete {len(to_delete)} item(s)? (y/N): ").strip().lower()
        except (EOFError, KeyboardInterrupt):
            print("")
            print("Cancelled.")
            return

        if confirm != 'y':
            print("Cancelled.")
            return

    deleted = 0
    for entry in to_delete:
        full_path = os.path.join(cwd, entry)
        try:
            if os.path.isdir(full_path):
                shutil.rmtree(full_path)
            else:
                os.remove(full_path)
            deleted += 1
        except Exception as e:
            print(f"  [FAIL] {entry}: {e}")

    print(f"Deleted {deleted}/{len(to_delete)} item(s).")

    # Remove any empty directories left behind
    empty_deleted = _remove_empty_dirs(cwd)
    if empty_deleted:
        print(f"Deleted {empty_deleted} empty directory/directories.")


def cmd_update_ip(args):
    """Regenerate IP netlists for all .hqip files referenced by the project."""
    hqprj_path = _resolve_hqprj(args[0] if args else None)

    if not os.path.isfile(hqprj_path):
        print(f"Error: file not found: {hqprj_path}")
        sys.exit(1)

    ip_files = list_ip_files(hqprj_path)
    if not ip_files:
        print("No .hqip files referenced by this project.")
        return

    print(f"Updating {len(ip_files)} IP file(s) for: {os.path.abspath(hqprj_path)}")
    print("")
    sys.stdout.flush()

    failed = 0
    for i, hqip_path in enumerate(ip_files, 1):
        print(f"[{i}/{len(ip_files)}] {os.path.abspath(hqip_path)}")
        sys.stdout.flush()
        try:
            run_ipgen(hqip_path)
        except SystemExit as e:
            # run_ipgen exits on fatal errors; count it and continue
            if e.code != 0:
                failed += 1
        except Exception as e:
            print(f"  [FAIL] {e}")
            failed += 1
        print("")
        sys.stdout.flush()

    print(f"Done. {len(ip_files) - failed}/{len(ip_files)} IP file(s) updated successfully.")
    if failed:
        sys.exit(1)


def cmd_new_prj(args):
    """Create a new .hqprj project from template."""
    if not args:
        print("Error: -new_prj requires a project name")
        print("Usage: hqbuddy -new_prj <name> [-device <part>]")
        sys.exit(1)

    name = args[0]
    if name.startswith('-'):
        print("Error: project name cannot start with '-'")
        sys.exit(1)
    if name.lower().endswith('.hqprj'):
        name = name[:-6]

    # Check for -device option
    device = None
    i = 1
    while i < len(args):
        if args[i] == '-device' and i + 1 < len(args):
            device = args[i + 1]
            i += 2
        else:
            i += 1

    # If no device specified, launch interactive picker
    if not device:
        from .device import pick_device_interactive
        device = pick_device_interactive()
        if not device:
            return

    # Validate and parse device part
    from .device import _DEVICE_PART_RE, get_family_for_device
    from .device import set_device as validate_device
    match = _DEVICE_PART_RE.match(device)
    if not match:
        print(f"Error: invalid device part: {device}")
        print("Format: DIE-SPEEDPACKAGE-CONDITION (e.g. SA5T-100-D0-7H676CI)")
        sys.exit(1)

    die = match.group("die")
    speed = match.group("speed")
    package = match.group("package")
    condition = match.group("condition")

    # Look up family from dv_list.xml
    family = get_family_for_device(device)
    if not family:
        print(f"Error: device not found: {device}")
        print("Please use a valid device from 'hqbuddy -device -set'")
        sys.exit(1)

    # Read template
    template_path = _get_resource_path(os.path.join("templates", "project.hqprj"))
    try:
        with open(template_path, "r", encoding="utf-8") as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: template not found: {template_path}")
        sys.exit(1)

    # Replace fields
    content = content.replace("PROJ_NAME=hqfpga_project", f"PROJ_NAME={name}")
    content = content.replace("FAMILY=SEAL", f"FAMILY={family}")
    content = content.replace("DIE=SA5Z-30-D0", f"DIE={die}")
    content = content.replace("PACKAGES=U324", f"PACKAGES={package}")
    content = content.replace("SPEEDS=8", f"SPEEDS={speed}")
    content = content.replace("CONDITION=C", f"CONDITION={condition}")

    # Write file
    output = os.path.join(os.getcwd(), f"{name}.hqprj")
    if os.path.exists(output):
        try:
            confirm = input(f"Overwrite {output}? (y/N): ").strip().lower()
            if confirm != 'y':
                print("Cancelled.")
                return
        except (EOFError, KeyboardInterrupt):
            print("")
            print("Cancelled.")
            return

    with open(output, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Project created: {output} (device: {device})")


def cmd_add(args):
    """Add source/constraint files to the .hqprj project."""
    if not args:
        print("Error: -add requires at least one file")
        print("Usage: hqbuddy -add <file1> [<file2> ...]")
        print("  .v / .vh / .f  → add to FILE_SRC")
        print("  .sdc           → set FILE_TC")
        print("  .upc           → set FILE_PC")
        sys.exit(1)

    hqprj_path = _find_hqprj()
    if not hqprj_path:
        print("Error: no .hqprj file found in current directory.")
        sys.exit(1)
    hqprj_abs = os.path.abspath(hqprj_path)

    added_src = []
    added_tc = None
    added_pc = None

    # Read existing file
    with open(hqprj_abs, "r", encoding="utf-8") as f:
        lines = f.readlines()

    existing_src = set()
    existing_tc = None
    existing_pc = None
    tc_line_idx = -1
    pc_line_idx = -1
    src_none_idx = -1
    tc_none_idx = -1
    pc_none_idx = -1
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("FILE_SRC="):
            existing_src.add(stripped)
            if stripped == "FILE_SRC=NONE":
                src_none_idx = i
        elif stripped.startswith("FILE_TC="):
            existing_tc = stripped
            tc_line_idx = i
            if stripped == "FILE_TC=NONE":
                tc_none_idx = i
        elif stripped.startswith("FILE_PC="):
            existing_pc = stripped
            pc_line_idx = i
            if stripped == "FILE_PC=NONE":
                pc_none_idx = i

    now = str(int(time.time()))
    ft_lines = []

    def add_src(entry):
        nonlocal src_none_idx
        if entry in existing_src:
            return False
        if src_none_idx >= 0:
            lines[src_none_idx] = entry + "\n"
            existing_src.discard("FILE_SRC=NONE")
            existing_src.add(entry)
            src_none_idx = -1
            return True
        lines.append(entry + "\n")
        existing_src.add(entry)
        return True

    def set_tc(entry):
        nonlocal tc_line_idx, existing_tc, tc_none_idx
        if existing_tc == entry:
            return False
        if tc_none_idx >= 0:
            lines[tc_none_idx] = entry + "\n"
            existing_tc = entry
            tc_none_idx = -1
            return True
        if tc_line_idx >= 0:
            lines[tc_line_idx] = entry + "\n"
        else:
            lines.append(entry + "\n")
        existing_tc = entry
        return True

    def set_pc(entry):
        nonlocal pc_line_idx, existing_pc, pc_none_idx
        if existing_pc == entry:
            return False
        if pc_none_idx >= 0:
            lines[pc_none_idx] = entry + "\n"
            existing_pc = entry
            pc_none_idx = -1
            return True
        if pc_line_idx >= 0:
            lines[pc_line_idx] = entry + "\n"
        else:
            lines.append(entry + "\n")
        existing_pc = entry
        return True

    supported_src = ('.v', '.vh')
    errors = []

    # Process each file argument
    for file_arg in args:
        ext = os.path.splitext(file_arg)[1].lower()

        if ext == '.f':
            # Filelist: read and expand
            flist_path = os.path.abspath(file_arg) if os.path.isabs(file_arg) else os.path.abspath(file_arg)
            if not os.path.isfile(flist_path):
                errors.append(f"filelist not found: {file_arg}")
                continue
            flist_dir = os.path.dirname(flist_path)
            try:
                with open(flist_path, "r", encoding="utf-8") as f:
                    flines = f.readlines()
            except Exception as e:
                errors.append(f"cannot read filelist {file_arg}: {e}")
                continue
            for fline in flines:
                fpath = fline.strip()
                if not fpath or fpath.startswith('#'):
                    continue
                fext = os.path.splitext(fpath)[1].lower()
                if fext not in supported_src:
                    errors.append(f"unsupported suffix in filelist: {fpath}")
                    continue
                # Resolve relative to filelist directory
                resolved = fpath if os.path.isabs(fpath) else os.path.normpath(os.path.join(flist_dir, fpath))
                if not os.path.isfile(resolved):
                    errors.append(f"file not found: {fpath}")
                    continue
                rel = os.path.relpath(resolved, os.getcwd()).replace("\\", "/")
                entry = f"FILE_SRC=$WORK_DIR${rel}"
                if add_src(entry):
                    added_src.append(rel)
        elif ext in supported_src:
            src_path = os.path.abspath(file_arg) if os.path.isabs(file_arg) else os.path.abspath(file_arg)
            if not os.path.isfile(src_path):
                errors.append(f"file not found: {file_arg}")
                continue
            rel = os.path.relpath(src_path, os.getcwd()).replace("\\", "/")
            entry = f"FILE_SRC=$WORK_DIR${rel}"
            if add_src(entry):
                added_src.append(rel)
        elif ext == '.sdc':
            sdc_path = os.path.abspath(file_arg) if os.path.isabs(file_arg) else os.path.abspath(file_arg)
            if not os.path.isfile(sdc_path):
                errors.append(f"file not found: {file_arg}")
                continue
            rel = os.path.relpath(sdc_path, os.getcwd()).replace("\\", "/")
            if set_tc(f"FILE_TC=$WORK_DIR${rel}"):
                added_tc = rel
        elif ext == '.upc':
            upc_path = os.path.abspath(file_arg) if os.path.isabs(file_arg) else os.path.abspath(file_arg)
            if not os.path.isfile(upc_path):
                errors.append(f"file not found: {file_arg}")
                continue
            rel = os.path.relpath(upc_path, os.getcwd()).replace("\\", "/")
            if set_pc(f"FILE_PC=$WORK_DIR${rel}"):
                added_pc = rel
        else:
            errors.append(f"unsupported file type: {file_arg}")

    # Append FILE_TIME lines (after all FILE_SRC) and FILE_TIME_CST lines (at bottom)
    for _ in added_src:
        lines.append(f"FILE_TIME={now}\n")
    if added_tc:
        lines.append(f"FILE_TIME_CST={now}\n")
    if added_pc:
        lines.append(f"FILE_TIME_CST={now}\n")

    # Write back
    with open(hqprj_abs, "w", encoding="utf-8") as f:
        f.writelines(lines)

    # Report
    for f in added_src:
        print(f"  [ADD] FILE_SRC: {f}")
    if added_tc:
        print(f"  [ADD] FILE_TC: {added_tc}")
    if added_pc:
        print(f"  [ADD] FILE_PC: {added_pc}")
    for e in errors:
        print(f"  [WARN] {e}")
    if not added_src and not added_tc and not added_pc and not errors:
        print("Nothing to add.")
    elif added_src or added_tc or added_pc:
        print(f"Updated: {hqprj_abs}")


def cmd_set_top(args):
    """Set TOP_MODULE in the .hqprj project."""
    if not args:
        print("Error: -set_top requires a module name")
        sys.exit(1)
    top = args[0]
    if top.startswith('-'):
        print("Error: module name cannot start with '-'")
        sys.exit(1)

    hqprj_path = _find_hqprj()
    if not hqprj_path:
        print("Error: no .hqprj file found in current directory.")
        sys.exit(1)
    hqprj_abs = os.path.abspath(hqprj_path)

    with open(hqprj_abs, "r", encoding="utf-8") as f:
        lines = f.readlines()

    found = False
    for i, line in enumerate(lines):
        if line.strip().startswith("TOP_MODULE="):
            lines[i] = f"TOP_MODULE={top}\n"
            found = True
            break
    if not found:
        lines.append(f"TOP_MODULE={top}\n")

    with open(hqprj_abs, "w", encoding="utf-8") as f:
        f.writelines(lines)
    print(f"  [SET] TOP_MODULE={top}")
    print(f"Updated: {hqprj_abs}")


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
        from .device import pick_device_interactive, get_device
        remaining = args[1:]
        if not remaining:
            # No part/hqprj given: launch interactive device picker
            # Detect current device from auto-detected .hqprj
            current = None
            try:
                hqprj = _find_hqprj()
                if hqprj:
                    current = get_device(hqprj)
            except SystemExit:
                pass
            part = pick_device_interactive(current)
            if part is None:
                return
            hqprj_path = _resolve_hqprj(None)
            run_device(hqprj_path, part)
        else:
            first = remaining[0]
            rest = remaining[1:]
            # If the first argument is an existing .hqprj file, treat it as the
            # project path and launch the interactive picker (no part provided).
            if os.path.isfile(first) and first.lower().endswith('.hqprj'):
                current = None
                try:
                    current = get_device(first)
                except SystemExit:
                    pass
                part = pick_device_interactive(current)
                if part is None:
                    return
                hqprj_path = _resolve_hqprj(first)
                run_device(hqprj_path, part)
            else:
                # first is a part name
                part = first
                hqprj_path = _resolve_hqprj(rest[0] if rest else None)
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


def _quiet_filter_output(text: str) -> list:
    """Quiet-mode filter for hqfpga output: strip the startup banner
    (everything before the first 'Info:' line) and all 'Info:' lines,
    keeping only command results and warnings/errors."""
    lines = []
    seen_first_info = False
    for line in text.splitlines():
        if not seen_first_info:
            if line.startswith('Info:'):
                seen_first_info = True
            else:
                continue
        if line.startswith('Info:'):
            continue
        if line.strip():
            lines.append(line)
    return lines


def _run_hqfpga_cmd(version: dict, tool_args: list, quiet: bool) -> None:
    """Run 'hqfpga -cmd ...' for inline (-e) commands. Without -q, stream
    output as-is; with -q, capture output and print only the filtered result."""
    if not quiet:
        launcher.launch_tool(version, 'hqfpga', tool_args)
        return
    exe_path = version['hqfpga_path']
    proc = subprocess.run(
        [exe_path] + tool_args,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, errors='replace',
    )
    for line in _quiet_filter_output(proc.stdout):
        print(line)
    if proc.returncode != 0:
        sys.exit(proc.returncode)


def cmd_launch_cmd(args):
    """Launch hqfpga CLI: interactively (no args), with a TCL script,
    or with an inline command string via '-e'.

    '-q' (quiet) is only supported with '-e': it filters the banner and
    all 'Info:' lines from the output."""
    version = launcher.resolve_hqfpga_version()
    if not version:
        print("Error: no HqFPGA versions found.")
        print("Tip: Use 'hqbuddy -cfg auto' to configure scan roots.")
        sys.exit(1)

    if args and args[0] == '-e':
        # Inline command: write to a temp TCL file and run it.
        # '-q' may appear anywhere after -e.
        quiet = '-q' in args[1:]
        command = ' '.join(a for a in args[1:] if a != '-q').strip()
        if not command:
            print("Error: -cmd -e requires a TCL command string")
            sys.exit(1)
        fd, tmp = tempfile.mkstemp(suffix='.tcl', prefix='hqbuddy_cmd_')
        try:
            with os.fdopen(fd, 'w', encoding='utf-8') as f:
                f.write(command + '\n')
            _run_hqfpga_cmd(version, ['-cmd', tmp], quiet)
        finally:
            try:
                os.remove(tmp)
            except OSError:
                pass
        return

    tool_args = ['-cmd'] + args if args else []
    launcher.launch_tool(version, 'hqfpga', tool_args)


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


def _ensure_console_utf8():
    """Configure Windows console/stderr/stdout for UTF-8 output."""
    if sys.platform != 'win32':
        return
    try:
        import ctypes
        ctypes.windll.kernel32.SetConsoleOutputCP(65001)
    except Exception:
        pass
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
        sys.stderr.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass


def main():
    """Main entry point."""
    _ensure_console_utf8()
    args = sys.argv[1:]

    # No arguments: launch HqFPGA GUI
    if not args:
        cmd_gui([])
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

    # Root path
    if first == '-root':
        root = launcher.resolve_hqfpga_root()
        if root:
            print(root)
        else:
            print("Error: no HqFPGA versions found.")
            print("Tip: Use 'hqbuddy -cfg auto' to configure scan roots.")
        return

    # Build selector
    if first == '-build_sel':
        cmd_build()
        return

    # Clean
    if first == '-clean':
        force = '-force' in args or '-f' in args
        cmd_clean(force)
        return

    # New project
    if first == '-new_prj':
        cmd_new_prj(args[1:])
        return

    # Add files
    if first == '-add':
        cmd_add(args[1:])
        return

    # Set top module
    if first == '-set_top':
        cmd_set_top(args[1:])
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

    # IP generation
    if first == '-ipgen':
        hqip_arg = None
        lang = "chs"
        i = 1
        while i < len(args):
            if args[i] == '-lang' and i + 1 < len(args):
                lang = args[i + 1]
                i += 2
            elif not args[i].startswith('-') and hqip_arg is None:
                hqip_arg = args[i]
                i += 1
            else:
                i += 1
        run_ipgen(hqip_arg, lang)
        return

    # Update all IP netlists for project
    if first == '-update_ip':
        cmd_update_ip(args[1:])
        return

    # Simlib
    if first == '-simlib':
        cmd_simlib(args[1:])
        return

    # HDL encryption
    if first == '-encrypt':
        run_encrypt(args[1:])
        return

    # Generate default .hqip from IP meta XML
    if first == '-gen_hqip':
        run_gen_hqip(args[1:])
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

    # HqInsight
    if first == '-insight':
        run_insight(args[1:])
        return

    print(f"Error: unknown option: {first}")
    show_help()
    sys.exit(1)


if __name__ == '__main__':
    main()
