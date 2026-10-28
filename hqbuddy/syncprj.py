"""Reverse-update a .hqprj from its hqprj2tcl-generated flow TCL (-sync_prj).

The mapping is the exact inverse of what hqfpga's hqprj2tcl emits (verified
by mutating .hqprj fields and diffing the regenerated TCL). Only settings the
TCL actually expresses are rewritten; every other .hqprj key is preserved
(PROJ_NAME/bitgen only when a design.bitgen line exists, RTL_11/MAP_*/PLACE_2..
6/ROUTE_2..4/BGEN_13 are never exported by hqprj2tcl and stay untouched).
"""

import os
import re
import sys

from . import soc
from .device import _DEVICE_PART_RE


def _tcl_words(s: str) -> list:
    """Split a TCL command line into words, honoring {braces} and "quotes"."""
    words, i, n = [], 0, len(s)
    while i < n:
        c = s[i]
        if c in " \t":
            i += 1
        elif c == "{":
            depth, j = 1, i + 1
            while j < n and depth:
                if s[j] == "{":
                    depth += 1
                elif s[j] == "}":
                    depth -= 1
                j += 1
            words.append(s[i + 1:j - 1])
            i = j
        elif c == '"':
            j = s.find('"', i + 1)
            j = n if j < 0 else j
            words.append(s[i + 1:j])
            i = j + 1
        else:
            j = i
            while j < n and s[j] not in " \t":
                j += 1
            words.append(s[i:j])
            i = j
    return words


def _conv_bool(v: str) -> str:
    return {"on": "true", "off": "false"}.get(v, v)


# tcl flag -> .hqprj key (hqprj2tcl writes on/off for all of these)
_FLAG_MAP = {
    "ta.set": {
        "-ira": "GLOBAL_1", "-dlb": "GLOBAL_2", "-cca": "GLOBAL_3",
        "-analysis_type": "GLOBAL_4", "-actrl2q": "GLOBAL_6",
        "-clock_name_style": "GLOBAL_8",
    },
    "rtl.set": {
        "-infer_ram": "RTL_1", "-infer_rom": "RTL_2", "-fsm_opt": "RTL_3",
        "-expr_opt": "RTL_4", "-mux_opt": "RTL_5", "-dsp_map": "RTL_6",
        "-share_opt": "RTL_7", "-infer_srl": "RTL_10",
        "-macro_rebuild": "RTL_14",
    },
    "lo.slo.set": {
        "-sweep": "RTL_8", "-clk_conv": "RTL_12", "-data_opt": "RTL_16",
        "-merge": "RTL_17",
    },
    "lo.set": {"-cut_merge": "RTL_15"},
}


def prj_from_header(tcl_path: str) -> str | None:
    """Source .hqprj path from the `#[hqprj2tcl] Converted from <path>` line."""
    with open(tcl_path, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            m = re.match(r"#\[hqprj2tcl\]\s*Converted from (.+)", line.strip())
            return m.group(1).strip() if m else None
    return None


def parse_tcl(tcl_path: str) -> dict:
    """Extract every project setting the TCL expresses.

    Returns a dict with:
      updates        -- scalar .hqprj key -> new value (only expressed keys)
      file_lists     -- FILE_TC/FILE_PC/FILE_SRC -> entry list (may be empty)
      warnings       -- unparsed/ambiguous lines worth reporting
    """
    vars_: dict = {}
    updates: dict = {}
    file_lists: dict = {}
    warnings: list = []
    seen = {  # command-family presence gates (section absent -> keys untouched)
        "ta.set": False, "rtl.set": False, "lo.slo.set": False,
        "lo.set": False, "rtl.incpath.add": False, "design.rtlsyn": False,
        "design.tdomap": False, "ioh": False, "design.pack": False,
        "design.place": False, "design.route": False, "design.bitgen": False,
        "incpath_comment": False, "ff_init": False,
    }

    def set_flag(cmd: str, args: list, table: dict) -> None:
        seen[cmd] = True
        i = 0
        while i < len(args):
            a = args[i]
            if a in table:
                if i + 1 >= len(args):
                    warnings.append(f"{cmd} {a}: missing value")
                    break
                updates[table[a]] = _conv_bool(args[i + 1])
                i += 2
            elif a == "-ff_init" and cmd == "lo.slo.set":
                if i + 1 >= len(args):
                    warnings.append(f"{cmd} {a}: missing value")
                    break
                updates["GLOBAL_7"] = args[i + 1]
                seen["ff_init"] = True
                i += 2
            else:
                warnings.append(f"{cmd}: ignored option {a}")
                i += 1

    def resolve(tok: str) -> str:
        if tok.startswith("${") and tok.endswith("}"):
            v = vars_.get(tok[2:-1])
            return v[0] if v else tok
        if tok.startswith("$"):
            v = vars_.get(tok[1:])
            return v[0] if v else tok
        return tok

    with open(tcl_path, "r", encoding="utf-8", errors="replace") as f:
        for raw in f:
            st = raw.strip()
            if st.startswith("#"):
                if "-- Verilog include path --" in st:
                    seen["incpath_comment"] = True
                continue
            if not st:
                continue
            words = _tcl_words(st)
            cmd, args = words[0], words[1:]

            if cmd == "set" and len(args) >= 2:
                # tokenizer already stripped braces; join+split = TCL list
                # semantics for `set SDC_FILE {p1 p2}` vs a bare scalar
                vars_[args[0]] = " ".join(args[1:]).split()
                continue
            if cmd == "lappend" and len(args) >= 2:
                lst = vars_.setdefault(args[0], [])
                if isinstance(lst, list):
                    lst.extend(args[1:])
                continue
            if cmd == "dv.setup" and len(args) >= 2:
                fam = resolve(args[0])
                name = resolve(args[1])
                updates["FAMILY"] = fam
                m = _DEVICE_PART_RE.match(name)
                if m:
                    updates["DIE"] = m.group("die")
                    updates["SPEEDS"] = m.group("speed")
                    updates["PACKAGES"] = m.group("package")
                    updates["CONDITION"] = m.group("condition")
                else:
                    warnings.append(f"dv.setup: cannot split device name: {name}")
                continue
            if cmd in _FLAG_MAP:
                set_flag(cmd, args, _FLAG_MAP[cmd])
                continue
            if cmd == "rtl.incpath.add" and args:
                seen["rtl.incpath.add"] = True
                updates["RTL_9"] = args[0]
                continue
            if cmd == "design.rtlsyn":
                seen["design.rtlsyn"] = True
                for i, a in enumerate(args):
                    if a == "-top" and i + 1 < len(args) and "TOP_MODULE" not in updates:
                        updates["TOP_MODULE"] = resolve(args[i + 1])
                updates["GLOBAL_5"] = "true" if "-keep_hier" in args else "false"
                continue
            if cmd == "design.tdomap":
                seen["design.tdomap"] = True
                updates["RTL_13"] = "true" if "-no_ioins" in args else "false"
                continue
            if cmd == "ioh.set_default_pullmode" and args:
                seen["ioh"] = True
                updates["PACK_7"] = args[0]
                continue
            if cmd == "ioh.set_global_attr":
                seen["ioh"] = True
                if "-trans_mode" in args:
                    updates["GLOBAL_10"] = "true"
                if "-unused_io" in args:
                    updates["PACK_8"] = "true"
                continue
            if cmd == "design.pack":
                seen["design.pack"] = True
                for i, a in enumerate(args):
                    if a in ("-effort", "-ratio", "-iob_dff") and i + 1 < len(args):
                        key = {"-effort": "PACK_6", "-ratio": "PACK_1",
                               "-iob_dff": "PACK_2"}[a]
                        updates[key] = args[i + 1]
                continue
            if cmd == "design.place":
                seen["design.place"] = True
                if "-effort" in args:
                    vals = [resolve(t) for t in args[args.index("-effort") + 1:]
                            if not t.startswith("-")]
                    if vals:
                        updates["PLACE_1"] = vals[0]
                    updates["PLACE_7"] = vals[1] if len(vals) > 1 else "NONE"
                continue
            if cmd == "design.route":
                seen["design.route"] = True
                if "-effort" in args and args.index("-effort") + 1 < len(args):
                    updates["ROUTE_1"] = args[args.index("-effort") + 1]
                continue
            if cmd == "design.bitgen" and args:
                seen["design.bitgen"] = True
                target = resolve(args[0])
                updates["PROJ_NAME"] = os.path.splitext(
                    os.path.basename(target))[0]
                flags, value_flags = [], {"-config", "-dclk"}
                extras = []
                i = 1
                while i < len(args):
                    a = args[i]
                    if a in value_flags and i + 1 < len(args):
                        key = "-config" if a == "-config" else "-dclk"
                        updates["BGEN_6" if a == "-config" else "BGEN_12"] = \
                            resolve(args[i + 1])
                        i += 2
                        continue
                    if a.startswith("-"):
                        flags.append(a)
                    else:
                        extras.append(a)
                    i += 1
                updates["BGEN_1"] = "true" if "-bin" in flags else "false"
                for flag, key in (("-compress", "BGEN_2"), ("-nocrc", "BGEN_3"),
                                  ("-rbin", "BGEN_4"), ("-v", "BGEN_5"),
                                  ("-framecrc", "BGEN_7"),
                                  ("-trans_mode", "BGEN_9"),
                                  ("-sspi", "BGEN_10"), ("-i2c", "BGEN_11")):
                    updates[key] = "true" if flag in flags else "false"
                updates["BGEN_6"] = updates.get("BGEN_6", "NONE")
                updates["BGEN_12"] = updates.get("BGEN_12", "")  # template default
                updates["BGEN_8"] = " ".join(extras) if extras else "NONE"
                continue
            # flow-only commands (design.analyze/flatten, tc.clear, foreach,
            # sdc.read, ta.report, ...) carry no project state: ignore
    def sv(name: str) -> str:
        v = vars_.get(name)
        return v[0] if v else ""

    if sv("DEV_FAMILY"):
        updates.setdefault("FAMILY", sv("DEV_FAMILY"))
    if sv("DEV_NAME") and "DIE" not in updates:
        m = _DEVICE_PART_RE.match(sv("DEV_NAME"))
        if m:
            updates["DIE"] = m.group("die")
            updates["SPEEDS"] = m.group("speed")
            updates["PACKAGES"] = m.group("package")
            updates["CONDITION"] = m.group("condition")
        else:
            warnings.append(f"set DEV_NAME: cannot split device name: {sv('DEV_NAME')}")
    if sv("TOP_MODULE"):
        updates["TOP_MODULE"] = sv("TOP_MODULE")
    if "SDC_FILE" in vars_:
        file_lists["FILE_TC"] = [resolve(p) for p in vars_["SDC_FILE"] if p]
    if "UPC_FILE" in vars_:
        file_lists["FILE_PC"] = [resolve(p) for p in vars_["UPC_FILE"] if p]
    if "RTL_FILES" in vars_:
        file_lists["FILE_SRC"] = [resolve(p) for p in vars_["RTL_FILES"] if p]
    # strict inverse within an expressed section: option line absent -> default
    if seen["ta.set"]:
        for key in ("GLOBAL_1", "GLOBAL_2", "GLOBAL_3", "GLOBAL_6"):
            updates.setdefault(key, "false")
        updates.setdefault("GLOBAL_4", "setup")
        updates.setdefault("GLOBAL_8", "pin")
    if seen["rtl.set"]:
        for key in ("RTL_1", "RTL_2", "RTL_3", "RTL_4", "RTL_5", "RTL_6",
                    "RTL_7", "RTL_10", "RTL_14"):
            updates.setdefault(key, "false")
    if seen["lo.slo.set"]:
        for key in ("RTL_8", "RTL_12", "RTL_16", "RTL_17"):
            updates.setdefault(key, "false")
        if not seen["ff_init"]:
            updates.setdefault("GLOBAL_7", "NONE")
    if seen["lo.set"]:
        updates.setdefault("RTL_15", "false")
    if seen["incpath_comment"] and not seen["rtl.incpath.add"]:
        updates.setdefault("RTL_9", "NONE")
    if seen["ioh"]:
        updates.setdefault("GLOBAL_10", "false")
        updates.setdefault("PACK_8", "false")
    return {"updates": updates, "file_lists": file_lists, "warnings": warnings}


def _relativize(path: str, work_dir: str) -> str:
    """$WORK_DIR$-relative when under the project dir, else absolute (GUI/-add
    convention)."""
    p = path.replace("\\", "/")
    ap = os.path.normpath(p)
    try:
        rel = os.path.relpath(ap, work_dir)
    except ValueError:  # different drives
        return ap.replace("\\", "/")
    if rel.startswith(".."):
        return ap.replace("\\", "/")
    return "$WORK_DIR$" + rel.replace("\\", "/")


def _first_value(lines: list, key: str) -> str | None:
    for ln in lines:
        if ln.startswith(key + "="):
            return ln[len(key) + 1:]
    return None


def sync_prj(tcl_path: str, hqprj_path: str) -> None:
    """Reverse-update hqprj_path in place from tcl_path and report changes."""
    parsed = parse_tcl(tcl_path)
    for w in parsed["warnings"]:
        print(f"  [WARN] {w}")

    with open(hqprj_path, "r", encoding="utf-8", errors="replace") as f:
        raw = f.read()
    crlf = "\r\n" in raw
    lines = raw.splitlines()
    work_dir = os.path.dirname(os.path.abspath(hqprj_path))

    changed = 0
    for key, val in parsed["updates"].items():
        old = _first_value(lines, key)
        if old != val:
            print(f"  [SET] {key}: {old!r} -> {val!r}")
            changed += 1

    new_files: dict = {}
    for kind, entries in parsed["file_lists"].items():
        rel = [_relativize(p, work_dir) for p in entries]
        old = []
        for ln in lines:
            if ln.startswith(kind + "="):
                old.append(ln[len(kind) + 1:])
        if old != rel:
            new_files[kind] = rel
            print(f"  [SET] {kind}: {len(old)} -> {len(rel)} file(s)")
            changed += 1

    if not changed:
        print("No changes — .hqprj already matches the TCL "
              "(FILE_TIME refreshed).")

    for key, val in parsed["updates"].items():
        done = False
        for i, ln in enumerate(lines):
            if ln.startswith(key + "="):
                lines[i] = f"{key}={val}"
                done = True
                break
        if not done:
            lines.append(f"{key}={val}")
    for kind, rel in new_files.items():
        new_lines = [f"{kind}={e}" for e in rel] or [f"{kind}=NONE"]
        idxs = [i for i, ln in enumerate(lines) if ln.startswith(kind + "=")]
        if idxs:
            drop = set(idxs[1:])
            lines = [ln for i, ln in enumerate(lines) if i not in drop]
            pos = next(i for i, ln in enumerate(lines)
                       if ln.startswith(kind + "="))
            lines[pos:pos + 1] = new_lines
        else:
            lines.extend(new_lines)

    with open(hqprj_path, "w", encoding="utf-8", newline="") as f:
        f.write(("\r\n" if crlf else "\n").join(lines) + ("\r\n" if crlf else "\n"))
    soc.refresh_hqprj_times(hqprj_path)
    if changed:
        print(f"Updated: {os.path.abspath(hqprj_path)}")


def run_sync_prj(tcl_path: str, hqprj_path: str) -> None:
    for path in (tcl_path, hqprj_path):
        if not os.path.isfile(path):
            print(f"Error: file not found: {path}")
            sys.exit(1)
    print(f"TCL:     {os.path.abspath(tcl_path)}")
    print(f"Project: {os.path.abspath(hqprj_path)}")
    sync_prj(tcl_path, hqprj_path)
