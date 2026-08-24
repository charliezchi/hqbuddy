#!/usr/bin/env python3
"""Install the hqfpga skill for Kimi Code CLI.

Usage:
    python install_skill.py

Copies skills/hqfpga/ from this repository to the user-level skills
directory (~/.kimi-code/skills/hqfpga/), replacing any previous version.
"""

import os
import shutil
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(SCRIPT_DIR, "skills", "hqfpga")
DST = os.path.join(os.path.expanduser("~"), ".kimi-code", "skills", "hqfpga")


def main():
    if not os.path.isdir(SRC):
        print(f"[FAIL] Skill source not found: {SRC}")
        sys.exit(1)

    if os.path.isdir(DST):
        shutil.rmtree(DST)
    os.makedirs(os.path.dirname(DST), exist_ok=True)
    shutil.copytree(SRC, DST)

    print(f"[OK] Installed hqfpga skill to {DST}")
    print("     Restart Kimi Code CLI (or start a new session) to pick it up.")


if __name__ == "__main__":
    main()
