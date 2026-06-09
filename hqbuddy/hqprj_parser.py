"""Parser for .hqprj files to extract filelist"""

import os


def _to_forward_slash(path: str) -> str:
    """Convert backslashes to forward slashes for cross-platform compatibility."""
    return path.replace("\\", "/")


def extract_filelist(hqprj_path: str) -> list[str]:
    """
    Extract FILE_SRC entries from an .hqprj file.

    The placeholder $WORK_DIR$ is replaced with the absolute directory
    where the .hqprj file resides. All paths use forward slashes (/)
    for compatibility with tools like ModelSim.

    Args:
        hqprj_path: Path to the .hqprj file.

    Returns:
        A list of absolute source file paths with forward slashes.
    """
    hqprj_path = os.path.abspath(hqprj_path)
    work_dir = os.path.dirname(hqprj_path)

    filelist: list[str] = []

    with open(hqprj_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line.startswith("FILE_SRC="):
                raw_path = line[len("FILE_SRC="):]
                # Replace $WORK_DIR$ with the project directory
                resolved = raw_path.replace("$WORK_DIR$", work_dir + os.sep)
                # Normalize the path, then convert to forward slashes
                resolved = os.path.normpath(resolved)
                resolved = _to_forward_slash(resolved)
                filelist.append(resolved)

    return filelist


def print_filelist(hqprj_path: str) -> None:
    """Print the extracted filelist from an .hqprj file."""
    files = extract_filelist(hqprj_path)
    print(f"Project: {os.path.abspath(hqprj_path)}")
    print(f"Total {len(files)} source file(s):")
    for i, f in enumerate(files, 1):
        print(f"  {i}. {f}")
