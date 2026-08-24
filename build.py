#!/usr/bin/env python3
"""Build script for HqBuddy.

Provides clean, build, and PATH registration.

Usage:
    python build.py [command]

Commands:
    build    Build hqbuddy.exe using PyInstaller
    clean    Remove build artifacts (exe, logs, temp files)
    help     Show this help message

Default (no command): clean + build (build registers PATH at the end)
"""

import glob
import os
import shutil
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROXY_DIR = os.path.join(os.environ.get("APPDATA", ""), "hqbuddy")

# ANSI colors (supported by Windows 10+ terminals)
CYAN = "\033[36m"
GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
RESET = "\033[0m"


def info(msg):
    print(f"{CYAN}{msg}{RESET}")


def ok(msg):
    print(f"{GREEN}{msg}{RESET}")


def fail(msg):
    print(f"{RED}{msg}{RESET}")
    sys.exit(1)


def show_help():
    print(__doc__.strip())


def _remove(path):
    """Remove a file or directory if it exists."""
    if os.path.isdir(path):
        shutil.rmtree(path, ignore_errors=True)
    elif os.path.exists(path):
        try:
            os.remove(path)
        except OSError:
            pass


def clean():
    info("Cleaning build artifacts and temporary files...")
    print()

    targets = [
        ("hqbuddy.exe", "hqbuddy.exe"),
        ("*.log", "log files"),
        ("*.dump", "dump files"),
        ("dist", "dist/"),
        ("build", "build/"),
        ("*.spec", "spec files"),
        ("_build_entry.py", "_build_entry.py"),
    ]

    for pattern, label in targets:
        matched = glob.glob(os.path.join(SCRIPT_DIR, pattern))
        if matched:
            for p in matched:
                _remove(p)
            ok(f"  [OK] Removed {label}")

    print()
    ok("Done.")


def _run(cmd, **kwargs):
    return subprocess.run(cmd, cwd=SCRIPT_DIR, **kwargs)


def build():
    info("========================================")
    info("  Building hqbuddy.exe")
    info("========================================")
    print()

    # Check Python (we are running on it, but verify subprocess works)
    try:
        subprocess.run(
            [sys.executable, "--version"],
            check=True, capture_output=True,
        )
    except (OSError, subprocess.CalledProcessError):
        fail("[FAIL] Python is not available.")

    # Check / install PyInstaller
    print("Checking PyInstaller...")
    r = _run([sys.executable, "-m", "PyInstaller", "--version"],
             capture_output=True, text=True)
    if r.returncode == 0:
        print(f"PyInstaller {r.stdout.strip()}")
    else:
        print("PyInstaller not found. Installing...")
        r = _run([sys.executable, "-m", "pip", "install", "pyinstaller"])
        if r.returncode != 0:
            fail("[FAIL] Failed to install PyInstaller.")

    # Create temporary entry point
    print()
    print("Preparing build entry point...")
    entry_file = os.path.join(SCRIPT_DIR, "_build_entry.py")
    with open(entry_file, "w", encoding="utf-8") as f:
        f.write("from hqbuddy.__main__ import main\nmain()\n")

    # Clean previous build artifacts
    print("Cleaning previous build artifacts...")
    for item in ("dist", "build", "hqbuddy.spec", "hqbuddy.exe"):
        _remove(os.path.join(SCRIPT_DIR, item))

    # Build
    print()
    print("Building hqbuddy.exe...")
    sep = ";" if os.name == "nt" else ":"
    cmd = [
        sys.executable, "-m", "PyInstaller",
        "--onefile",
        "--name", "hqbuddy",
        "--add-data", f"scripts{sep}scripts",
        "--add-data", f"templates{sep}templates",
        "--add-data", f"configs{sep}configs",
        entry_file,
    ]
    r = _run(cmd)
    if r.returncode != 0:
        print()
        _remove(entry_file)
        fail("[FAIL] Build failed.")

    # Copy exe to project root
    src = os.path.join(SCRIPT_DIR, "dist", "hqbuddy.exe")
    dst = os.path.join(SCRIPT_DIR, "hqbuddy.exe")
    try:
        shutil.copyfile(src, dst)
    except OSError:
        _remove(entry_file)
        fail("[FAIL] Failed to copy hqbuddy.exe.")
    ok("[OK] hqbuddy.exe created.")

    # Clean temporary files
    _remove(entry_file)
    _remove(os.path.join(SCRIPT_DIR, "dist"))
    _remove(os.path.join(SCRIPT_DIR, "build"))
    _remove(os.path.join(SCRIPT_DIR, "hqbuddy.spec"))
    ok("[OK] Cleaned temporary files.")

    print()
    ok("========================================")
    ok("  Build Complete")
    ok("========================================")
    print()

    register()


def _get_user_path():
    """Read the persistent user PATH from the registry (Windows)."""
    import winreg
    try:
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Environment") as key:
            value, _ = winreg.QueryValueEx(key, "Path")
            return value
    except OSError:
        return ""


def _set_user_path(value):
    """Write the persistent user PATH to the registry (Windows)."""
    import winreg
    with winreg.OpenKey(
        winreg.HKEY_CURRENT_USER, r"Environment", 0, winreg.KEY_SET_VALUE
    ) as key:
        winreg.SetValueEx(key, "Path", 0, winreg.REG_EXPAND_SZ, value)
    # Notify running apps that the environment changed
    try:
        import ctypes
        ctypes.windll.user32.SendMessageTimeoutW(
            0xFFFF, 0x001A, 0, "Environment", 0x0002, 5000, None
        )
    except Exception:
        pass


def register():
    info("Registering hqbuddy to user PATH...")
    print()

    exe = os.path.join(SCRIPT_DIR, "hqbuddy.exe")
    if not os.path.exists(exe):
        fail("[FAIL] hqbuddy.exe not found in project directory.\n"
             "       Please run 'python build.py build' first.")

    os.makedirs(PROXY_DIR, exist_ok=True)
    shutil.copyfile(exe, os.path.join(PROXY_DIR, "hqbuddy.exe"))
    ok("[OK] Copied hqbuddy.exe to proxy directory.")

    if os.name != "nt":
        print(f"[WARN] Automatic PATH registration is only supported on Windows.")
        print(f"       Please add the following path to your PATH manually:")
        print(f"       {PROXY_DIR}")
        return

    user_path = _get_user_path()
    path_parts = [p for p in user_path.split(";") if p]
    if PROXY_DIR.lower() in [p.lower() for p in path_parts]:
        ok("[OK] Already in user PATH.")
        return

    new_path = f"{user_path};{PROXY_DIR}" if user_path else PROXY_DIR
    try:
        _set_user_path(new_path)
        ok("[OK] Added to user PATH.")
    except OSError:
        print(f"{YELLOW}[WARN] Failed to update PATH automatically.{RESET}")
        print(f"{YELLOW}       Please add the following path to your PATH manually:{RESET}")
        print(f"{YELLOW}       {PROXY_DIR}{RESET}")
        return

    print()
    info("Please restart your terminal to use 'hqbuddy'.")


def main():
    command = sys.argv[1].lower() if len(sys.argv) > 1 else ""

    if command == "":
        clean()
        build()
    elif command == "build":
        build()
    elif command == "clean":
        clean()
    elif command == "help":
        show_help()
    else:
        print(f"{RED}Unknown command: {command}{RESET}")
        print("Run 'python build.py help' for usage.")
        sys.exit(1)


if __name__ == "__main__":
    main()
