"""HDL source encryption via hq_ipencrypt.exe."""

import os
import subprocess
import sys

from . import launcher

# Relative location of the encrypt tool and its key repository
# inside an HqFpGA installation.
_TOOL_RELPATH = os.path.join('build', 'common', 'util', 'hq_ipencrypt.exe')
_KEYS_RELPATH = os.path.join('build', 'common', 'util', 'keys.txt')

_SRC_EXTS = ('.v', '.vh')


def _resolve_tool() -> tuple[str, str]:
    """Resolve (hq_ipencrypt.exe, keys.txt) from the selected HqFpGA version."""
    version = launcher.resolve_hqfpga_version()
    if not version:
        print("Error: no HqFPGA versions found.")
        print("Tip: Use 'hqbuddy -cfg auto' to configure scan roots.")
        sys.exit(1)
    root = version['path']
    exe = os.path.join(root, _TOOL_RELPATH)
    keys = os.path.join(root, _KEYS_RELPATH)
    for p, label in ((exe, 'hq_ipencrypt.exe'), (keys, 'keys.txt')):
        if not os.path.exists(p):
            print(f"Error: {label} not found: {p}")
            sys.exit(1)
    return exe, keys


def _classify_inputs(inputs: list) -> tuple[list, list]:
    """Split inputs into (source files, .f filelists)."""
    files, lists = [], []
    for item in inputs:
        ext = os.path.splitext(item)[1].lower()
        if ext == '.f':
            if os.path.isfile(item):
                lists.append(item)
            else:
                print(f"Warning: filelist not found, skipped: {item}")
        elif ext in _SRC_EXTS:
            if os.path.isfile(item):
                files.append(item)
            else:
                print(f"Warning: file not found, skipped: {item}")
        else:
            print(f"Warning: unsupported file type skipped: {item}")
    return files, lists


def run_encrypt(args: list) -> None:
    """Encrypt HDL source files with hq_ipencrypt.exe.

    Usage: hqbuddy -encrypt [<files...>] [-d <outdir>] [-m <method>] [-po]
    Without input files, encrypts all .v files and .f filelists found in
    the current directory.
    """
    inputs = []
    outdir = 'encrypted'
    method = 'aes256-cbc'
    protect_only = False

    i = 0
    while i < len(args):
        a = args[i]
        if a == '-d' and i + 1 < len(args):
            outdir = args[i + 1]
            i += 2
        elif a == '-m' and i + 1 < len(args):
            method = args[i + 1]
            i += 2
        elif a in ('-po', '-p_only'):
            protect_only = True
            i += 1
        elif a.startswith('-'):
            print(f"Error: unknown option: {a}")
            sys.exit(1)
        else:
            inputs.append(a)
            i += 1

    if not inputs:
        # Default: all .v files and .f filelists in the current directory
        inputs = sorted(
            f for f in os.listdir('.')
            if os.path.isfile(f) and os.path.splitext(f)[1].lower() in ('.v', '.f')
        )
        if inputs:
            print(f"No input specified, encrypting all .v/.f in current directory: "
                  f"{', '.join(inputs)}")
        else:
            print("Error: -encrypt requires input files (.v/.vh/.f), "
                  "and no .v/.f files found in current directory")
            sys.exit(1)

    if method not in ('aes128-cbc', 'aes256-cbc'):
        print(f"Error: invalid method '{method}' (expect aes128-cbc or aes256-cbc)")
        sys.exit(1)

    files, lists = _classify_inputs(inputs)
    if not files and not lists:
        print("Error: no valid input files.")
        sys.exit(1)

    exe, keys = _resolve_tool()
    os.makedirs(outdir, exist_ok=True)

    failed = 0
    total = len(files) + len(lists)

    def _run(mode: str, target: str) -> bool:
        cmd = [exe, mode, target, '-pk', keys, '-m', method, '-d', outdir]
        if protect_only:
            cmd.append('-po')
        proc = subprocess.run(cmd, capture_output=True, text=True, errors='replace')
        return proc.returncode == 0, (proc.stdout or '').strip()

    # Filelists via the tool's -l branch (output names not knowable here,
    # so only the exit code is checked)
    for lst in lists:
        success, output = _run('-l', lst)
        if success:
            print(f"[OK] {lst} (filelist) -> {outdir}/")
        else:
            failed += 1
            print(f"[FAIL] {lst}")
            if output:
                print(f"       {output}")

    for f in files:
        success, output = _run('-f', f)
        out_file = os.path.join(outdir, os.path.basename(f))
        if success and os.path.exists(out_file):
            print(f"[OK] {f} -> {out_file}")
        else:
            failed += 1
            print(f"[FAIL] {f}")
            if output:
                print(f"       {output}")

    print(f"\nDone: {total - failed} succeeded, {failed} failed. "
          f"Output dir: {os.path.abspath(outdir)} (method: {method}"
          f"{', protect-only' if protect_only else ''})")
    if failed:
        sys.exit(1)
