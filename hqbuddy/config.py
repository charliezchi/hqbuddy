"""Configuration management for hqbuddy."""

import os
import json
import sys

DEFAULT_CONFIG = {
    "scan_path": ["C:\\"],
    "selected_build": None,
}


def get_config_dir() -> str:
    """Get the configuration directory path."""
    appdata = os.environ.get('APPDATA', os.path.expanduser('~'))
    return os.path.join(appdata, 'hqbuddy')


def get_config_path() -> str:
    """Get the full path to the config file."""
    return os.path.join(get_config_dir(), 'config.json')


def parse_config_text(text: str) -> dict:
    """Parse config JSON into a dict; migrates scan_roots -> scan_path.
    Raises json.JSONDecodeError if the content is not valid JSON."""
    data = json.loads(text)
    if not isinstance(data, dict):
        raise json.JSONDecodeError("config root must be an object", text, 0)
    if "scan_path" not in data and isinstance(data.get("scan_roots"), list):
        data["scan_path"] = data["scan_roots"]
    data.pop("scan_roots", None)
    for key, default in DEFAULT_CONFIG.items():
        data.setdefault(key, default)
    return data


def load_config() -> dict:
    """Load configuration from file, or return defaults if not exists."""
    config_path = get_config_path()
    if os.path.exists(config_path):
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                return parse_config_text(f.read())
        except (json.JSONDecodeError, OSError) as e:
            print(f"Warning: Failed to load config ({e}), using defaults.",
                  file=sys.stderr)
            return dict(DEFAULT_CONFIG)
    return dict(DEFAULT_CONFIG)


def save_config(cfg: dict) -> None:
    """Save configuration to file as plain JSON."""
    config_dir = get_config_dir()
    os.makedirs(config_dir, exist_ok=True)
    body = {
        "scan_path": list(cfg.get("scan_path") or []),
        "selected_build": cfg.get("selected_build"),
    }
    with open(get_config_path(), 'w', encoding='utf-8') as f:
        json.dump(body, f, indent=2, ensure_ascii=False)
        f.write("\n")
