#!/usr/bin/env python3
"""Install the hqfpga skill for Kimi Code CLI and/or Xiaomi MIMO.

Usage:
    python install_skill.py              # install to all targets (default)
    python install_skill.py --kimi       # only Kimi Code (~/.kimi-code/skills/)
    python install_skill.py --mimo       # only Xiaomi MIMO (~/.claude/skills/)
    python install_skill.py --kimi --mimo

Copies skills/hqfpga/ from this repository to the selected user-level skills
directories, replacing any previous version. For Xiaomi MIMO, also writes
locales/{zh-CN,en-US}.json display metadata used by the Plugins page.
"""

import argparse
import json
import os
import shutil
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SKILL_NAME = "hqfpga"
SRC = os.path.join(SCRIPT_DIR, "skills", SKILL_NAME)

# MIMO Plugins page display metadata (name/description stay in SKILL.md frontmatter)
MIMO_LOCALES = {
    "zh-CN": {
        "displayName": "HqFpga",
        "brief": "智多晶 HqFPGA 开发操作指南（工程/流程/约束/调试）",
    },
    "en-US": {
        "displayName": "HqFpga",
        "brief": "XiST HqFpga FPGA development guide (projects, flows, constraints, debug)",
    },
}

TARGETS = {
    "kimi": {
        "label": "Kimi Code",
        "dst": os.path.join(os.path.expanduser("~"), ".kimi-code", "skills", SKILL_NAME),
        "restart_hint": "Restart Kimi Code CLI (or start a new session) to pick it up.",
    },
    "mimo": {
        "label": "Xiaomi MIMO",
        "dst": os.path.join(os.path.expanduser("~"), ".claude", "skills", SKILL_NAME),
        "restart_hint": "Start a new MiMo Desktop conversation to pick it up.",
    },
}


def _write_mimo_locales(dst):
    locales_dir = os.path.join(dst, "locales")
    os.makedirs(locales_dir, exist_ok=True)
    for locale, meta in MIMO_LOCALES.items():
        path = os.path.join(locales_dir, f"{locale}.json")
        with open(path, "w", encoding="utf-8") as f:
            json.dump(meta, f, ensure_ascii=False, indent=2)
            f.write("\n")


def install_to(target_key):
    """Install the skill to one target. Returns True on success."""
    target = TARGETS[target_key]
    label = target["label"]
    dst = target["dst"]

    if os.path.isdir(dst):
        shutil.rmtree(dst)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copytree(SRC, dst)

    if target_key == "mimo":
        _write_mimo_locales(dst)

    print(f"[OK] Installed {SKILL_NAME} skill to {dst} ({label})")
    print(f"     {target['restart_hint']}")
    return True


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description="Install the hqfpga skill to Kimi Code and/or Xiaomi MIMO.",
    )
    parser.add_argument(
        "--kimi",
        action="store_true",
        help=f"install to Kimi Code ({TARGETS['kimi']['dst']})",
    )
    parser.add_argument(
        "--mimo",
        action="store_true",
        help=f"install to Xiaomi MIMO ({TARGETS['mimo']['dst']})",
    )
    return parser.parse_args(argv)


def main(argv=None):
    if not os.path.isdir(SRC):
        print(f"[FAIL] Skill source not found: {SRC}")
        sys.exit(1)

    args = parse_args(argv)
    selected = [key for key, flag in (("kimi", args.kimi), ("mimo", args.mimo)) if flag]
    if not selected:
        selected = list(TARGETS.keys())

    failed = False
    for key in selected:
        try:
            install_to(key)
        except OSError as exc:
            print(f"[FAIL] Failed to install to {TARGETS[key]['label']}: {exc}")
            failed = True

    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
