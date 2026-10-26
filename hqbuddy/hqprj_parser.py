"""Parser for .hqprj project files.

Provides GUI-parity project understanding:
- FILE_SRC (enabled sources) and FILE_SRC_DISABLED (disabled sources)
- $WORK_DIR$ and relative-path resolution (GUI resolves both)
- FILE_TIME per-file timestamps (GUI staleness tracking)
- scalar project fields (TOP_MODULE, DIE, FAMILY, OUT_DIR, RTL_9 include path, …)
"""

import os


def _to_forward_slash(path: str) -> str:
    """Convert backslashes to forward slashes for cross-platform compatibility."""
    return path.replace("\\", "/")


def _resolve(raw_path: str, work_dir: str) -> str:
    """Resolve $WORK_DIR$ and relative paths against work_dir, absolute with
    forward slashes (the GUI resolves bare relative paths against the project
    directory, not its own cwd)."""
    resolved = raw_path.replace("$WORK_DIR$", work_dir + os.sep)
    if not os.path.isabs(resolved):
        resolved = os.path.join(work_dir, resolved)
    return _to_forward_slash(os.path.normpath(resolved))


def parse_hqprj(hqprj_path: str) -> dict:
    """Parse an .hqprj file into a structured view.

    Returns dict with:
      path, work_dir          -- project file and its directory
      fields                  -- all KEY=VALUE scalars (first wins per key;
                                 FILE_SRC*/FILE_TIME collected separately)
      sources                 -- enabled source files (absolute, forward slash)
      disabled                -- FILE_SRC_DISABLED files (present but excluded
                                 from synthesis by the GUI)
      missing                 -- enabled sources that do not exist on disk
      times / times_cst       -- FILE_TIME / FILE_TIME_CST entries in file order
      tc / pc                 -- resolved constraint files (FILE_TC / FILE_PC,
                                 NONE entries skipped)
      include_dir             -- RTL_9 include path ('' when NONE)
      top, die, family, out_dir, proj_name -- common scalar conveniences
      out_dir_abs             -- OUT_DIR resolved against the project dir
    """
    hqprj_path = os.path.abspath(hqprj_path)
    work_dir = os.path.dirname(hqprj_path)

    fields: dict = {}
    sources: list = []
    disabled: list = []
    times: list = []
    times_cst: list = []
    tc: list = []
    pc: list = []

    def _is_none(value: str) -> bool:
        # FILE_SRC=NONE / FILE_TC=NONE are GUI placeholders, not paths
        return value.strip() == "NONE"

    with open(hqprj_path, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            if not line or "=" not in line:
                continue
            key, value = line.split("=", 1)
            if key == "FILE_SRC":
                if not _is_none(value):
                    sources.append(_resolve(value, work_dir))
            elif key == "FILE_SRC_DISABLED":
                if not _is_none(value):
                    disabled.append(_resolve(value, work_dir))
            elif key == "FILE_TC":
                if not _is_none(value):
                    tc.append(_resolve(value, work_dir))
            elif key == "FILE_PC":
                if not _is_none(value):
                    pc.append(_resolve(value, work_dir))
            elif key == "FILE_TIME":
                times.append(value)
            elif key == "FILE_TIME_CST":
                times_cst.append(value)
            elif key not in fields:
                fields[key] = value

    missing = [p for p in sources if not os.path.isfile(p)]

    def field(key: str, default: str = "") -> str:
        v = fields.get(key, default)
        return default if v in ("NONE", "undefined") and default != "" else (v or default)

    out_dir = field("OUT_DIR", "hq_run")
    return {
        "path": _to_forward_slash(hqprj_path),
        "work_dir": _to_forward_slash(work_dir),
        "fields": fields,
        "sources": sources,
        "disabled": disabled,
        "missing": missing,
        "times": times,
        "times_cst": times_cst,
        "tc": tc,
        "pc": pc,
        "include_dir": _resolve(fields.get("RTL_9", ""), work_dir)
        if fields.get("RTL_9", "NONE") != "NONE" else "",
        "top": field("TOP_MODULE"),
        "die": field("DIE"),
        "family": field("FAMILY"),
        "out_dir": out_dir,
        "out_dir_abs": _resolve(out_dir, work_dir),
        "proj_name": field("PROJ_NAME"),
    }


def extract_filelist(hqprj_path: str) -> list[str]:
    """
    Extract enabled FILE_SRC entries from an .hqprj file.

    The placeholder $WORK_DIR$ is replaced with the absolute directory
    where the .hqprj file resides. All paths use forward slashes (/)
    for compatibility with tools like ModelSim.

    FILE_SRC_DISABLED entries are excluded (GUI: disabled sources do not
    participate in synthesis).

    Args:
        hqprj_path: Path to the .hqprj file.

    Returns:
        A list of absolute source file paths with forward slashes.
    """
    return parse_hqprj(hqprj_path)["sources"]


def print_filelist(hqprj_path: str) -> None:
    """Print the extracted filelist; -v style detail shows disabled/missing."""
    info = parse_hqprj(hqprj_path)
    print(f"Project: {info['path']}")
    print(f"Total {len(info['sources'])} enabled source file(s):")
    for i, f in enumerate(info["sources"], 1):
        stale = "  [MISSING]" if f in info["missing"] else ""
        print(f"  {i}. {f}{stale}")
    if info["disabled"]:
        print(f"Disabled ({len(info['disabled'])}):")
        for f in info["disabled"]:
            print(f"  - {f}")
    if info["include_dir"]:
        print(f"Include dir: {info['include_dir']}")
