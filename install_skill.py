#!/usr/bin/env python3
"""Install the hqfpga skill for Kimi Code CLI, Claude Code, ZCode and/or Codex.

Usage:
    python install_skill.py              # install to all targets (default)
    python install_skill.py --kimi       # only Kimi Code (~/.kimi-code/skills/)
    python install_skill.py --claude       # only Claude Code (~/.claude/skills/)
    python install_skill.py --zcode      # only ZCode (~/.zcode/skills/)
    python install_skill.py --codex      # only Codex (~/.agents/skills/)
    python install_skill.py --kimi --claude --zcode --codex

Copies skills/hqfpga/ from this repository to the selected user-level skills
directories, replacing any previous version.
"""

import argparse
import os
import shutil
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SKILL_NAME = "hqfpga"
SRC = os.path.join(SCRIPT_DIR, "skills", SKILL_NAME)

TARGETS = {
    "kimi": {
        "label": "Kimi Code",
        "dst": os.path.join(os.path.expanduser("~"), ".kimi-code", "skills", SKILL_NAME),
        "restart_hint": "Restart Kimi Code CLI (or start a new session) to pick it up.",
    },
    "claude": {
        "label": "Claude Code",
        "dst": os.path.join(os.path.expanduser("~"), ".claude", "skills", SKILL_NAME),
        "restart_hint": "Start a new Claude Code session to pick it up.",
    },
    "zcode": {
        "label": "ZCode",
        "dst": os.path.join(os.path.expanduser("~"), ".zcode", "skills", SKILL_NAME),
        "restart_hint": "Restart ZCode CLI (or start a new session) to pick it up.",
    },
    "codex": {
        "label": "Codex",
        "dst": os.path.join(os.path.expanduser("~"), ".agents", "skills", SKILL_NAME),
        "restart_hint": "Codex detects skill changes automatically; restart Codex if it does not appear.",
    },
}


def install_to(target_key):
    """Install the skill to one target. Returns True on success."""
    target = TARGETS[target_key]
    label = target["label"]
    dst = target["dst"]

    if os.path.isdir(dst):
        shutil.rmtree(dst)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copytree(SRC, dst)

    print(f"[OK] Installed {SKILL_NAME} skill to {dst} ({label})")
    print(f"     {target['restart_hint']}")
    return True


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description="Install the hqfpga skill to Kimi Code, Claude Code, ZCode and/or Codex.",
    )
    parser.add_argument(
        "--kimi",
        action="store_true",
        help=f"install to Kimi Code ({TARGETS['kimi']['dst']})",
    )
    parser.add_argument(
        "--claude",
        action="store_true",
        help=f"install to Claude Code ({TARGETS['claude']['dst']})",
    )
    parser.add_argument(
        "--zcode",
        action="store_true",
        help=f"install to ZCode ({TARGETS['zcode']['dst']})",
    )
    parser.add_argument(
        "--codex",
        action="store_true",
        help=f"install to Codex ({TARGETS['codex']['dst']})",
    )
    return parser.parse_args(argv)


def main(argv=None):
    if not os.path.isdir(SRC):
        print(f"[FAIL] Skill source not found: {SRC}")
        sys.exit(1)

    args = parse_args(argv)
    selected = [key for key in TARGETS if getattr(args, key)]
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
