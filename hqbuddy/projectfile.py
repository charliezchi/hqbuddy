"""Spec-compliant .hqprj FILE-section reader/writer (P0 spec study).

The authoritative format was extracted from the official HqFpga GUI's own
serialization code (hqui resources: project-manager.js save block +
server.js formINIString — two independent implementations that agree):

    str0  VERSION/PROJ_NAME/OUT_DIR/... header (untouched here)
    str1  FILE_TC= / FILE_TC_DISABLED= lines (FILE_TC=NONE placeholder when
          no TC exists at all)
    str2  FILE_PC= / FILE_PC_DISABLED= lines
    str3  TOP_MODULE/STEP_*/RTL_*/GLOBAL_*/MAP_*/... (untouched here)
    str4  FILE_SRC= / FILE_SRC_DISABLED= lines (FILE_SRC=NONE placeholder)
    str5  FILE_TIME= one per source file IN THE SAME ORDER as the FILE_SRC/
          FILE_SRC_DISABLED block (disabled files keep their FILE_TIME),
          then FILE_TIME_CST= one per constraint file, TC group first then
          PC group, again including disabled ones

All lines CRLF; paths use $WORK_DIR$ prefixes with forward slashes;
FILE_TIME values are file mtimes in epoch seconds.

hqbuddy edits keep every non-FILE line at its existing position and only
re-lay the FILE blocks out per this spec — the GUI re-reads the result
identically to its own saves.
"""

import io
import os

FILE_KEYS = ("FILE_TC", "FILE_PC", "FILE_SRC")
DISABLED_KEYS = {"FILE_SRC": "FILE_SRC_DISABLED",
                 "FILE_TC": "FILE_TC_DISABLED",
                 "FILE_PC": "FILE_PC_DISABLED"}
TIME_KEYS = ("FILE_TIME", "FILE_TIME_CST")


def _norm(path: str) -> str:
    return os.path.normpath(path).replace(os.sep, "/")


def _to_entry(path: str, work_dir: str) -> str:
    p = _norm(path)
    w = _norm(work_dir)
    if p.lower().startswith(w.lower()):
        p = "$WORK_DIR$" + p[len(w):].lstrip("/")
        return p
    if not os.path.isabs(p):
        return "$WORK_DIR$" + p
    return p


class Entry:
    def __init__(self, path: str, disabled: bool = False, mtime: int | None = None):
        self.path = _norm(path)
        self.disabled = disabled
        self.mtime = mtime


def parse(lines: list, work_dir: str) -> dict:
    """Extract ordered file entries from .hqprj lines.

    Returns {src: [Entry], tc: [Entry], pc: [Entry]} with disabled flags and
    FILE_TIME / FILE_TIME_CST mapping (src times zip against the mixed
    FILE_SRC/FILE_SRC_DISABLED sequence; cst times zip TC group then PC
    group, per the GUI serializer)."""
    out = {"src": [], "tc": [], "pc": []}
    kinds = []
    for ln in lines:
        st = ln.rstrip("\r\n").strip()
        for key in FILE_KEYS:
            dk = DISABLED_KEYS[key]
            if st.startswith(key + "="):
                v = st[len(key) + 1:].strip()
                if v and v != "NONE":
                    kinds.append((key, _resolve(v, work_dir), False))
            elif st.startswith(dk + "="):
                v = st[len(dk) + 1:].strip()
                if v and v != "NONE":
                    kinds.append((key, _resolve(v, work_dir), True))
    # zip times: FILE_TIME pairs with the mixed src sequence (incl. disabled)
    times = []
    csts = []
    for ln in lines:
        st = ln.rstrip("\r\n").strip()
        if st.startswith("FILE_TIME="):
            times.append(st[len("FILE_TIME="):].strip())
        elif st.startswith("FILE_TIME_CST="):
            csts.append(st[len("FILE_TIME_CST="):].strip())
    src_seq = [e for e in kinds if e[0] == "FILE_SRC"]
    tc_seq = [e for e in kinds if e[0] == "FILE_TC"]
    pc_seq = [e for e in kinds if e[0] == "FILE_PC"]

    def _mtime(t):
        return int(t) if t.isdigit() else None

    # zip would silently DROP entries when the time list is short — the
    # exact "GUI shows a wrong file list" corruption this module exists to
    # fix.  Keep every file entry; a missing time becomes None (validate
    # flags it, relayout re-stats the real file).
    for k, (key, path, dis) in enumerate(src_seq):
        t = times[k] if k < len(times) else None
        out["src"].append(Entry(path, dis, _mtime(t) if t is not None else None))
    cst_all = tc_seq + pc_seq
    for k, (key, path, dis) in enumerate(cst_all):
        t = csts[k] if k < len(csts) else None
        bucket = "tc" if key == "FILE_TC" else "pc"
        out[bucket].append(Entry(path, dis, _mtime(t) if t is not None else None))
    return out


def _resolve(v: str, work_dir: str) -> str:
    if v.startswith("$WORK_DIR$"):
        v = v[len("$WORK_DIR$"):]
    p = os.path.join(work_dir, v) if not os.path.isabs(v) else v
    return _norm(p)


def validate(lines: list, work_dir: str, fix: bool = False) -> tuple:
    """Validate the FILE blocks against the GUI serializer invariants.

    Returns (ok, problems, lines_out).  problems: human-readable lines.
    lines_out == lines when ok or not fix; otherwise the re-laid-out file."""
    parsed = parse(lines, work_dir)
    problems: list = []
    # count invariants
    n_src = len(parsed["src"])
    n_time = sum(1 for ln in lines
                 if ln.strip().startswith("FILE_TIME="))
    n_cst = sum(1 for ln in lines
                if ln.strip().startswith("FILE_TIME_CST="))
    n_cst_expect = len(parsed["tc"]) + len(parsed["pc"])
    if n_time != n_src:
        problems.append(f"FILE_TIME 数量 {n_time} != 源文件行数 {n_src}")
    if n_cst != n_cst_expect:
        problems.append(f"FILE_TIME_CST 数量 {n_cst} != 约束文件行数 {n_cst_expect}")
    # mtime agreement
    for bucket, tkey in (("src", "FILE_TIME"), ("tc", "FILE_TIME_CST"),
                         ("pc", "FILE_TIME_CST")):
        for e in parsed[bucket]:
            if e.mtime is None:
                problems.append(f"{tkey} 缺失: {os.path.basename(e.path)}")
            elif os.path.isfile(e.path):
                real = int(os.path.getmtime(e.path))
                if abs(e.mtime - real) > 1:
                    problems.append(f"{tkey} 与文件 mtime 不一致: "
                                    f"{os.path.basename(e.path)} "
                                    f"(记录 {e.mtime} / 实际 {real})")
            else:
                problems.append(f"文件不存在: {e.path}")
    # NONE placeholder presence
    def has_none(key):
        return any(ln.strip() == key + "=NONE" for ln in lines)
    if n_src and not has_none("FILE_SRC") \
            and not any(ln.strip().startswith("FILE_SRC=") for ln in lines):
        problems.append("缺少 FILE_SRC 行（含 NONE 占位）")
    lines_out = lines
    if problems and fix:
        # relayout re-stats every mtime and re-emits block layout — this is
        # what turns the [FIX] reports into actual file content (R11-D01:
        # a fresh project with empty time lists must not be left at 0)
        lines_out = relayout(lines, work_dir)
        ok = not validate(lines_out, work_dir)[1]
    else:
        ok = not problems
    return ok, problems, lines_out


def relayout(lines: list, work_dir: str, parsed: dict | None = None) -> list:
    """Re-lay the FILE blocks per the GUI serializer, keeping every other
    line at its current position (content untouched).  parsed: pre-modified
    entries from the caller (add/remove/... mutate them in memory first)."""
    if parsed is None:
        parsed = parse(lines, work_dir)

    def emit_tc():
        out = []
        for e in parsed["tc"]:
            key = "FILE_TC" if not e.disabled else "FILE_TC_DISABLED"
            out.append(f"{key}={_to_entry(e.path, work_dir)}")
        if not parsed["tc"]:
            # GUI: hqprj2tcl errors out without a FILE_TC object — the
            # serializer always emits the NONE placeholder
            out.append("FILE_TC=NONE")
        return out

    def emit_pc():
        out = []
        for e in parsed["pc"]:
            key = "FILE_PC" if not e.disabled else "FILE_PC_DISABLED"
            out.append(f"{key}={_to_entry(e.path, work_dir)}")
        if not parsed["pc"]:
            out.append("FILE_PC=NONE")
        return out

    def emit_src():
        out = []
        for e in parsed["src"]:
            key = "FILE_SRC" if not e.disabled else "FILE_SRC_DISABLED"
            out.append(f"{key}={_to_entry(e.path, work_dir)}")
        if not any(e for e in parsed["src"] if not e.disabled):
            # GUI: no enabled source -> FILE_SRC=NONE placeholder (kept
            # alongside the disabled lines, as the GUI's serializer emits)
            out.insert(0, "FILE_SRC=NONE")
        return out

    def emit_times():
        # GUI semantics (project-manager.js save block): the mtime is
        # re-statted at save time — stale recorded values self-heal here
        out = []
        for e in parsed["src"]:
            t = (int(os.path.getmtime(e.path)) if os.path.isfile(e.path)
                 else (e.mtime if e.mtime is not None else 0))
            out.append(f"FILE_TIME={t}")
        for bucket in ("tc", "pc"):
            for e in parsed[bucket]:
                t = (int(os.path.getmtime(e.path)) if os.path.isfile(e.path)
                     else (e.mtime if e.mtime is not None else 0))
                out.append(f"FILE_TIME_CST={t}")
        return out

    # strip all FILE_* lines, remember first-insert anchors
    tc_anchor = pc_anchor = src_anchor = time_anchor = None
    top_idx = None  # kept-position of the TOP_MODULE line (GUI clears it
    # when no enabled source remains)
    kept = []
    for ln in lines:
        st = ln.strip()
        if st.startswith("FILE_TC=") or st.startswith("FILE_TC_DISABLED="):
            if tc_anchor is None:
                tc_anchor = len(kept)
            continue
        if st.startswith("FILE_PC=") or st.startswith("FILE_PC_DISABLED="):
            if pc_anchor is None:
                pc_anchor = len(kept)
            continue
        if st.startswith("FILE_SRC=") or st.startswith("FILE_SRC_DISABLED="):
            if src_anchor is None:
                src_anchor = len(kept)
            continue
        if st.startswith(("FILE_TIME=", "FILE_TIME_CST=")):
            if time_anchor is None:
                time_anchor = len(kept)
            continue
        if st.startswith("TOP_MODULE="):
            top_idx = len(kept)
        kept.append(ln)

    ins = {"tc": emit_tc(), "pc": emit_pc(), "src": emit_src(),
           "time": emit_times()}
    # GUI parity: no ENABLED source at all -> FILE_SRC=NONE placeholder and
    # the GUI clears TOP_MODULE (project-manager.js checkAndOutPut block)
    if not any(e for e in parsed["src"] if not e.disabled):
        if top_idx is not None:
            kept[top_idx] = "TOP_MODULE=" + chr(13) + chr(10)
            print("[WARN] 所有源文件均已禁用——TOP_MODULE 已按 GUI 行为清空")
    if tc_anchor is None and pc_anchor is None and src_anchor is None \
            and time_anchor is None:
        # fresh project: append the whole FILE tail in GUI layout order
        tail = ins["tc"] + ins["pc"] + ins["src"] + ins["time"]
        out = kept + tail
        return [ln.rstrip("\r\n") + "\n" for ln in out]
    if time_anchor is None:
        # project has FILE blocks but no time block yet (fresh -new_prj:
        # FILE_SRC/TC/PC exist, FILE_TIME was never written) — the time block
        # goes at EOF per the GUI layout
        time_anchor = len(kept)

    # anchors refer to positions in `kept`; applying from the last anchor
    # backwards keeps earlier anchors valid
    plan = sorted([("time", time_anchor, ins["time"]),
                   ("src", src_anchor, ins["src"]),
                   ("pc", pc_anchor, ins["pc"]),
                   ("tc", tc_anchor, ins["tc"])],
                  key=lambda t: (t[1] is None, -(t[1] or 0)))
    out = kept
    for _name, anchor, block in plan:
        if anchor is None:
            continue
        out = out[:anchor] + block + out[anchor:]
    return [ln.rstrip("\r\n") + "\n" for ln in out]


def add_remove_disable(lines: list, work_dir: str, adds: list,
                       removes: list, disable: list, enable: list,
                       kind_default: str = "src") -> tuple:
    """Apply add/remove/disable/enable operations on parsed entries.

    adds: [(abs_path, kind)] with kind in src/tc/pc; removes/disable/enable:
    [(abs_path, kind)] matched by normalized path.
    Returns (lines_out, report_lines)."""
    parsed = parse(lines, work_dir)
    report = []

    def bucket(kind):
        return parsed[kind]

    for path, kind in adds:
        e = Entry(path)
        if os.path.isfile(path):
            e.mtime = int(os.path.getmtime(path))
        b = bucket(kind)
        if any(x.path == e.path for x in b):
            report.append(f"[skip] 已在工程中: {os.path.basename(path)}")
            continue
        b.append(e)
        report.append(f"[ADD] {kind.upper()}: {os.path.basename(path)}")
    for path, kind in removes:
        b = bucket(kind)
        before = len(b)
        b[:] = [x for x in b if x.path != _norm(path)]
        if len(b) != before:
            report.append(f"[DEL] {kind.upper()}: {os.path.basename(path)}")
        else:
            report.append(f"[WARN] 未找到: {os.path.basename(path)}")
    for path, kind in disable:
        hit = False
        for x in bucket(kind):
            if x.path == _norm(path):
                x.disabled = True
                hit = True
        report.append(("[DIS] " if hit else "[WARN] 未找到(禁用): ")
                      + os.path.basename(path))
    for path, kind in enable:
        hit = False
        for x in bucket(kind):
            if x.path == _norm(path):
                x.disabled = False
                hit = True
        report.append(("[EN] " if hit else "[WARN] 未找到(启用): ")
                      + os.path.basename(path))
    out = relayout(lines, work_dir, parsed=parsed)
    return out, report


def summary(lines: list, work_dir: str) -> str:
    parsed = parse(lines, work_dir)
    out = []
    for kind, label in (("src", "源文件"), ("tc", "时序约束"), ("pc", "物理约束")):
        for e in parsed[kind]:
            flag = " [禁用]" if e.disabled else ""
            out.append(f"  {label}: {os.path.basename(e.path)}{flag}")
    return "\n".join(out)


def read_lines(hqprj: str) -> list:
    with open(hqprj, "r", encoding="utf-8", errors="replace") as f:
        return f.readlines()


def write_lines(hqprj: str, lines: list) -> None:
    # GUI writes CRLF
    text = "".join(lines).replace("\r\n", "\n").replace("\n", "\r\n")
    with open(hqprj, "w", encoding="utf-8", newline="") as f:
        f.write(text)
