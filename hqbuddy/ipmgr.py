"""IP management: list .hqip files associated with a project."""

import os

from .hqprj_parser import extract_filelist


def list_ip_files(hqprj_path: str) -> list[str]:
    """
    List all .hqip files used by the project.

    For each source file in the .hqprj FILE_SRC list, check if a .hqip file
    with the same base name exists in the same directory.

    Args:
        hqprj_path: Path to the .hqprj file.

    Returns:
        A list of absolute .hqip file paths.
    """
    filelist = extract_filelist(hqprj_path)

    ip_files: list[str] = []
    seen: set[str] = set()

    for src_path in filelist:
        src_abs = os.path.abspath(src_path)
        if not os.path.isfile(src_abs):
            continue

        base, _ = os.path.splitext(src_abs)
        hqip_path = base + ".hqip"

        if os.path.isfile(hqip_path):
            hqip_abs = os.path.abspath(hqip_path)
            if hqip_abs not in seen:
                seen.add(hqip_abs)
                ip_files.append(hqip_abs)

    return ip_files


def print_ip_files(hqprj_path: str) -> None:
    """Print the list of .hqip files for a project."""
    ip_files = list_ip_files(hqprj_path)
    print(f"Project: {os.path.abspath(hqprj_path)}")
    print(f"Total {len(ip_files)} IP file(s):")
    for i, f in enumerate(ip_files, 1):
        print(f"  {i}. {f}")
