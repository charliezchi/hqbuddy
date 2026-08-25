"""Device part management: get/set device from .hqprj and .hqip files."""

import msvcrt
import os
import re
import sys
import xml.etree.ElementTree as ET

from . import config
from .ipmgr import list_ip_files
from .scanner import scan_all, get_selected_version


# Regex to parse device part strings like SA5T-200-D0-7H676CI
_DEVICE_PART_RE = re.compile(
    r"^(?P<die>.+)-(?P<speed>\d)(?P<package>[A-Za-z]+\d+)(?P<condition>[A-Za-z]+)$"
)


def _parse_key_value(line: str) -> tuple[str, str] | None:
    """
    Parse a key=value line from .hqprj.

    Returns:
        Tuple of (key, value) or None if not a valid key=value line.
    """
    if "=" not in line:
        return None
    key, value = line.split("=", 1)
    return key.strip(), value.strip()


def _get_device_list_xml() -> ET.Element:
    """Parse and return the dv_list.xml root element from the selected HqFPGA version."""
    cfg = config.load_config()
    versions = scan_all(cfg)
    if not versions:
        print("Error: no HqFPGA versions found.")
        print("Tip: Use 'hqbuddy -cfg' to edit the scan roots in config.json.")
        sys.exit(1)

    version = get_selected_version(versions, cfg.get("selected_build"))
    dv_list_path = os.path.join(
        version['path'], 'build', 'common', 'device', 'dv_list.xml'
    )

    if not os.path.exists(dv_list_path):
        print(f"Error: Device list not found: {dv_list_path}")
        sys.exit(1)

    try:
        tree = ET.parse(dv_list_path)
        return tree.getroot()
    except Exception as e:
        print(f"Error parsing device list: {e}")
        sys.exit(1)


def _get_valid_devices() -> set[str]:
    """
    Query the selected HqFPGA version's dv_list.xml for valid device part numbers.

    Returns:
        A set of valid device part strings.
    """
    root = _get_device_list_xml()
    devices: set[str] = set()
    for family in root.findall('.//family'):
        order_parts = family.find('order_parts')
        if order_parts is None:
            continue
        for part in order_parts.findall('part'):
            name = part.get('name')
            if name:
                devices.add(name)
    return devices


def get_family_for_device(device: str) -> str | None:
    """
    Look up the family name for a given device part number.

    Args:
        device: Device part string (e.g. SA5T-100-D0-7H676CI).

    Returns:
        Family name (e.g. SEAL), or None if not found.
    """
    try:
        root = _get_device_list_xml()
    except SystemExit:
        return None
    for family in root.findall('.//family'):
        family_name = family.get('name', '').upper()
        order_parts = family.find('order_parts')
        if order_parts is None:
            continue
        for part in order_parts.findall('part'):
            if part.get('name') == device:
                return family_name
    return None


def get_device(hqprj_path: str) -> str:
    """
    Get the current device part from an .hqprj file.

    The device part is composed as DIE-SPEEDPACKAGE-CONDITION.

    Args:
        hqprj_path: Path to the .hqprj file.

    Returns:
        The device part string.
    """
    if not os.path.isfile(hqprj_path):
        print(f"Error: file not found: {hqprj_path}")
        sys.exit(1)

    die = None
    speed = None
    package = None
    condition = None

    with open(hqprj_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            parsed = _parse_key_value(line)
            if not parsed:
                continue
            key, value = parsed
            if key == "DIE":
                die = value
            elif key == "SPEEDS":
                speed = value
            elif key == "PACKAGES":
                package = value
            elif key == "CONDITION":
                condition = value

    if not all([die, speed, package, condition]):
        missing = [k for k, v in {
            "DIE": die, "SPEEDS": speed, "PACKAGES": package, "CONDITION": condition
        }.items() if not v]
        print(f"Error: missing device field(s) in .hqprj: {', '.join(missing)}")
        sys.exit(1)

    return f"{die}-{speed}{package}{condition}"


def _update_hqprj_device(hqprj_path: str, part: str, die: str, speed: str, package: str, condition: str, family: str | None = None) -> None:
    """Update device fields in the .hqprj file."""
    with open(hqprj_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    updated = False
    new_lines = []
    for line in lines:
        stripped = line.strip()
        parsed = _parse_key_value(stripped)
        if parsed:
            key, _ = parsed
            if key == "FAMILY" and family is not None:
                new_lines.append(f"FAMILY={family}\n")
                updated = True
                continue
            elif key == "DIE":
                new_lines.append(f"DIE={die}\n")
                updated = True
                continue
            elif key == "SPEEDS":
                new_lines.append(f"SPEEDS={speed}\n")
                updated = True
                continue
            elif key == "PACKAGES":
                new_lines.append(f"PACKAGES={package}\n")
                updated = True
                continue
            elif key == "CONDITION":
                new_lines.append(f"CONDITION={condition}\n")
                updated = True
                continue
        new_lines.append(line)

    if not updated:
        print("Error: no device fields found to update in .hqprj.")
        sys.exit(1)

    with open(hqprj_path, "w", encoding="utf-8") as f:
        f.writelines(new_lines)

    print(f"Device updated to: {part}")
    print(f"File: {os.path.abspath(hqprj_path)}")


def _update_hqip_device(hqip_path: str, part: str) -> bool:
    """
    Update the device field in a single .hqip file.

    Args:
        hqip_path: Path to the .hqip file.
        part: New device part string.

    Returns:
        True if updated, False otherwise.
    """
    if not os.path.isfile(hqip_path):
        return False

    with open(hqip_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    # Find [IP] section and update device= under it
    in_ip_section = False
    updated = False
    new_lines = []

    for line in lines:
        stripped = line.strip()

        # Section header
        if stripped.startswith("[") and stripped.endswith("]"):
            in_ip_section = (stripped == "[IP]")
            new_lines.append(line)
            continue

        # Update device= only in [IP] section
        if in_ip_section and stripped.startswith("device="):
            new_lines.append(f"device={part}\n")
            updated = True
            continue

        new_lines.append(line)

    if updated:
        with open(hqip_path, "w", encoding="utf-8") as f:
            f.writelines(new_lines)

    return updated


def set_device(hqprj_path: str, part: str, update_ip: bool = True) -> None:
    """
    Set the device part in an .hqprj file after validating it.

    Optionally also updates the device field in all related .hqip files.

    Args:
        hqprj_path: Path to the .hqprj file.
        part: The new device part string (e.g. SA5T-200-D0-7H676CI).
        update_ip: If True, also update related .hqip files.
    """
    if not os.path.isfile(hqprj_path):
        print(f"Error: file not found: {hqprj_path}")
        sys.exit(1)

    # Validate part format: DIE-SPEEDPACKAGE-CONDITION
    match = _DEVICE_PART_RE.match(part)
    if not match:
        print("Error: device part must be in format DIE-SPEEDPACKAGE-CONDITION")
        print(f"  Example: SA5T-200-D0-7H676CI")
        sys.exit(1)

    die = match.group("die")
    speed = match.group("speed")
    package = match.group("package")
    condition = match.group("condition")

    # Validate against selected build's device list
    valid_devices = _get_valid_devices()
    if part not in valid_devices:
        print(f"Error: invalid device part: {part}")
        sys.exit(1)

    # Look up family and update .hqprj
    family = get_family_for_device(part)
    _update_hqprj_device(hqprj_path, part, die, speed, package, condition, family)

    # Update related .hqip files
    if update_ip:
        print(f"")
        print("Updating related .hqip files...")
        ip_files = list_ip_files(hqprj_path)
        updated_count = 0
        for hqip_path in ip_files:
            if _update_hqip_device(hqip_path, part):
                print(f"  [OK] {os.path.abspath(hqip_path)}")
                updated_count += 1
            else:
                print(f"  [SKIP] No device field in [IP] section: {os.path.abspath(hqip_path)}")
        print(f"")
        print(f"Updated {updated_count} .hqip file(s).")


def _clear_lines(n: int):
    """Move cursor up n lines and clear them."""
    for _ in range(n):
        sys.stdout.write('\033[F\033[K')
    sys.stdout.flush()


def _draw_device_list(devices: list[str], selected_idx: int, search: str,
                       current_device: str | None) -> int:
    """Draw the device selector UI. Returns number of lines printed."""
    lines = 0
    print(f"Type to search: {search}")
    lines += 1
    total = len(devices)
    start = max(0, selected_idx - 10)
    end = min(total, start + 20)
    if end - start < 20 and start > 0:
        start = max(0, end - 20)
    for i in range(start, end):
        cursor = " \u25b6" if i == selected_idx else "  "
        marker = ">" if devices[i] == current_device else " "
        print(f"{cursor} {marker} {devices[i]}")
        lines += 1
    if total > end:
        print(f"  ... and {total - end} more")
        lines += 1
    if total == 0:
        print("  (no matches)")
        lines += 1
    sys.stdout.flush()
    return lines


def pick_device_interactive(current_device: str | None = None) -> str | None:
    """
    Interactive device selector with keyboard navigation and search.

    Returns:
        Selected device part string, or None if cancelled.
    """
    all_devices = sorted(_get_valid_devices())
    if not all_devices:
        print("Error: no devices found in dv_list.xml.")
        return None

    filtered = list(all_devices)
    selected_idx = 0
    search = ""

    lines_printed = _draw_device_list(filtered, selected_idx, search, current_device)

    while True:
        key = msvcrt.getch()

        if key == b'\xe0':  # Arrow keys
            key = msvcrt.getch()
            if key == b'H':  # Up
                selected_idx = max(0, selected_idx - 1)
            elif key == b'P':  # Down
                selected_idx = min(len(filtered) - 1, selected_idx + 1)
            _clear_lines(lines_printed)
            lines_printed = _draw_device_list(filtered, selected_idx, search, current_device)

        elif key == b'\r':  # Enter
            if filtered:
                _clear_lines(lines_printed)
                return filtered[selected_idx]

        elif key == b'\x08':  # Backspace
            if search:
                search = search[:-1]
                filtered = [d for d in all_devices if search.upper() in d.upper()]
                selected_idx = 0
            _clear_lines(lines_printed)
            lines_printed = _draw_device_list(filtered, selected_idx, search, current_device)

        elif key == b'\x1b':  # Esc
            _clear_lines(lines_printed)
            return None

        elif key == b'\x03':  # Ctrl+C
            print("")
            return None

        else:  # Regular character (for search)
            try:
                ch = key.decode('utf-8')
                if ch.isprintable():
                    search += ch
                    filtered = [d for d in all_devices if search.upper() in d.upper()]
                    selected_idx = 0
                _clear_lines(lines_printed)
                lines_printed = _draw_device_list(filtered, selected_idx, search, current_device)
            except UnicodeDecodeError:
                pass


def run_device(hqprj_path: str, part: str | None = None) -> None:
    """
    Get or set the device part for an .hqprj file.

    Args:
        hqprj_path: Path to the .hqprj file.
        part: Optional new device part to set. If None, print current part.
    """
    if part:
        set_device(hqprj_path, part)
    else:
        current = get_device(hqprj_path)
        print(f"Device: {current}")
