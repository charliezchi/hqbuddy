"""HqInsight online logic analyzer: status view, trigger setup, waveform capture."""

import glob
import json
import os
import re
import subprocess
import sys
import tempfile
import threading
import time
import xml.etree.ElementTree as ET


from . import buildman
from . import jtag
from . import probes as probes_mod
from . import stageflow
from . import launcher
from .hqprj_parser import extract_filelist, parse_hqprj
from .utils import wait_process

# sample_type encoding in .hqins [SIGNAL JSON INFO]
SAMPLE_TYPES = {2: "sample", 3: "trigger", 4: "sample+trigger"}


def resolve_insight_project(hqprj_arg: str | None, require_hqins: bool = True) -> dict:
    """Resolve the HqInsight project from a .hqprj path or auto-detection.

    Returns dict with: hqprj, work_dir, hqins_dir, hqins, ddf, top, die, family.
    Exits with an error if the HqInsight project (hqins_run/) is missing,
    unless require_hqins is False (e.g. for -init).
    """
    if hqprj_arg:
        hqprj = hqprj_arg
    else:
        matches = sorted(glob.glob("*.hqprj"))
        if not matches:
            print("Error: no .hqprj file specified and none found in current directory.")
            sys.exit(1)
        hqprj = matches[0]

    if not os.path.isfile(hqprj):
        print(f"Error: file not found: {hqprj}")
        sys.exit(1)

    hqprj = os.path.abspath(hqprj)
    work_dir = os.path.dirname(hqprj)
    info = parse_hqprj(hqprj)
    top = info["top"]
    die = info["die"]
    family = info["family"]
    if not top or not die:
        print("Error: .hqprj 缺少 TOP_MODULE 或 DIE 字段")
        sys.exit(1)

    hqins_dir = os.path.join(work_dir, "hqins_run")
    hqins = os.path.join(hqins_dir, "hq_import.hqins")
    ddf = os.path.join(hqins_dir, "hq_import", f"{top}_insight.ddf")

    if require_hqins and not os.path.isfile(hqins):
        print("Error: 找不到 HqInsight 工程（缺少 hqins_run/hq_import.hqins）。")
        print("Tip: run -insight -init, or configure signals in the HqFpga GUI first.")
        sys.exit(1)

    return {
        "hqprj": hqprj,
        "work_dir": work_dir,
        "hqins_dir": hqins_dir,
        "hqins": hqins,
        "ddf": ddf,
        "top": top,
        "die": die,
        "family": family or "",
    }


def read_hqins(hqins_path: str) -> dict:
    """Parse a .hqins file into {section_name: [lines]} (JSON sections kept raw)."""
    sections = {}
    current = None
    with open(hqins_path, "r", encoding="utf-8") as f:
        for line in f:
            stripped = line.strip()
            if stripped.startswith("[") and stripped.endswith("]"):
                current = stripped[1:-1]
                sections[current] = []
            elif current is not None:
                sections[current].append(line.rstrip("\n"))
    return sections


def _section_value(lines: list, la: str = "0_LA") -> str | None:
    """Extract '0_LA:value' style value from a section's lines."""
    for line in lines:
        stripped = line.strip()
        if stripped.startswith(la + ":"):
            return stripped.split(":", 1)[1].strip()
    return None


def _load_signal_info(proj: dict) -> dict | None:
    """Load [SIGNAL JSON INFO] from the .hqins file."""
    sections = read_hqins(proj["hqins"])
    raw = "\n".join(sections.get("SIGNAL JSON INFO", [])).strip()
    if not raw:
        return None
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return None


def _collect_signals(info: dict) -> list:
    """Flatten normal_signals from [SIGNAL JSON INFO] into a signal list.

    msb/lsb stay the RAW signal range (compare-unit compatibility); the
    registered slice travels separately in slice_msb/slice_lsb."""
    signals = []
    for clk_mod in info.get("module_sample_list", []):
        clk = clk_mod.get("clk_signal_name", "")
        for mod in clk_mod.get("modules_sample_data", []):
            for sig in mod.get("normal_signals", []):
                signals.append({
                    "name": sig["signal_name"],
                    "module": mod.get("module_name", ""),
                    "clk": clk,
                    "msb": sig.get("raw_msb", 0),
                    "lsb": sig.get("raw_lsb", 0),
                    "slice_msb": sig.get("slice_msb"),
                    "slice_lsb": sig.get("slice_lsb"),
                    "sample_type": sig.get("sample_type", 2),
                })
    return signals


def show_status(proj: dict) -> None:
    """Print a summary of the HqInsight project configuration."""
    sections = read_hqins(proj["hqins"])

    depth = _section_value(sections.get("MEMORY DEPTH INFO", []))
    trig_pos = _section_value(sections.get("TRIGGER POSITION", []))

    print(f"Project : {proj['hqins']}")
    print(f"Top     : {proj['top']}   Die: {proj['die']}")
    ddf_depth = None
    if os.path.isfile(proj["ddf"]):
        _m = re.search(r"<depth>(\d+)</depth>",
                       open(proj["ddf"], encoding="utf-8", errors="replace").read())
        ddf_depth = int(_m.group(1)) if _m else None
    depth_txt = depth or "?"
    if ddf_depth is not None and str(ddf_depth) != str(depth):
        depth_txt += f"  (注意: 插桩 bit 实际深度 {ddf_depth}，与 .hqins 不一致——先 -depth {ddf_depth} 对齐)"
    print(f"Depth   : {depth_txt}   Trigger position: {trig_pos or '?'}")
    print()

    info = _load_signal_info(proj)
    signals = _collect_signals(info) if info else []
    if not signals:
        print("Signals : (none)")
    else:
        print(f"Signals : {len(signals)}")
        for sig in signals:
            width = sig["msb"] - sig["lsb"] + 1
            stype = SAMPLE_TYPES.get(sig["sample_type"], str(sig["sample_type"]))
            print(f"  {sig['name']}[{width}b]  clk={sig['clk']}  type={stype}")
    print()

    expr_path = os.path.join(proj["hqins_dir"], "hq_import", "trigger_expr.json")
    if os.path.isfile(expr_path):
        try:
            with open(expr_path, "r", encoding="utf-8") as f:
                expr = json.load(f)
            print("Trigger :")
            for conds in expr.get("conditions", {}).values():
                for cond in conds:
                    for lvl in cond.get("trigger_levels", []):
                        ttype = lvl.get("trigger_type", "")
                        if ttype == "Edge Detector":
                            desc = lvl.get("edge_type", "")
                        elif ttype == "Range":
                            desc = f"RANGE {lvl.get('left_value_v','')}..{lvl.get('right_value_v','')}"
                        else:
                            desc = f"{lvl.get('left_value_type','')} {lvl.get('left_value_v','')}"
                        print(f"  {cond.get('signal_name','?')} {ttype} {desc}")
        except (json.JSONDecodeError, OSError):
            print("Trigger : (unreadable trigger_expr.json)")
    else:
        print("Trigger : (not set)")


# --- Trigger condition setup (-trig) ---

ARITH_OPS = ("EQ", "GT", "LT", "NE", "LE", "GE")
EDGE_OPS = {"RISE": "Rising Edge", "FALL": "Falling Edge", "BOTH": "B Edge", "X": "X"}
# RANGE bound op pairs: CLI token -> (left_op, right_op) written to ddf/json.
# GUI Range dialog allows GT/GE for the left bound and LT/LE for the right.
RANGE_OPS = {"RANGE": ("GT", "LT"),           # open interval
             "RANGE_C": ("GE", "LE"),         # closed interval
             "RANGE_LC": ("GE", "LT"),        # left-closed
             "RANGE_RC": ("GT", "LE")}        # right-closed


def _bits_lsb_first(value: int, width: int) -> str:
    """Binary string, LSB first (ddf operand encoding: 16'd1 -> '1000000000000000')."""
    return bin(value)[2:].zfill(width)[::-1]


def _parse_value(token: str) -> int:
    """Parse an integer literal (decimal or 0x hex)."""
    try:
        return int(token, 0)
    except ValueError:
        print(f"Error: 无效的值: {token}")
        sys.exit(1)


def _parse_value_maybe_wild(token: str) -> tuple:
    """Parse a value that may contain x/X wildcard bits (binary only).

    Returns (value, wild): value has x->0; wild has 1 where the bit is a
    don't-care (hardware compare mask).  Hex (0x-prefix) and decimal are
    returned with wild=0."""
    core = token.replace("_", "")
    if core[:2].lower() == "0x":
        return _parse_value(token), 0
    if any(c in "xX" for c in core):
        if core == "" or any(c not in "01xX" for c in core):
            print(f"Error: invalid wildcard value: {token} "
                  f"(use only 0/1/x, e.g. xxxxx000)")
            sys.exit(1)
        val = int(core.replace("x", "0").replace("X", "0"), 2)
        wild = int(core.replace("x", "1").replace("X", "1"), 2)
        return val, wild
    return _parse_value(token), 0


def parse_trig_expr(tokens: list) -> dict:
    """Parse -trig tokens into a trigger description.

    Returns {conds: [{signal, kind, op, value, lo, hi, negate}],
             combine: 'AND'|'OR'|None, negate_all: bool}.
    kind: 'arith' | 'edge' | 'range'
    """
    negate_all = False
    words = []
    for t in tokens:
        if t == "--negate":
            negate_all = True
        else:
            words.extend(t.split())

    # Split words into conditions on AND/OR
    groups = []
    combine = None
    current = []
    for w in words:
        if w.upper() in ("AND", "OR"):
            if not current:
                print("Error: AND/OR 前缺少条件")
                sys.exit(1)
            groups.append(current)
            if combine and combine != w.upper():
                print("Error: AND 与 OR 不能混用")
                sys.exit(1)
            combine = w.upper()
            current = []
        else:
            current.append(w)
    if current:
        groups.append(current)

    if len(groups) >= 2 and not combine:
        print("Error: 多条件之间需要 AND 或 OR 连接")
        sys.exit(1)
    if not groups:
        print("Error: 触发表达式为空——需要至少一个条件（如 'cnt EQ 5'）。")
        sys.exit(1)

    conds = []
    for g in groups:
        negate = False
        if g and g[0].upper() == "NOT":
            negate = True
            g = g[1:]
        if len(g) < 2:
            print(f"Error: 条件不完整: {' '.join(g)}")
            sys.exit(1)
        signal, op = g[0], g[1].upper()
        if op in ARITH_OPS:
            if len(g) != 3:
                print(f"Error: {op} requires a value: {signal} {op} <value>")
                sys.exit(1)
            val, wild = _parse_value_maybe_wild(g[2])
            conds.append({"signal": signal, "kind": "arith", "op": op,
                          "value": val, "wild": wild, "negate": negate})
        elif op in RANGE_OPS:
            if len(g) != 4:
                print(f"Error: {op} requires two bounds: {signal} {op} <lo> <hi>")
                sys.exit(1)
            conds.append({"signal": signal, "kind": "range", "op": op,
                          "lo": _parse_value(g[2]), "hi": _parse_value(g[3]),
                          "negate": negate})
        elif op in EDGE_OPS:
            if len(g) != 2:
                print(f"Error: {op} takes no value: {signal} {op}")
                sys.exit(1)
            conds.append({"signal": signal, "kind": "edge", "op": op, "negate": negate})
        else:
            print(f"Error: 未知触发算子: {op}")
            print(f"       arithmetic: {'/'.join(ARITH_OPS)}; range: "
                  f"{'/'.join(RANGE_OPS)} lo hi; edge: RISE/FALL/BOTH/X")
            sys.exit(1)

    return {"conds": conds, "combine": combine, "negate_all": negate_all}


def _check_trigger_signals(proj: dict, parsed: dict) -> list:
    """Validate condition signals against .hqins; returns signal info list per cond."""
    info = _load_signal_info(proj)
    signals = _collect_signals(info) if info else []
    result = []
    for cond in parsed["conds"]:
        match = [s for s in signals if s["name"] == cond["signal"]]
        if not match:
            avail = ", ".join(s["name"] for s in signals if s["sample_type"] in (3, 4))
            print(f"Error: 信号不在 HqInsight 工程中: {cond['signal']}（先 -insight -add 登记并 -run+下载）")
            print(f"       trigger-capable signals: {avail or '(none)'}")
            sys.exit(1)
        sig = match[0]
        if sig["sample_type"] not in (3, 4):
            print(f"Error: 信号 {cond['signal']} 是仅采样（sample-only），不能作为触发。")
            print(f"       补救：-del {cond['signal']} 后以 -type both 重新 -add，再 -run + 下载。")
            sys.exit(1)
        if cond["kind"] == "edge" and sig["msb"] != sig["lsb"]:
            print(f"Error: 边沿触发要求 1 位信号: {cond['signal']}（多位总线请改用算术/范围条件，或登记 1 位片选信号）")
            sys.exit(1)
        # LA 比较单元按无符号位串比较：负数/超宽值会被静默写成垃圾位串
        width = sig["msb"] - sig["lsb"] + 1
        if cond["kind"] == "arith":
            v, wild = cond["value"], cond.get("wild", 0)
            if v < 0:
                two = v & ((1 << width) - 1)
                print(f"Error: 触发值 {v} 为负——请改用其二补码值 {two}（{width} 位）。")
                sys.exit(1)
            if v >= (1 << width) or (wild and wild >= (1 << width)):
                print(f"Error: 触发值超出信号 {cond['signal']} 位宽"
                      f"（{width} 位，最大 {(1 << width) - 1}）。")
                sys.exit(1)
        elif cond["kind"] == "range":
            lo, hi = cond["lo"], cond["hi"]
            for label, v in (("下界", lo), ("上界", hi)):
                if v < 0:
                    two = v & ((1 << width) - 1)
                    print(f"Error: 范围{label} {v} 为负——请改用其二补码值 {two}（{width} 位）。")
                    sys.exit(1)
                if v >= (1 << width):
                    print(f"Error: 范围{label} {v} 超出信号 {cond['signal']} 位宽"
                          f"（{width} 位，最大 {(1 << width) - 1}）。")
                    sys.exit(1)
            if lo > hi:
                print(f"Error: 范围下界 {lo} 大于上界 {hi}。")
                sys.exit(1)
        # vacuous constant conditions on an unsigned compare unit (R5-D10):
        # hardware "GT max"/"LT 0" never fire and "GE 0"/"LE max" always fire
        # — the arming looks fine and the capture misleads
        if cond["kind"] == "arith" and not cond.get("wild"):
            op, v = cond["op"], cond["value"]
            vmax = (1 << width) - 1
            if op == "GT" and v >= vmax:
                print(f"Warning: 布防条件恒假——{cond['signal']} {op} {v} 在 "
                      f"{width} 位无符号比较上永不可能为真（最大 {vmax}），"
                      "布防将不会命中；仍写入。")
            if op == "LT" and v <= 0:
                print(f"Warning: 布防条件恒假——{cond['signal']} {op} {v} "
                      "（无符号最小 0），布防将不会命中；仍写入。")
            if op == "GE" and v <= 0:
                print(f"Warning: 布防条件恒真——{cond['signal']} {op} {v} "
                      "（恒成立，布防立即命中）。")
            if op == "LE" and v >= vmax:
                print(f"Warning: 布防条件恒真——{cond['signal']} {op} {v} "
                      "（恒成立，布防立即命中）。")
        result.append(sig)
    return result


def _fold_err(msg):
    print(f"Error: {msg}")
    print("       硬件上每个触发信号只有一个比较单元，同信号多条件无法组合；")
    print("       请改写成单条件，或用跨信号条件表达。")
    sys.exit(1)


def _canon_cond(c: dict) -> dict:
    """Push NOT into the operator: NOT EQ v -> NE v etc.  Edges cannot be
    pushed (NOT RISE is steady-high OR steady-low, NOT 'FALL'), so a negated
    edge condition is an error here."""
    c = dict(c)
    if not c.get("negate"):
        return c
    if c["kind"] == "arith":
        if c["op"] not in ("EQ", "NE"):
            _fold_err(f"信号 {c['signal']} 的 NOT {c['op']} 无法合并为单比较单元")
        c["op"] = "NE" if c["op"] == "EQ" else "EQ"
    elif c["kind"] == "edge":
        _fold_err(f"信号 {c['signal']} 的 NOT {c['op']} 无法合并为单比较单元"
                  f"（NOT 边沿不等价于反向边沿，硬件取反位实测会被丢弃）")
    else:
        _fold_err(f"信号 {c['signal']} 的 NOT RANGE 无法合并为单比较单元")
    c["negate"] = False
    return c


def _fold_same_signal(a: dict, b: dict) -> dict:
    """Fold two conditions on the SAME signal into one compare-unit condition
    (AND/intersection semantics).

    The LA hardware has exactly ONE compare unit per trigger signal, so a
    second condition on the same signal silently replaces the first.  Fold the
    semantically expressible cases and error on the rest."""
    err = _fold_err
    canon = _canon_cond

    def fold_pair(x, y):
        if x["kind"] == "edge" and y["kind"] == "edge":
            if x["op"] == "X":
                return {**y}
            if y["op"] == "X":
                return {**x}
            if x["op"] == "BOTH" or y["op"] == "BOTH" or x["op"] != y["op"]:
                if x["op"] != "BOTH" and y["op"] != "BOTH" and x["op"] != y["op"]:
                    print(f"Note: {x['signal']} 的 {x['op']} + {y['op']} 折叠为 BOTH"
                          f"（硬件无方向组合单元，等效于双沿都触发）")
                return {**x, "op": "BOTH"}
            return {**x}

        if x["kind"] == "edge" or y["kind"] == "edge":
            edge, other = (x, y) if x["kind"] == "edge" else (y, x)
            if other["kind"] == "range":
                err(f"信号 {x['signal']} 的边沿条件与范围条件无法合并")
            post = {"RISE": 1, "FALL": 0, "BOTH": None, "X": None}[edge["op"]]
            if other["op"] != "EQ" or post is None or other["value"] != post:
                err(f"信号 {x['signal']} 的边沿条件与 {other['op']} {other.get('value')} 无法合并（1 位信号上 {edge['op']} 隐含电平={post}）")
            return {**edge}

        if x["kind"] == "range" and y["kind"] == "range":
            lo, hi = max(x["lo"], y["lo"]), min(x["hi"], y["hi"])
            if lo > hi:
                err(f"信号 {x['signal']} 范围条件相交为空：[{x['lo']},{x['hi']}] ∩ [{y['lo']},{y['hi']}]")
            return {**x, "op": "RANGE_C", "lo": lo, "hi": hi}

        if x["kind"] == "range" or y["kind"] == "range":
            rng, pt = (x, y) if x["kind"] == "range" else (y, x)
            lop, rop = RANGE_OPS[rng["op"]]
            v = pt["value"]
            in_lo = rng["lo"] < v or (rng["lo"] == v and lop == "GE")
            in_hi = rng["hi"] > v or (rng["hi"] == v and rop == "LE")
            if pt["op"] == "EQ":
                if in_lo and in_hi:
                    return {**pt}
                err(f"信号 {x['signal']} 条件矛盾：EQ {v} 不在范围 [{rng['lo']},{rng['hi']}] 内")
            err(f"信号 {x['signal']} 的 NE {v} 与范围条件无法合并为单比较单元")

        # arith + arith
        if x["op"] == "EQ" and y["op"] == "EQ":
            if x["value"] != y["value"]:
                err(f"信号 {x['signal']} 条件矛盾：EQ {x['value']} 与 EQ {y['value']} 无法同时成立")
            return {**x}
        if x["op"] == "EQ":
            if y["value"] == x["value"]:
                err(f"信号 {x['signal']} 条件恒假：EQ {x['value']} 且 NE {x['value']}")
            return {**x}
        if y["op"] == "EQ":
            if x["value"] == y["value"]:
                err(f"信号 {x['signal']} 条件恒假：NE {x['value']} 且 EQ {x['value']}")
            err(f"信号 {x['signal']} 的 NE {x['value']} 与 EQ {y['value']} 无法合并为单条件")
        if x["value"] == y["value"]:
            return {**x, "op": "NE"}
        err(f"信号 {x['signal']} 的 NE {x['value']} 与 NE {y['value']} 无法合并为单比较单元条件")

    return fold_pair(canon(a), canon(b))


def _cond_intervals(c: dict) -> "list[tuple] | None":
    """Inclusive integer intervals of an arith/range condition (None bound =
    unbounded).  Returns None for wildcard compares (a masked EQ has no
    interval form) and [] for an empty condition."""
    if c["kind"] == "arith":
        if c.get("wild"):
            return None
        v = c["value"]
        return {"EQ": [(v, v)], "GE": [(v, None)], "GT": [(v + 1, None)],
                "LE": [(None, v)], "LT": [(None, v - 1)],
                "NE": [(None, v - 1), (v + 1, None)]}[c["op"]]
    lop, rop = RANGE_OPS[c["op"]]
    lo = c["lo"] + (1 if lop == "GT" else 0)
    hi = c["hi"] - (1 if rop == "LT" else 0)
    return [(lo, hi)] if lo <= hi else []


def _merge_intervals(a: list, b: list) -> list:
    """Union of two inclusive-interval lists (overlapping or adjacent
    intervals merge into one)."""
    ivs = sorted(a + b, key=lambda t: (t[0] is not None, t[0] or 0))
    out: list = []
    for lo, hi in ivs:
        if out:
            _plo, phi = out[-1]
            if phi is None or (lo is not None and lo - 1 <= phi):
                out[-1] = (out[-1][0],
                           None if (phi is None or hi is None) else max(phi, hi))
                continue
        out.append((lo, hi))
    return out


def _interval_to_cond(base: dict, iv: tuple):
    """Map one inclusive interval back to a single compare-unit condition
    shaped like `base`; returns the string 'TAUT' when it covers everything."""
    lo, hi = iv
    if lo is None and hi is None:
        return "TAUT"
    if lo is not None and hi is not None:
        if lo == hi:
            return {**base, "kind": "arith", "op": "EQ", "value": lo}
        return {**base, "kind": "range", "op": "RANGE_C", "lo": lo, "hi": hi}
    if lo is None:
        return {**base, "kind": "arith", "op": "LE", "value": hi}
    return {**base, "kind": "arith", "op": "GE", "value": lo}


def _fold_same_signal_or(a: dict, b: dict) -> dict:
    """Fold two same-signal conditions under OR (union) semantics.

    The ddf keeps ONE active compare unit per trigger signal, so an OR chain
    listing the same signal twice keeps only the last condition written
    (last-write-wins) — the user's other condition silently disappears.
    Identical conditions dedup; unions one compare unit can express
    (contiguous value intervals, edge widening to BOTH/X) fold; the rest is
    rejected with an explanation."""
    err = _fold_err
    if a.get("negate") or b.get("negate"):
        err(f"信号 {a['signal']} 的带 NOT 条件无法与其他同信号条件做 OR 折叠"
            f"（硬件取反位实测会被丢弃，R25）")
    x, y = _canon_cond(a), _canon_cond(b)

    def same(p, q):
        if p["kind"] != q["kind"]:
            return False
        if p["kind"] == "edge":
            return p["op"] == q["op"]
        if p["kind"] == "arith":
            return (p["op"] == q["op"] and p["value"] == q["value"]
                    and p.get("wild", 0) == q.get("wild", 0))
        return p["op"] == q["op"] and p["lo"] == q["lo"] and p["hi"] == q["hi"]

    if same(x, y):
        return x

    if x["kind"] == "edge" and y["kind"] == "edge":
        if x["op"] == "X" or y["op"] == "X":
            return {**x, "op": "X"}
        if x["op"] == "BOTH" or y["op"] == "BOTH":
            return {**x, "op": "BOTH"}
        print(f"Note: {x['signal']} 的 {x['op']} | {y['op']} 折叠为 BOTH"
              f"（单边沿检测单元可监视双沿）")
        return {**x, "op": "BOTH"}

    if x["kind"] == "edge" or y["kind"] == "edge":
        err(f"信号 {x['signal']} 的边沿条件与电平条件无法在单比较单元内做 OR")

    ia, ib = _cond_intervals(x), _cond_intervals(y)
    if ia is None or ib is None:
        err(f"信号 {x['signal']} 的通配符比较无法与其他同信号条件做 OR 折叠")
    merged = _merge_intervals(ia, ib)
    if not merged:
        err(f"信号 {x['signal']} 的两个条件交集为空")
    if len(merged) > 1:
        err(f"信号 {x['signal']} 的 OR 并集不连续（两个分离的取值区间），"
            f"单比较单元无法表达——请改写成单条件或跨信号条件")
    res = _interval_to_cond(x, merged[0])
    if res == "TAUT":
        err(f"信号 {x['signal']} 的 OR 并集覆盖全部取值——表达式恒真，请简化条件")
    return res


_ARITH_NEGATE = {"EQ": "NE", "NE": "EQ", "GT": "LE", "GE": "LT",
                 "LT": "GE", "LE": "GT"}


def _eliminate_arith_negate(parsed: dict) -> None:
    """Rewrite NOT on arithmetic conditions into the complementary operator.

    R25 board finding (FT091226): a single condition's hardware negate bit is
    dropped downstream (NOT cnt EQ 7 fired at cnt==7, 4/4, while
    trigger_cond.json correctly recorded negate) -- so never send a negated
    arith compare; express it as the complementary op instead.  NOT on
    range/edge has no single-op complement and stays with a warning."""
    for c in parsed.get("conds", []):
        if not c.get("negate"):
            continue
        if c.get("kind") == "arith":
            new_op = _ARITH_NEGATE[c["op"]]
            print(f"Note: NOT {c['signal']} {c['op']} {c['value']} 改写为 "
                  f"{c['signal']} {new_op} {c['value']}（硬件取反位实测会被丢弃）")
            c["op"] = new_op
            c["negate"] = False
        else:
            print(f"Warning: {c['signal']} 上的 NOT（{c.get('op')}）无等价单算子，"
                  f"硬件取反位实测会被丢弃（R25），该条件可能按未取反执行——"
                  f"建议改写为可表达的等价条件")


def collapse_same_signal(parsed: dict) -> dict:
    """Fold same-signal conditions into one compare-unit condition.

    The hardware keeps ONE compare unit per trigger signal: a second
    condition on the same signal silently overwrites the first in the ddf
    (last-write-wins).  AND chains fold by intersection, OR chains by union;
    inexpressible same-signal combinations are rejected instead of silently
    dropping a condition."""
    _eliminate_arith_negate(parsed)
    conds = list(parsed["conds"])
    if len(conds) < 2:
        return parsed
    or_chain = parsed.get("combine") == "OR"
    order, groups = [], {}
    for c in conds:
        key = (c["signal"], c["negate"])
        if key not in groups:
            groups[key] = []
            order.append(key)
        groups[key].append(c)
    # conditions with the same signal but DIFFERENT negate cannot be folded
    seen_sig = {}
    for key in order:
        sig = key[0]
        if sig in seen_sig:
            print(f"Error: 信号 {sig} 同时出现带 NOT 与不带 NOT 的条件，硬件无法组合")
            print("       （每个触发信号只有一个比较单元；跨信号条件不受影响）")
            sys.exit(1)
        seen_sig[sig] = True
    fold = _fold_same_signal_or if or_chain else _fold_same_signal
    new_conds = []
    changed = False
    for key in order:
        group = groups[key]
        cur = group[0]
        for other in group[1:]:
            changed = True
            cur = fold(cur, other)
        new_conds.append(cur)
    if not changed:
        return parsed
    parsed = {**parsed, "conds": new_conds}
    if len(new_conds) == 1:
        parsed["combine"] = None
        parsed["negate_all"] = False
    return parsed


def _write_trigger_expr(proj: dict, parsed: dict, sigs: list) -> None:
    """Write trigger_expr.json (GUI persistence format)."""
    conds_json = []
    for cond, sig in zip(parsed["conds"], sigs):
        width = sig["msb"] - sig["lsb"] + 1
        level = {"trigger_level": 1, "edge_type": "",
                 "left_value_type": "", "left_value_v": "", "left_value_b": "",
                 "right_value_type": "", "right_value_v": "", "right_value_b": ""}
        if cond["kind"] == "arith":
            level["trigger_type"] = "Arithm Comparator"
            level["left_value_type"] = cond["op"]
            level["left_value_v"] = f"{width}'d{cond['value']}"
            level["left_value_b"] = bin(cond["value"])[2:].zfill(width)
        elif cond["kind"] == "range":
            left_op, right_op = RANGE_OPS[cond["op"]]
            level["trigger_type"] = "Range"
            level["left_value_type"] = left_op
            level["left_value_v"] = f"{width}'d{cond['lo']}"
            level["left_value_b"] = bin(cond["lo"])[2:].zfill(width)
            level["right_value_type"] = right_op
            level["right_value_v"] = f"{width}'d{cond['hi']}"
            level["right_value_b"] = bin(cond["hi"])[2:].zfill(width)
        else:
            level["trigger_type"] = "Edge Detector"
            level["edge_type"] = EDGE_OPS[cond["op"]]
        conds_json.append({"signal_name": cond["signal"], "module_name": sig["module"],
                           "trigger_levels": [level]})

    path = os.path.join(proj["hqins_dir"], "hq_import", "trigger_expr.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump({"version": "1.0", "conditions": {"0": conds_json}}, f, indent=2)


def _expr_op_bits(parsed: dict) -> str:
    """expr_op encoding: bit1 = OR combine, bit0 = negate-all."""
    return f"{1 if parsed['combine'] == 'OR' else 0}{1 if parsed['negate_all'] else 0}"


def _write_expression_operation(proj: dict, parsed: dict) -> None:
    """Persist [EXPRESSION OPERATION] into .hqins (section the GUI debugger reads)."""
    sections = read_hqins(proj["hqins"])
    sections["EXPRESSION OPERATION"] = [_expr_op_bits(parsed)]
    parts = []
    for name, lines in sections.items():
        parts.append(f"[{name}]")
        parts.extend(lines)
        parts.append("")
    with open(proj["hqins"], "w", encoding="utf-8") as f:
        f.write("\n".join(parts))


def _write_trigger_cond(proj: dict, parsed: dict, sigs: list) -> None:
    """Write trigger_cond.json (runtime combination expression).

    The .svf generator resolves each operand's hardware compare unit by
    signal_name+module_name (signal_id is symbolic and the expression string is
    GUI bookkeeping); per-operand `operation` codes drive the actual combination:
    bit3 = negate unit, low bits 01 = OR chain, 11 = AND chain.
    """
    n = len(parsed["conds"])
    if n == 1:
        expr, base_op = "B0", 0b00
    else:
        or_eq = parsed["combine"] == "OR"
        expr = "|".join(f"B{i}" for i in range(n)) if or_eq \
            else "&".join(f"B{i}" for i in range(n))
        base_op = 0b101 if or_eq else 0b011

    operands = []
    for i, (cond, sig) in enumerate(zip(parsed["conds"], sigs)):
        op_bits = base_op | (0b1000 if cond["negate"] else 0)
        operands.append({"signal_id": f"B{i}", "signal_name": cond["signal"],
                         "module_name": sig["module"],
                         "negate": "Yes" if cond["negate"] else "No",
                         "operation": format(op_bits, "04b"), "busname": ""})
    if parsed["negate_all"]:
        expr = f"!({expr})"

    path = os.path.join(proj["hqins_dir"], "hq_import", "trigger_cond.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump({"version": "1.0", "conditions": {"0": [{
            "index": "C0", "expression": expr,
            "and_eq": not (parsed["combine"] == "OR"),
            "or_eq": parsed["combine"] == "OR",
            "negate_eq": parsed["negate_all"], "operands": operands}]}}, f, indent=2)
    _write_expression_operation(proj, parsed)


def _write_ddf(proj: dict, parsed: dict, sigs: list) -> None:
    """Update the .ddf comparator blocks (ignore flag, op, mask, operand)."""

    if not os.path.isfile(proj["ddf"]):
        print(f"Warning: .ddf not found, skipped: {proj['ddf']}")
        return

    tree = ET.parse(proj["ddf"])
    root = tree.getroot()
    trigger = root.find("./la_core/trigger")
    if trigger is None:
        print("Warning: no <trigger> section in .ddf, skipped")
        return

    # kind -> ddf type string
    kind_type = {"edge": "EDGE", "arith": "ARITHM", "range": "RANGE"}

    # Active ddf block per trigger signal; edge X ("don't care") activates none,
    # matching observed GUI behavior (all blocks ignore=yes). All trigger-capable
    # signals not used in the current expression get all blocks ignore=yes.
    active = {}
    info = _load_signal_info(proj)
    for s in (_collect_signals(info) if info else []):
        if s["sample_type"] in (3, 4):
            active[f"{s['name']}__INS_{s['module']}__INS0"] = None
    for cond, sig in zip(parsed["conds"], sigs):
        ip_name = f"{cond['signal']}__INS_{sig['module']}__INS0"
        if not (cond["kind"] == "edge" and cond["op"] == "X"):
            active[ip_name] = cond

    for condition in trigger.findall("condition"):
        name = condition.find("./signal/name")
        if name is None:
            continue
        ip_name = name.text
        if ip_name not in active:
            continue  # not a trigger signal we manage; leave untouched
        cond = active[ip_name]
        ctype = condition.findtext("type", "")
        ignore = condition.find("ignore")
        if ignore is None:
            continue
        op_el = condition.find("op")
        if cond is None or ctype != kind_type[cond["kind"]]:
            ignore.text = "yes"
            # restore canonical default op (tool warns on unsupported values)
            if op_el is not None:
                op_el.text = {"EDGE": "RISE", "ARITHM": "EQ", "RANGE": "GE,LE"}.get(ctype, op_el.text)
            continue
        ignore.text = "no"
        sig = sigs[parsed["conds"].index(cond)]
        width = sig["msb"] - sig["lsb"] + 1
        op_el = condition.find("op")
        mask_el = condition.find("mask")
        operand_el = condition.find("operand")
        if cond["kind"] == "arith":
            if op_el is not None:
                op_el.text = cond["op"]
            if mask_el is not None:
                wild = cond.get("wild", 0)
                mask_el.text = (format(wild, f"0{width}b") if wild
                                else "0" * width)
            if operand_el is not None:
                operand_el.text = _bits_lsb_first(cond["value"], width)
        elif cond["kind"] == "range":
            left_op, right_op = RANGE_OPS[cond["op"]]
            if op_el is not None:
                op_el.text = f"{left_op},{right_op}"
            if mask_el is not None:
                mask_el.text = "0" * width
            if operand_el is not None:
                operand_el.text = (f"{_bits_lsb_first(cond['lo'], width)},"
                                   f"{_bits_lsb_first(cond['hi'], width)}")
        else:  # edge: hardware EDGE unit op only accepts RISE/FALL;
            # BOTH edge = RISE with mask bits set (any-direction edge monitor).
            if op_el is not None:
                op_el.text = "FALL" if cond["op"] == "FALL" else "RISE"
            if mask_el is not None:
                mask_el.text = "1" if cond["op"] == "BOTH" else "0"

    tree.write(proj["ddf"], encoding="utf-8", xml_declaration=True)


def write_trigger_files(proj: dict, parsed: dict) -> dict:
    """Validate and write all three trigger files consistently.
    Returns the effective (folded) parsed expression."""
    parsed = collapse_same_signal(parsed)
    sigs = _check_trigger_signals(proj, parsed)
    _write_trigger_expr(proj, parsed, sigs)
    _write_trigger_cond(proj, parsed, sigs)
    _write_ddf(proj, parsed, sigs)
    return parsed


def cmd_trig(proj: dict, tokens: list) -> None:
    """Handle 'hqbuddy -insight -trig ...'."""
    parsed = write_trigger_files(proj, parse_trig_expr(tokens))
    desc = []
    for c in parsed["conds"]:
        prefix = "NOT " if c["negate"] else ""
        if c["kind"] == "arith":
            desc.append(f"{prefix}{c['signal']} {c['op']} {c['value']}")
        elif c["kind"] == "range":
            desc.append(f"{prefix}{c['signal']} {c['op']} {c['lo']} {c['hi']}")
        else:
            desc.append(f"{prefix}{c['signal']} {c['op']}")
    combined = f" {parsed['combine']} ".join(desc) if parsed["combine"] else desc[0]
    if parsed["negate_all"]:
        combined = f"NOT ({combined})"
    print(f"[OK] Trigger condition set: {combined}")


def _trig_wizard(proj: dict) -> None:
    """Interactive wizard for setting a trigger condition."""
    info = _load_signal_info(proj)
    signals = [s for s in (_collect_signals(info) if info else []) if s["sample_type"] in (3, 4)]
    if not signals:
        print("Error: 工程中没有可触发信号（触发至少需要 1 个 -type trigger/both 信号）。")
        sys.exit(1)

    conds = []
    combine = None
    negate_all = False

    while True:
        print("\nTrigger-capable signals:")
        for i, s in enumerate(signals):
            print(f"  {i + 1}. {s['name']}  [{s['msb'] - s['lsb'] + 1}b]")
        choice = input("Select signal number: ").strip()
        try:
            sig = signals[int(choice) - 1]
        except (ValueError, IndexError):
            print("Invalid selection.")
            continue
        width = sig["msb"] - sig["lsb"] + 1

        print("Trigger type: 1. arithmetic  2. edge  3. range")
        tchoice = input("Select type: ").strip()
        if tchoice == "1":
            op = input(f"Operator ({'/'.join(ARITH_OPS)}): ").strip().upper()
            if op not in ARITH_OPS:
                print("Invalid operator.")
                continue
            conds.append(f"{sig['name']} {op} {input('Value: ').strip()}")
        elif tchoice == "2":
            if width != 1:
                print("Edge trigger requires a 1-bit signal.")
                continue
            op = input("Edge (RISE/FALL/BOTH/X): ").strip().upper()
            if op not in EDGE_OPS:
                print("Invalid edge type.")
                continue
            conds.append(f"{sig['name']} {op}")
        elif tchoice == "3":
            lo = input("Lower bound: ").strip()
            hi = input("Upper bound: ").strip()
            conds.append(f"{sig['name']} RANGE {lo} {hi}")
        else:
            print("Invalid type.")
            continue

        if input("Negate this condition? (y/N): ").strip().lower() == "y":
            conds[-1] = "NOT " + conds[-1]

        if len(conds) >= 2:
            break
        if input("Add another condition? (y/N): ").strip().lower() != "y":
            break
        combine = input("Combine with (AND/OR): ").strip().upper()
        if combine not in ("AND", "OR"):
            print("Invalid; using AND.")
            combine = "AND"

    if len(conds) == 2:
        tokens = [conds[0], combine, conds[1]]
    else:
        tokens = [conds[0]]
    if input("Negate the whole expression? (y/N): ").strip().lower() == "y":
        tokens.append("--negate")

    parsed = parse_trig_expr(tokens)
    write_trigger_files(proj, parsed)
    print(f"[OK] Trigger condition set ({len(parsed['conds'])} condition(s)).")


# --- Waveform capture (-capture) ---

# cable.exe --outTDO values seen from hq_ins (die mapping unknown; 366 verified on SA30K)
CAPTURE_OUT_TDO = "366"


def _tcl_path(path: str) -> str:
    """Forward-slash absolute path for tcl consumption."""
    return os.path.abspath(path).replace(os.sep, "/")


def _print_tail(out, n: int = 15) -> None:
    """Print the last n non-empty lines of captured subprocess output."""
    if isinstance(out, bytes):
        out = out.decode("utf-8", errors="replace")
    lines = [l for l in (out or "").splitlines() if l.strip()]
    if not lines:
        return
    print("  --- tool output tail ---")
    for l in lines[-n:]:
        print("  " + l)


def _run_hqfpga_cmds(hqfpga_exe: str, cmds: list, cwd: str,
                     timeout: int = 600) -> None:
    """Run hqfpga.exe -cmd with a temporary tcl; abort on abnormal exit.

    Output is captured instead of echoed: the tail is printed on failure,
    a hung tool times out, and TCL-level errors that still exit 0 (e.g.
    'invalid command name') abort instead of failing silently."""

    tcl = "\n".join(cmds) + "\nexit\n"
    with tempfile.NamedTemporaryFile("w", suffix=".tcl", delete=False, encoding="gbk") as f:
        f.write(tcl)
        tcl_path = f.name
    try:
        try:
            proc = subprocess.run([hqfpga_exe, "-cmd", tcl_path], cwd=cwd,
                                  capture_output=True, text=True,
                                  errors="replace", timeout=timeout)
        except subprocess.TimeoutExpired as e:
            print(f"Error: hqfpga.exe 超时（{timeout}s）——工具挂起或设计过大。")
            _print_tail(e.stdout)
            sys.exit(1)
    finally:
        try:
            os.unlink(tcl_path)
        except OSError:
            pass
    out = (proc.stdout or "") + (proc.stderr or "")
    if proc.returncode != 0:
        print(f"Error: hqfpga.exe 异常退出（code {proc.returncode}）。")
        _print_tail(out)
        sys.exit(1)
    if re.search(r"(?im)^\s*(error\s*[:：]|invalid command name)", out):
        print("Error: hqfpga TCL 层报错（输出尾部见下）。")
        _print_tail(out)
        sys.exit(1)


def _play_svf(cable_exe: str, svf_path: str, timeout: int = 120,
              session: str | None = None, label: str = "play") -> list:
    """Play an SVF via cable.exe under the machine-global JTAG lock; return
    the Received:TDO values.  Delegates to jtag.play_svf, which aborts when
    the shared svf.log was not refreshed by THIS play (read-only install dir,
    or a concurrent cable user) — stale TDO would otherwise spin to a
    misleading timeout.  session: optional transaction-log directory."""
    return jtag.play_svf(cable_exe, svf_path, out_tdo=CAPTURE_OUT_TDO,
                         timeout=timeout, session=session, label=label)


def _capture_expr_op(cond_path: str) -> str:
    """expr_op for la_set_trig_cond: bit1 = OR combine, bit0 = negate-all."""
    try:
        with open(cond_path, "r", encoding="utf-8") as f:
            cond = json.load(f)
        first = cond["conditions"]["0"][0]
        return f"{1 if first.get('or_eq') else 0}{1 if first.get('negate_eq') else 0}"
    except (OSError, json.JSONDecodeError, KeyError, IndexError):
        return "00"


def _is_combined_trigger(cond_path: str) -> bool:
    """Combined trigger (is_ct) = two or more condition operands in trigger_cond.json."""
    try:
        with open(cond_path, "r", encoding="utf-8") as f:
            cond = json.load(f)
        return len(cond["conditions"]["0"][0].get("operands", [])) >= 2
    except (OSError, json.JSONDecodeError, KeyError, IndexError):
        return False


def _parse_status(raw_hex: str, status_bits: int) -> tuple:
    """Parse la_status TDO value -> (overflow, done, pointer).

    Replicates the HqInsight GUI's parse_status exactly: take the low
    status_bits of the value as a binary string, reverse it, then
    [0]=overflow, [1]=done, int([2:], 2)=pointer (i.e. the pointer field
    is read out bit-reversed by the hardware).
    status_bits = mem_depth.bit_length() - 1 + 2 (e.g. 12 for depth 1024).
    """
    bin_str = format(int(raw_hex, 16), f"0{status_bits}b")[-status_bits:]
    rev = bin_str[::-1]
    return (rev[0] == "1", rev[1] == "1", int(rev[2:] or "0", 2))


def _write_force_ddf(proj: dict) -> str:
    """Write <prefix>_force.ddf: all trigger blocks ignored (= trigger always fires)."""

    force_ddf = proj["ddf"].replace(".ddf", "_force.ddf")
    tree = ET.parse(proj["ddf"])
    for ignore in tree.getroot().iter("ignore"):
        ignore.text = "yes"
    tree.write(force_ddf, encoding="utf-8", xml_declaration=True)
    return force_ddf


def _verify_vcd(vcd_path: str, offset: int, force: bool,
                session: str | None, overflow: bool = False,
                pointer: int | None = None) -> dict:
    """Self-check a captured VCD (P0-A7 decode stage): sample timestamps
    contiguous, trigger_event marker at the armed offset (skipped in -force
    mode), clock present.  Returns the verdict dict; decode failures print
    [FAIL] and exit.

    Board-calibrated semantics (R4-D1): the trigger_event marker is WRITER-
    SYNTHESIZED at the armed offset — in overflow (tail-window) dumps its
    position does NOT identify the hardware trigger sample, so overflow
    verdicts report the marker semantics explicitly instead of claiming
    'trigger @128' as hardware truth."""
    try:
        with open(vcd_path, "r", encoding="utf-8", errors="replace") as f:
            lines = f.read().splitlines()
    except OSError as e:
        print(f"Error: VCD 无法读取: {e}")
        sys.exit(1)

    codes = {}
    i = 0
    while i < len(lines):
        parts = lines[i].split()
        if len(parts) >= 5 and parts[0] == "$var":
            codes[parts[3]] = " ".join(parts[4:-1])
        if parts and parts[0] == "$enddefinitions":
            break
        i += 1

    def code_of(name):
        return next((c for c, n in codes.items() if n == name), None)

    clk_code = code_of("clock_cycle")
    trig_code = code_of("trigger_event")

    # walk value changes; sample k = the changes emitted at timestamp #k
    # (real dump_vcd layout: $dumpvars at #0 carries the first sample).
    # Snapshot k is appended when the NEXT # line (or EOF) is reached.
    times: list = []
    clk_vals: list = []
    trig_vals: list = []
    values: dict = {}
    cur_t = 0
    pending = False

    xsnap = 0

    def _snap():
        nonlocal xsnap
        times.append(cur_t)
        clk_vals.append(values.get(clk_code) if clk_code else None)
        trig_vals.append(values.get(trig_code) if trig_code else None)
        # R5-D4: a capture whose sampled scalars read x for most samples means
        # the JTAG frame was not ready (or a first-dump race) — the waveform
        # is garbage even though the timestamps look fine
        if any(v is not None and "x" in v.lower() for v in
               (values.get(clk_code), values.get(trig_code))):
            xsnap += 1

    for line in lines[i:]:
        line = line.strip()
        if not line or line.startswith("$"):
            continue
        if line.startswith("#"):
            if pending:
                _snap()
                pending = False
            cur_t = int(line[1:])
        elif line.startswith("b"):
            b, _, code = line.partition(" ")
            values[code] = b[1:]
            pending = True
        elif line[0] in "01xz":
            values[line[1:]] = line[0]
            pending = True
    if pending:
        _snap()

    verdict = {"vcd": vcd_path, "samples": len(times),
               "trigger_offset_expected": offset, "force": force,
               "verified": False, "reason": None}

    if len(times) < 2:
        verdict["reason"] = f"样本数不足 ({len(times)})"
        print(f"Warning: VCD 未验证: {verdict['reason']}（标记为未验证）")
        jtag.write_report(session, "vcd_verify.json", verdict)
        return verdict

    gaps = [b - a for a, b in zip(times, times[1:])]
    if not all(g == 1 for g in gaps):
        bad = [(k, gaps[k]) for k in range(len(gaps)) if gaps[k] != 1][:5]
        verdict["reason"] = f"时间戳不连续: {bad}（采样丢失或解码错位）"
        print(f"Error: VCD 解码校验失败——{verdict['reason']}。")
        jtag.write_report(session, "vcd_verify.json", verdict)
        print("[FAIL] decode")
        sys.exit(1)

    # R5-D4: garbage-data detection BEFORE trigger semantics — a capture
    # whose sampled scalars read x for most samples means the JTAG frame
    # was not ready (or a first-dump race); the waveform is unusable
    if len(times) >= 10 and xsnap > len(times) * 0.5:
        verdict["verified"] = False
        verdict["reason"] = (f"采样标量大量为 x（{xsnap}/{len(times)} 样本）——"
                             "JTAG 帧未就绪或首次抓取时序竞争，波形不可信；重试一次。")
        print(f"Error: VCD 解码校验失败——{verdict['reason']}")
        jtag.write_report(session, "vcd_verify.json", verdict)
        print("[FAIL] decode")
        sys.exit(1)

    trig_idx = [k for k, v in enumerate(trig_vals) if v == "1"] if trig_code else []
    verdict["trigger_idx"] = trig_idx
    if not force and trig_code is not None:
        # real LA semantics (board-verified): trigger_event is 0 for the
        # pre-trigger window, then HELD at 1 from the trigger sample (== the
        # armed offset) to the end of the window; the trailing re-dump
        # artifact re-emits the same value at the last timestamp.
        if not trig_idx:
            verdict["reason"] = "trigger_event 从未置 1（板上可能不是本次构建或条件未布防）"
            print(f"Error: VCD 解码校验失败——{verdict['reason']}。")
            jtag.write_report(session, "vcd_verify.json", verdict)
            print("[FAIL] decode")
            sys.exit(1)
        if trig_idx[0] != offset:
            verdict["reason"] = (f"触发位置 {trig_idx[0]} != 布防偏移 {offset}"
                                 "（采样顺序或 offset 解码错位）")
            print(f"Error: VCD 解码校验失败——{verdict['reason']}。")
            jtag.write_report(session, "vcd_verify.json", verdict)
            print("[FAIL] decode")
            sys.exit(1)
        dropped = [k for k in range(trig_idx[0], len(trig_vals))
                   if trig_vals[k] != "1"]
        if dropped:
            verdict["reason"] = (f"trigger_event 在触发后回落（首个回落样本 {dropped[0]}）"
                                 "——采样顺序或解码错位")
            print(f"Error: VCD 解码校验失败——{verdict['reason']}。")
            jtag.write_report(session, "vcd_verify.json", verdict)
            print("[FAIL] decode")
            sys.exit(1)

    verdict["verified"] = True
    if overflow:
        # the marker is writer-synthesized at the armed offset; in an
        # overflow tail-window it does NOT identify the hardware trigger
        # sample (R4-D1 board finding: armed-value occurrences depend on the
        # free-running design, trigger position is only derivable from the
        # pointer).  Report marker semantics honestly.
        verdict["marker_semantics"] = "writer-synthesized (overflow tail window)"
        pos = ""
        if pointer is not None:
            verdict["hardware_trigger_pos_est"] = (offset - pointer) % len(times) \
                if len(times) else None
            pos = f"，触发样本位置估算 (offset-pointer)%N = {verdict['hardware_trigger_pos_est']}"
        print(f"[OK] VCD verified: {len(times)} samples (offset {offset}), 时间戳连续")
        print(f"     [NOTE] overflow 尾窗：trigger_event 标记为写出端按布防偏移注入"
              f"{pos}——标记位置不等于硬件触发样本位置。")
    else:
        where = f", trigger @{trig_idx[0]}" if trig_idx else ""
        print(f"[OK] VCD verified: {len(times)} samples{where} (offset {offset}), "
              "时间戳连续")
    jtag.write_report(session, "vcd_verify.json", verdict)
    return verdict


def run_capture(proj: dict, timeout: int, force: bool, out_prefix: str | None = None) -> None:
    """Handle 'hqbuddy -insight -capture': arm trigger, wait, read waveform, dump VCD."""


    version = launcher.require_hqfpga_version()
    hqfpga_exe = version["hqfpga_path"]
    cable_exe = version["cable_path"]
    if not version.get("has_cable") or not os.path.isfile(cable_exe):
        print(f"Error: cable.exe not found in {version['path']}")
        sys.exit(1)

    # every capture is a logged JTAG session (arm/status/dump SVFs, cable
    # output, TDO values, verification verdicts all preserved for reproduction)
    session = jtag.session_dir(proj, "capture")

    import_dir = os.path.join(proj["hqins_dir"], "hq_import")
    prefix = out_prefix or os.path.join(import_dir, f"{proj['top']}_insight")
    # dump_vcd resolves -out_path_prefix against hqfpga's cwd and crashes
    # (exit -1) when the target directory doesn't exist -- absolutize and
    # create the directory ourselves, with a clean error on failure.
    prefix = os.path.abspath(prefix)
    prefix_dir = os.path.dirname(prefix)
    if not os.path.isdir(prefix_dir):
        try:
            os.makedirs(prefix_dir, exist_ok=True)
        except OSError as e:
            print(f"Error: -o 输出目录无法创建: {prefix_dir} ({e})")
            sys.exit(1)
    cond_path = os.path.join(import_dir, "trigger_cond.json")
    if not os.path.isfile(cond_path):
        print("Error: 尚未设置触发条件——先执行 -insight -trig。")
        sys.exit(1)
    if not os.path.isfile(proj["ddf"]):
        print(f"Error: .ddf not found: {proj['ddf']}")
        sys.exit(1)

    # Programmed-build identity check (P0-A7): -program records what was
    # downloaded; a capture on a board running a DIFFERENT build is garbage.
    stamp_path_prog = os.path.join(import_dir, ".programmed_stamp")
    bit_paths = glob.glob(os.path.join(import_dir, "hqins_impl", "*.bin"))
    prog_match = False
    if os.path.isfile(stamp_path_prog) and bit_paths:
        try:
            prog = json.load(open(stamp_path_prog, "r", encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            prog = None
        if prog:
            import hashlib
            newest_bit_path2 = max(bit_paths, key=os.path.getmtime)
            h_now = hashlib.sha256(open(newest_bit_path2, "rb").read()).hexdigest()
            prog_match = (h_now == prog.get("bin_sha256"))
            if not prog_match:
                print(f"Warning: 板上编程记录是 build {prog.get('build_id')}，"
                      f"但当前 hqins_impl 最新 bin 与其不符（可能已重新 -run 未重新 -program）。")
                print("         板上运行的很可能不是本工程当前位流，触发/抓波结果不可信；"
                      "先 -insight -program 重新下载。")
                print("         注意：布防/抓波使用的是当前 ddf 的采样周期与触发位置——")
                print("         若与板上旧构建不一致，VCD 时间轴与触发索引都会失真。")

    # Bit-freshness warning (stamp-file based): -trig/-capture also rewrite
    # .hqins, so raw mtime comparison against .hqins false-positives.  -run
    # records the newest impl-bin mtime in .bit_stamp; -capture compares it
    # with the newest bin now on disk (stale bin => warn) .
    stamp_path = os.path.join(import_dir, ".bit_stamp")
    if bit_paths and os.path.isfile(stamp_path):
        try:
            stamp_bit_mtime = float(open(stamp_path).read().strip() or 0)
        except ValueError:
            stamp_bit_mtime = 0
        newest_bit = max(os.path.getmtime(b) for b in bit_paths)
        # -program recorded the exact downloaded hash: when it still matches
        # the newest bin, the board runs THIS build and the mtime heuristic
        # (which cannot know about -program) must not cry stale.
        if newest_bit > stamp_bit_mtime + 1 and not prog_match:
            print("Warning: hqins_impl 里有比上次下载更新的 bin——先重新 -cable 下载再验收。")
        # Bit identity check (C6 finding): a wrong/stale bit on the board
        # silently never fires; compare the bitstream header design name
        # against the project top before trusting any capture.
        newest_bit_path = max(bit_paths, key=os.path.getmtime)
        try:
            from .downloader import read_bitstream_header
            hdr = read_bitstream_header(newest_bit_path)
        except OSError:
            hdr = None
        if hdr and hdr.get("design") and hdr["design"] != proj.get("top"):
            print(f"Warning: 位流头 design={hdr['design']} 与工程顶层 "
                  f"{proj.get('top')} 不符——板上可能不是本工程的位流，"
                  f"触发/抓波结果不可信。先重新 -run + 下载。")
    elif bit_paths and not os.path.isfile(stamp_path_prog):
        print("Note: 无 .bit_stamp 基线（本工程尚未用新版 hqbuddy 跑过 -run），")
        print("      位流过期预警未启用。跑一次 -insight -run 即可建立基线。")

    sections = read_hqins(proj["hqins"])
    depth = int(_section_value(sections.get("MEMORY DEPTH INFO", [])) or 1024)
    # Storage-architecture guard (R32): the instrumented bit's real depth lives
    # in the ddf (<depth>N</depth>); -run does NOT consume the .hqins depth yet,
    # so a mismatch means capture would silently produce misplaced data.
    if os.path.isfile(proj["ddf"]):
        ddf_txt = open(proj["ddf"], encoding="utf-8", errors="replace").read()
        m_ddf_depth = re.search(r"<depth>(\d+)</depth>", ddf_txt)
        if m_ddf_depth:
            ddf_depth = int(m_ddf_depth.group(1))
            if ddf_depth != depth:
                print(f"Error: .hqins 深度 ({depth}) 与插桩 bit 实际深度 ({ddf_depth}, "
                      f"见 ddf) 不一致——-run 尚未消费 .hqins 深度，此时抓取会静默错位。"
                      f"先 `-insight -depth {ddf_depth}` 对齐，或等待深度链路打通。")
                sys.exit(1)
    m_ddf_win = None
    if os.path.isfile(proj["ddf"]):
        m_ddf_win = re.search(r"<window_num>(\d+)</window_num>", ddf_txt)
    hqins_win = int(_section_value(sections.get("TRIGGER MULTI-WINDOW", [])) or 1)
    if m_ddf_win and hqins_win != int(m_ddf_win.group(1)):
        print(f"Error: 多窗口 (.hqins windows={hqins_win}) 的布防/轮询/dump 尚未实现"
              f"（ddf window_num={m_ddf_win.group(1)}）——继续抓取会按单窗口静默错读。")
        sys.exit(1)
    if hqins_win > 1:
        # 数量一致也拒绝：布防/轮询/dump 全链路硬编码单窗口，抓了必错读
        print(f"Error: 多窗口 (windows={hqins_win}) 的布防/轮询/dump 尚未实现"
              "——继续抓取会按单窗口静默错读。")
        print("       先 `hqbuddy -insight -windows 1`（随后 -run 重建并重新下载）再抓取。")
        sys.exit(1)
    status_bits = depth.bit_length() - 1 + 2
    offset = int(_section_value(sections.get("TRIGGER POSITION", [])) or 0)
    expr_op = _capture_expr_op(cond_path)
    is_ct = _is_combined_trigger(cond_path)

    # Signal-set freshness: warn when .hqins signals differ from the set the
    # on-board bit was built with (R25: silent misplaced data view otherwise).
    sig_stamp_path = os.path.join(import_dir, ".bit_signals")
    info = _load_signal_info(proj)
    if info is not None and os.path.isfile(sig_stamp_path):
        now = sorted(f"{s['name']}:{s['msb']}:{s['lsb']}"
                     for s in _collect_signals(info))
        try:
            built = [l for l in open(sig_stamp_path).read().splitlines() if l]
        except OSError:
            built = []
        if built and now != built:
            only_now = [s for s in now if s not in built]
            only_built = [s for s in built if s not in now]
            print("Warning: .hqins 信号集与插桩 bit 不一致"
                  f"（多: {only_now or '-'} / 少: {only_built or '-'}）——"
                  "新信号在板上不存在、被删信号读数错位，读数不可信；"
                  "先 -insight -run 并重新下载，且布防上下文随信号集变化，"
                  "下载后必须重新 -trig 再 -capture！")

    if force:
        ddf = _write_force_ddf(proj)
    else:
        ddf = proj["ddf"]

    def svf(name):
        return os.path.join(import_dir, name)

    gen = "insight.svf_generator"
    common = f"-la_num 1 -la_idx 0 -is_multi_window False"

    if is_ct:
        trig_args = (f"-is_continuous False -is_ct True -expr_op {expr_op} "
                     f"-ct_no C0 -cond_path {{{_tcl_path(cond_path)}}}")
    else:
        trig_args = f"-is_continuous False -is_ct False -expr_op {expr_op}"

    # 1. Arm the trigger
    _run_hqfpga_cmds(hqfpga_exe, [
        f"{gen}.start -svf_file_path {{{_tcl_path(svf('arm.svf'))}}} "
        f"-device_die {proj['die']} -ddf_file {{{_tcl_path(ddf)}}}",
        f"{gen}.jtag_detect",
        f"{gen}.la_reset {common}",
        f"{gen}.la_offset {common} -offset {offset}",
        f"{gen}.la_set_trig_cond {common} {trig_args}",
        f"{gen}.la_reset {common}",
        f"{gen}.write",
    ], cwd=proj["hqins_dir"])  # la_set_trig_cond resolves probe values relative to cwd; must be hqins_run (GUI convention)
    _play_svf(cable_exe, svf("arm.svf"), session=session, label="arm")
    print("[OK] Trigger armed.")

    # 2. Wait for the trigger (status done bit), unless -force
    _run_hqfpga_cmds(hqfpga_exe, [
        f"{gen}.start -svf_file_path {{{_tcl_path(svf('status.svf'))}}} "
        f"-device_die {proj['die']} -ddf_file {{{_tcl_path(ddf)}}}",
        f"{gen}.la_status {common}",
        f"{gen}.write",
    ], cwd=proj["hqins_dir"])  # la_set_trig_cond resolves probe values relative to cwd; must be hqins_run (GUI convention)

    overflow, pointer = False, 0
    if force:
        print("[OK] Force trigger, capturing immediately.")
    else:
        print(f"Waiting for trigger (timeout {timeout}s, Ctrl-C to abort)...")
        deadline = time.time() + timeout
        while True:
            time.sleep(0.5)
            tdo = _play_svf(cable_exe, svf("status.svf"), session=session,
                            label="status")
            if len(tdo) >= 2:
                overflow, done, pointer = _parse_status(tdo[1], status_bits)
                if done:
                    print(f"[OK] Triggered (pointer={pointer}, overflow={overflow}).")
                    break
            if time.time() >= deadline:
                print(f"Error: 触发超时（{timeout}s）——加 -force 可立即抓取当前波形。")
                sys.exit(1)

    # 3. Read status + waveform (only 'pointer' words if the buffer never wrapped)
    limit = depth if (force or overflow) else max(pointer, 1)
    _run_hqfpga_cmds(hqfpga_exe, [
        f"{gen}.start -svf_file_path {{{_tcl_path(svf('dump.svf'))}}} "
        f"-device_die {proj['die']} -ddf_file {{{_tcl_path(ddf)}}}",
        f"{gen}.la_status {common}",
        f"{gen}.write",
        f"{gen}.la_waveform {common} -limit {limit}",
        f"{gen}.write",
    ], cwd=proj["hqins_dir"])  # la_set_trig_cond resolves probe values relative to cwd; must be hqins_run (GUI convention)
    tdo = _play_svf(cable_exe, svf("dump.svf"), session=session, label="dump")

    # TDO lines: the first two are status words (short hex), the rest are
    # waveform words whose hex length depends on the LA data width (do NOT
    # hardcode a length — narrow designs read back short words).
    def _is_hex(v: str) -> bool:
        return bool(v) and all(c in "0123456789abcdefABCDEF" for c in v)
    header = list(tdo[:2])
    data = [v for v in tdo[2:] if _is_hex(v)]
    if len(set(len(v) for v in data)) > 1:
        widths = sorted({len(v) for v in data})
        print(f"Error: 波形字位宽不一致（出现 {widths} 多种十六进制长度）——"
              f"JTAG 帧错位或 TDO 数量不符（期望 {limit}，实际 {len(data)}）。")
        jtag._log(session, "transactions.log",
                  f"WAVEFORM WIDTH MIX: {widths} expected_count={limit} got={len(data)}")
        print(f"       会话日志: {session}")
        print("[FAIL] tdo")
        sys.exit(1)
    if not force and len(tdo) >= 2:
        overflow, done, pointer = _parse_status(tdo[1], status_bits)
    if len(data) < limit:
        print(f"Error: 波形字数不符：期望 {limit}，实际 {len(data)}。")
        sys.exit(1)
    while len(header) < 2:
        header.insert(0, "0")
    tdo_path = os.path.join(import_dir, "tdo_data.txt")
    with open(tdo_path, "w", encoding="utf-8") as f:
        f.write("\n".join(header + data[:limit]) + "\n")

    # 4. Convert to VCD
    _run_hqfpga_cmds(hqfpga_exe, [
        f"{gen}.start -svf_file_path {{{_tcl_path(svf('vcd.svf'))}}} "
        f"-device_die {proj['die']} -ddf_file {{{_tcl_path(proj['ddf'])}}}",
        f"{gen}.dump_vcd {common} -tdo_path {{{_tcl_path(tdo_path)}}} -window_num 1 "
        f"-is_hier True -out_path_prefix {{{_tcl_path(prefix)}}} "
        f"-diff_info {overflow}|{pointer}",
    ], cwd=proj["hqins_dir"])  # la_set_trig_cond resolves probe values relative to cwd; must be hqins_run (GUI convention)

    vcd = f"{prefix}_0_ww.vcd"
    if not os.path.isfile(vcd):
        print("Error: VCD 未生成（dump_vcd 静默失败）。")
        print(f"       会话日志: {session}")
        print("[FAIL] decode")
        sys.exit(1)
    print(f"[OK] Waveform captured: {vcd}")
    _verify_vcd(vcd, offset, force, session, overflow=overflow,
                pointer=pointer if overflow else None)
    summarize_vcd(vcd)


def summarize_vcd(vcd_path: str) -> None:
    """Print a summary of a captured VCD: signals and values at the trigger moment."""
    try:
        with open(vcd_path, "r", encoding="utf-8", errors="replace") as f:
            lines = f.read().splitlines()
    except OSError:
        return

    codes = {}  # code -> (name, width)
    i = 0
    while i < len(lines):
        parts = lines[i].split()
        if len(parts) >= 5 and parts[0] == "$var":
            width = int(parts[2])
            codes[parts[3]] = (" ".join(parts[4:-1]), width)
        if parts and parts[0] == "$enddefinitions":
            break
        i += 1

    # scan value changes; find first 0->1 of trigger_event
    values = {}
    time_now = 0
    trig_time = None
    trig_code = None
    for code, (name, _) in codes.items():
        if name == "trigger_event":
            trig_code = code
    for line in lines[i:]:
        if line.startswith("#"):
            time_now = int(line[1:])
        elif line.startswith("b"):
            b, _, code = line.partition(" ")
            values[code] = b[1:]
        elif line and line[0] in "01xz":
            values[line[1:]] = line[0]
            if trig_code and line[1:] == trig_code and line[0] == "1" and trig_time is None:
                trig_time = time_now

    print(f"Signals ({len(codes)}):")
    for code, (name, width) in codes.items():
        print(f"  {name} [{width}b]")
    if trig_time is not None:
        # values at the trigger moment are not fully tracked here; re-scan up to trig_time
        values.clear()
        time_now = 0
        for line in lines[i:]:
            if line.startswith("#"):
                time_now = int(line[1:])
                if time_now > trig_time:
                    break
            elif line.startswith("b"):
                b, _, code = line.partition(" ")
                values[code] = b[1:]
            elif line and line[0] in "01xz":
                values[line[1:]] = line[0]
        print(f"Trigger at #{trig_time}:")
        for code, (name, width) in codes.items():
            if name == "trigger_event":
                continue
            v = values.get(code)
            if v is not None:
                pv = hex(int(v, 2)) if set(v) <= {"0", "1"} else v
                print(f"  {name} = {v} ({pv})" if pv != v else f"  {name} = {v}")
    else:
        print("Error: VCD 中未找到触发时刻。")


# --- Instrumented implementation (-run) ---

def _storage_params(proj: dict) -> dict:
    """Collect storage-architecture params from .hqins (manifest inputs)."""
    sections = read_hqins(proj["hqins"])
    freq_raw = _section_value(sections.get("CLOCK FREQUENCY", []), la="")
    return {
        "depth": int(_section_value(sections.get("MEMORY DEPTH INFO", [])) or 1024),
        "windows": int(_section_value(sections.get("TRIGGER MULTI-WINDOW", [])) or 1),
        "offset": int(_section_value(sections.get("TRIGGER POSITION", [])) or 0),
        "level": int(_section_value(sections.get("TRIGGER LEVEL", [])) or 1),
        "freq_mhz": float(freq_raw) if freq_raw else None,
    }


def _probe_fp_list(proj: dict) -> list:
    """Ordered probe selection fingerprint (manifest inputs)."""
    info = _load_signal_info(proj)
    sigs = _collect_signals(info) if info else []
    return [{"name": s["name"], "module": s["module"], "msb": s["msb"],
             "lsb": s["lsb"], "sample_type": s["sample_type"], "clk": s["clk"]}
            for s in sigs]


def _rewrite_hqins_section_value(proj: dict, section: str, value: str) -> None:
    sections = read_hqins(proj["hqins"])
    sections[section] = [value]
    parts = []
    for name, lines in sections.items():
        parts.append(f"[{name}]")
        parts.extend(lines)
        parts.append("")
    with open(proj["hqins"], "w", encoding="utf-8") as f:
        f.write("\n".join(parts))


def _extract_sdc_periods(sdc_files: list) -> dict:
    """Parse create_clock periods (ns) from SDC files -> {clock_name: period}.

    Matches both '-name X -period P' and '-period P -name X'; also accepts a
    bare period with get_ports target (clock named after the port)."""
    periods: dict = {}
    for f in sdc_files:
        if not os.path.isfile(f):
            continue
        txt = open(f, "r", encoding="utf-8", errors="replace").read()
        for m in re.finditer(
                r"create_clock\s+([^#\n]*)", txt):
            spec = m.group(1)
            name = None
            period = None
            port = None
            mn = re.search(r"-name\s+(\S+)", spec)
            mp = re.search(r"-period\s+([\d.]+)", spec)
            mport = re.search(r"\[get_ports\s+\{?([^\}\]]+)\}?\]", spec)
            if mn:
                name = mn.group(1).strip("{}")
            if mp:
                period = float(mp.group(1))
            if mport:
                port = mport.group(1).strip("{} ")
            if period is None:
                continue
            key = name or port
            if key:
                periods.setdefault(key, period)
    return periods


def sync_sample_freq(proj: dict, explicit_period: float | None = None) -> str | None:
    """Align the sample-clock period across SDC/DDF/.hqins (P0-A6).

    The DDF <period> drives dump_vcd's waveform time axis; leaving it at the
    .hqins default (100 MHz -> 10 ns) while the real clock runs at another
    rate mislabels every VCD timestamp.  Returns the applied period (ns) or
    None when nothing could be determined."""
    info = _load_signal_info(proj)
    clk_name = ""
    msl = (info or {}).get("module_sample_list", [])
    if msl:
        clk_name = msl[0].get("clk_signal_name", "")

    period = explicit_period
    source = "explicit"
    if period is None:
        sdc_files = parse_hqprj(proj["hqprj"])["tc"]
        periods = _extract_sdc_periods(sdc_files)
        if clk_name and clk_name in periods:
            period = periods[clk_name]
            source = "sdc"
        elif len(periods) == 1:
            period = next(iter(periods.values()))
            other = next(iter(periods))
            source = "sdc"
            if clk_name and other != clk_name:
                print(f"Note: SDC 时钟名 {other} 与采样时钟 {clk_name} 不同，"
                      f"按唯一 create_clock（{period} ns）对齐采样周期。")
        elif periods:
            print(f"Warning: SDC 有多个时钟 {sorted(periods)}，无法确定采样时钟 "
                  f"{clk_name or '(未登记)'} 的周期——VCD 时间轴保持现状。"
                  f"可用 -insight -sample-period <ns> 显式指定。")
            return None
        else:
            print("[WARN] 无法确定采样时钟周期（工程无 FILE_TC，或 SDC 中无 create_clock）——")
            print("       DDF/VCD 时间轴按 .hqins CLOCK FREQUENCY 标注（GUI 默认 100MHz=10ns，")
            print("       与真实时钟不一致时波形时间轴会失真）。配置 FILE_TC 后 -run 自动对齐，")
            print("       或用 -insight -sample-period <ns> 显式指定。")
            return None

    # rewrite ddf <period> and .hqins [CLOCK FREQUENCY]
    freq = round(1000.0 / period, 4)
    # integer periods are written without a decimal point: dump_vcd renders
    # "<period>40.0ns</period>" as a malformed "$timescale 40 .0ns" in the VCD
    period_txt = int(period) if abs(period - int(period)) < 1e-9 else period
    canonical = f"<period>{period_txt}ns</period>"
    ddf_changed = False
    if os.path.isfile(proj["ddf"]):
        ddf_txt = open(proj["ddf"], encoding="utf-8", errors="replace").read()
        m = re.search(r"<period>([\d.]+)(ns|ps)</period>", ddf_txt)
        if m:
            cur_ns = float(m.group(1)) * (1000 if m.group(2) == "ps" else 1)
            # rewrite on value change OR formatting drift (normalizes e.g.
            # "40.0ns" left by an older version)
            if abs(cur_ns - period) > 1e-6 or m.group(0) != canonical:
                ddf_txt = re.sub(r"<period>[\d.]+(?:ns|ps)</period>",
                                 canonical, ddf_txt, count=1)
                with open(proj["ddf"], "w", encoding="utf-8", newline="") as f:
                    f.write(ddf_txt)
                ddf_changed = True
    sections = read_hqins(proj["hqins"])
    cur_freq = _section_value(sections.get("CLOCK FREQUENCY", []), la="")
    freq_changed = cur_freq is None or abs(float(cur_freq or 0) - freq) > 1e-6
    if freq_changed:
        _rewrite_hqins_section_value(proj, "CLOCK FREQUENCY", f"0_LA:{freq}")

    if ddf_changed or freq_changed:
        print(f"[OK] 采样时钟周期已对齐: {period} ns ({freq} MHz, 来源 {source}"
              f"{' '+clk_name if clk_name else ''})——ddf{'+hqins' if freq_changed else ''} 已更新，"
              "VCD 时间轴将按真实时钟标注。")
    else:
        print(f"[skip] 采样时钟周期已一致: {period} ns (来源 {source})")
    return period


def _write_legacy_stamps(proj: dict) -> None:
    """Pre-manifest freshness stamps (.bit_stamp/.bit_signals) still consumed
    by -capture's mtime/signal-set warnings; kept in sync on every -run."""
    stamp_dir = os.path.join(proj["hqins_dir"], "hq_import")
    bins = glob.glob(os.path.join(stamp_dir, "hqins_impl", "*.bin"))
    if not bins:
        return
    with open(os.path.join(stamp_dir, ".bit_stamp"), "w") as sf:
        sf.write(str(max(os.path.getmtime(b) for b in bins)))
    with open(os.path.join(stamp_dir, ".bit_signals"), "w") as sf:
        sf.write("\n".join(f"{s['name']}:{s['msb']}:{s['lsb']}"
                           for s in _collect_signals(_load_signal_info(proj))))


def run_flow(proj: dict, require_bin: bool = True, reuse_only: bool = False,
             legacy: bool = False) -> None:
    """Handle 'hqbuddy -insight -run': instrument-if-stale + staged implement.

    Unified freshness entry (P0-A1): every input (project fields, source
    order+content, includes, IP deps, device, tool, probe selection, storage
    params, ddf) is fingerprinted against the manifest of the last accepted
    build; anything changed re-instruments via -refresh before implementing.
    The implementation runs in a private build directory with per-stage
    acceptance and publish-or-rollback (P0-A3/A4, stageflow), so a failed or
    fake-successful flow can never replace the last good artifacts, and the
    downloader GUI is never spawned.  --legacy falls back to the official
    run_hqprj2hqins_flow wrapper."""
    if legacy:
        return run_flow_legacy(proj, require_bin)

    version = launcher.require_hqfpga_version()
    hqfpga_exe = version["hqfpga_path"]

    with jtag.build_lock(proj):
        # 0. loud configuration warnings: a build without timing constraints
        #    produces an unverifiable timing verdict and a dead violation gate
        prj_info = parse_hqprj(proj["hqprj"])
        if not prj_info["tc"]:
            print("[WARN] 工程未配置 FILE_TC（时序约束）——实现能成功，但时序未验证，")
            print("       -program 的违例门槛不会生效，采样时钟周期也无法从 SDC 对齐。")
            print("       在 .hqprj 中设置 FILE_TC=$WORK_DIR$<x.sdc> 后重跑。")

        # 1. freshness against the last accepted build
        storage = _storage_params(proj)
        old_manifest = buildman.load(proj)
        inputs = buildman.compute_inputs(proj, version, _probe_fp_list(proj), storage)
        fresh, diffs = buildman.inputs_match(old_manifest, inputs)
        netlist = os.path.join(proj["hqins_dir"], "hq_import", "hq_import_with_bscan.v")
        insight_ip = os.path.join(proj["hqins_dir"], "hq_import", "insight_ip.v")
        artifacts_ok = os.path.isfile(netlist) and os.path.isfile(insight_ip)

        # fully reusable = inputs unchanged AND the published, accepted
        # artifacts (bin) still match the manifest hash.  Re-running -run
        # then changes nothing (a rebuilt bin would even invalidate the
        # programmed stamp), so the whole build is skipped.
        import hashlib as _hashlib
        published_ok = False
        if old_manifest and artifacts_ok:
            out0 = old_manifest.get("outputs", {})
            b0 = out0.get("bin")
            if b0 and os.path.isfile(b0) and out0.get("bin_sha256"):
                try:
                    published_ok = (_hashlib.sha256(open(b0, "rb").read()).hexdigest()
                                    == out0["bin_sha256"])
                except OSError:
                    published_ok = False
        if fresh and artifacts_ok and published_ok:
            print(f"[skip] 全部输入未变化且已验收产物完好（build {old_manifest.get('build_id')}，"
                  f"bin sha256 {old_manifest['outputs']['bin_sha256'][:12]}...）——"
                  "无需重建，直接使用。")
            print("Tip: 强制重建请改动任一输入或删除 hqins_run/hq_import/.build_manifest.json。")
            _write_legacy_stamps(proj)
            return

        if fresh and artifacts_ok:
            print(f"[skip] 插桩输入未变化（沿用清单 build "
                  f"{(old_manifest or {}).get('build_id', '?')}）")
        else:
            constraint_only = bool(diffs) and all("约束" in d for d in diffs)
            if reuse_only:
                print("Error: --reuse-only 要求严格复用，但检测到输入变化：")
                for d in diffs:
                    print(f"       - {d}")
                print("       直接执行 -insight -run 重建，或去掉 --reuse-only。")
                sys.exit(1)
            for d in diffs:
                print(f"[i] 输入变化: {d}")
            if not diffs and not artifacts_ok:
                print("[i] 插桩产物缺失（hq_import_with_bscan.v / insight_ip.v）")
            if constraint_only:
                # constraints steer implementation/timing only — the
                # instrumented netlist is unaffected, skip the re-elaborate
                print("[i] 仅约束文件变化——跳过重插桩，直接重新实现。")
            else:
                run_refresh(proj)

        # 2. probe endpoint model: validate the selection against the (fresh)
        #    elaboration database and publish the probe map (P0-A2)
        pmap = probes_mod.build_probe_map(proj)
        pmap["build_id"] = None  # filled after the build
        pm_path = probes_mod.write_probe_map(proj, pmap)
        print(f"[OK] Probe map: {len(pmap['probes'])} probe(s) -> {pm_path}")

        # 3. sample-clock period alignment (P0-A6)
        sync_sample_freq(proj)

        # 4. staged implementation (P0-A3/A4)
        build_id = buildman.new_build_id()
        outputs = stageflow.run_stage_build(proj, hqfpga_exe, build_id,
                                            require_bin=require_bin)

        # 5. manifest: inputs (recomputed post-refresh) + accepted outputs
        storage = _storage_params(proj)
        inputs = buildman.compute_inputs(proj, version, _probe_fp_list(proj), storage)
        manifest = {"version": 1, "build_id": build_id, "time": time.time(),
                    "inputs": inputs, "outputs": outputs}
        buildman.save(proj, manifest)
        pmap["build_id"] = build_id
        probes_mod.write_probe_map(proj, pmap)

        # legacy freshness stamps (pre-manifest consumers: -capture's mtime
        # warning and .bit_signals signal-set check)
        if outputs.get("bin"):
            _write_legacy_stamps(proj)

        print(f"[OK] Instrumented flow done (build {build_id}, "
              f"{outputs['elapsed_s']}s, stages: {'/'.join(outputs['stages'])})")
        if outputs.get("bin"):
            print(f"     bin: {outputs['bin']}")
            print(f"     sha256: {outputs['bin_sha256']}")
        print("Tip: 下载用 -insight -program（消费已验收 bin 并登记编程记录）；"
              "抓波用 -insight -capture。")


def run_program(proj: dict, allow_violation: bool = False) -> None:
    """Handle 'hqbuddy -insight -program': download the ACCEPTED bitstream.

    Consumes the manifest-recorded bin (hash-verified), refuses when the
    timing verdict is violated unless --allow-violation, and records the
    programmed hash in .programmed_stamp so -capture can verify the board
    runs this build.  The JTAG lock serializes with any concurrent cable
    user; every transaction is logged to a session directory."""
    version = launcher.require_hqfpga_version()
    cable_exe = version.get("cable_path")
    if not version.get("has_cable") or not os.path.isfile(cable_exe):
        print(f"Error: cable.exe not found in {version['path']}")
        sys.exit(1)

    manifest = buildman.load(proj)
    outputs = (manifest or {}).get("outputs", {})
    if not manifest or not outputs.get("bin"):
        print("Error: 没有已验收的构建清单——先执行 -insight -run。")
        sys.exit(1)
    bin_path = outputs["bin"]
    if not os.path.isfile(bin_path):
        print(f"Error: 已验收的位流不存在: {bin_path}（被删除或移动）——重新 -run。")
        sys.exit(1)
    import hashlib
    h = hashlib.sha256(open(bin_path, "rb").read()).hexdigest()
    if h != outputs.get("bin_sha256"):
        print(f"Error: 位流内容与构建清单不符（{bin_path}）——")
        print(f"       清单 sha256={outputs.get('bin_sha256')}, 文件 sha256={h}。")
        print("       下载被拒绝：重新 -insight -run 生成并验收新位流。")
        sys.exit(1)

    timing = outputs.get("timing", {})
    violated = not (timing.get("setup_met", True) and timing.get("hold_met", True))
    if violated and not allow_violation:
        print("Error: 该构建时序未收敛"
              f"（setup WNS {timing.get('wns_setup_ps')} ps / hold WNS {timing.get('wns_hold_ps')} ps）——")
        print("       带违例下载请显式加 --allow-violation（实验位流）。")
        sys.exit(1)
    if violated:
        print("[WARN] 时序违例位流，--allow-violation 已确认（实验用途）。")

    session = jtag.session_dir(proj, "program")
    with jtag.jtag_lock(version):
        # board model detection (per download: the board may have been swapped)
        try:
            r = subprocess.run([cable_exe, "--detect_model"],
                               capture_output=True, text=True, errors="replace",
                               timeout=60)
        except subprocess.TimeoutExpired:
            print("Error: cable.exe --detect_model 超时（60s）——板卡/JTAG 未连接？")
            sys.exit(1)
        m = re.search(r"Device Model\s*:\s*(\S+)", r.stdout or "")
        if not m:
            jtag._log(session, "transactions.log",
                      "detect_model failed: " + (r.stdout or "") + (r.stderr or ""))
            print("[FAIL] 未能探测到板上型号，下载中止。cable 输出：")
            print((r.stdout or "").strip() or "(无输出)")
            sys.exit(1)
        model = m.group(1)
        print(f"[OK] 板上型号: {model}")
        jtag._log(session, "transactions.log", f"model={model}")

        # cable.exe prints errors but still exits 0 — scan the output
        cmd = [cable_exe, "--sealion", bin_path, "--model", model, "--Burst"]
        jtag._log(session, "transactions.log", "cmd: " + " ".join(cmd))
        try:
            proc = subprocess.run(cmd, capture_output=True, text=True,
                                  errors="replace", timeout=300)
        except subprocess.TimeoutExpired:
            print("Error: 下载超时（300s）——JTAG 连接异常，中止。")
            sys.exit(1)
        out = (proc.stdout or "") + (proc.stderr or "")
        jtag._log(session, "cable_output.txt", out)
        has_error = any(re.search(r"\b(error|fail(?:ed)?)\b\s*[:：]", ln, re.I)
                        for ln in out.splitlines())
        if proc.returncode != 0 or has_error:
            print(f"[FAIL] 下载失败 (exit {proc.returncode})。cable 输出尾部：")
            for ln in out.splitlines()[-15:]:
                print("  " + ln)
            print(f"       会话日志: {session}")
            sys.exit(1)

    stamp = {"bin": bin_path, "bin_sha256": h, "build_id": manifest["build_id"],
             "model": model, "time": time.time(), "violation_ok": violated}
    stamp_path = os.path.join(proj["hqins_dir"], "hq_import", ".programmed_stamp")
    with open(stamp_path, "w", encoding="utf-8") as f:
        json.dump(stamp, f, indent=2)
    jtag.write_report(session, "program.json", stamp)
    print(f"[OK] Programmed build {manifest['build_id']} -> {os.path.basename(bin_path)} "
          f"(sha256 {h[:12]}..., model {model})")
    print(f"     会话日志: {session}")


def run_flow_legacy(proj: dict, require_bin: bool = True) -> None:
    """Legacy -run: the official run_hqprj2hqins_flow wrapper with the
    hqdnload watcher (-run --legacy).  Kept as an escape hatch in case the
    hqprj2tcl-derived staged flow diverges on some project shape; it does NOT
    provide manifest freshness, staged acceptance or publish isolation."""

    version = launcher.require_hqfpga_version()
    hqfpga_exe = version["hqfpga_path"]

    # -run implements the EXISTING hq_import_with_bscan.v; it never re-instruments
    # (R47d: stale netlists are reused silently). Warn when any elaborated source
    # is newer than the netlist — best-effort only (IP-internal includes are not
    # tracked anywhere); -seed_sweep -ins always refreshes for that reason.
    netlist = os.path.join(proj["hqins_dir"], "hq_import", "hq_import_with_bscan.v")
    flist = os.path.join(proj["hqins_dir"], "hq_srcfile.f")
    if os.path.isfile(netlist) and os.path.isfile(flist):
        wdir = proj["work_dir"].replace(os.sep, "/").rstrip("/")
        netlist_mtime = os.path.getmtime(netlist)
        newer = 0
        for ln in open(flist, encoding="utf-8", errors="replace"):
            ln = ln.strip()
            if not ln:
                continue
            if ln.startswith("$WORK_DIR$"):
                ln = wdir + "/" + ln[len("$WORK_DIR$"):]
            elif ln.startswith("$WORK_DIR"):
                ln = wdir + "/" + ln[len("$WORK_DIR"):]
            elif not os.path.isabs(ln):
                ln = os.path.join(proj["work_dir"], ln)
            if os.path.isfile(ln) and os.path.getmtime(ln) > netlist_mtime:
                newer += 1
        if newer:
            print(f"Warning: 有 {newer} 个源文件比 hq_import_with_bscan.v 新——"
                  f"-run 只实现现有插桩网表，不会重新探针插入（板上将是旧逻辑）。")
            print("         先执行 hqbuddy -insight -refresh 重建网表"
                  "（自动重插桩刷新信号库，信号选择保留）。")

    # insight 流程必须产出 .bin（下载验收用）。GUI 新建工程 BGEN_1/2 常为
    # false（只出 .bit），这里自动打开并写回 .hqprj。
    _hqprj_lines = open(proj["hqprj"], encoding="utf-8", errors="replace").read().splitlines()
    _changed = False
    _out_lines = []
    for _ln in _hqprj_lines:
        if _ln.startswith("BGEN_1=false"):
            _out_lines.append("BGEN_1=true"); _changed = True
        elif _ln.startswith("BGEN_2=false"):
            _out_lines.append("BGEN_2=true"); _changed = True
        else:
            _out_lines.append(_ln)
    if _changed:
        with open(proj["hqprj"], "w", encoding="utf-8") as _f:
            _f.write(chr(10).join(_out_lines) + chr(10))
        print("[i] 已在 .hqprj 中开启 BGEN_1/BGEN_2（insight 流程需要产出 .bin）")
    tcl = f"run_hqprj2hqins_flow {{{_tcl_path(proj['hqprj'])}}}\nexit\n"
    with tempfile.NamedTemporaryFile("w", suffix=".tcl", delete=False, encoding="gbk") as f:
        f.write(tcl)
        tcl_path = f.name
    print(f"Running instrumented flow for {proj['hqprj']} ...")

    # The flow spawns the hqdnload GUI at the very end (it pre-fills the WRONG,
    # non-instrumented bin and blocks hqfpga.exe until dismissed). Auto-close
    # only OUR instances: hqdnload whose parent is this flow's hqfpga.exe,
    # or one already orphaned (parent exited). A user-started downloader's
    # parent (explorer/terminal) is still alive and is never touched.
    flow_start = time.time()
    proc = subprocess.Popen([hqfpga_exe, "-cmd", tcl_path], cwd=proj["work_dir"])

    def reap_downloader(hq_pid: int):
        ps = ("$dn = Get-CimInstance Win32_Process -Filter \"Name='hqdnload.exe'\";"
              "$alive = @(Get-Process -ErrorAction SilentlyContinue | "
              "Select-Object -ExpandProperty Id);"
              "foreach ($p in $dn) {"
              f"  if ($p.ParentProcessId -eq {hq_pid} "
              "  -or -not ($alive -contains $p.ParentProcessId)) "
              "  { Write-Output $p.ProcessId } }")
        while os.path.isfile(tcl_path):
            try:
                r = subprocess.run(["powershell", "-NoProfile", "-Command", ps],
                                   capture_output=True, text=True, timeout=15)
                pids = [ln.strip() for ln in (r.stdout or "").splitlines()
                        if ln.strip().isdigit()]
                for pid in pids:
                    subprocess.run(["taskkill", "/PID", pid, "/F"],
                                   capture_output=True, timeout=15)
                    print("[i] Auto-closed hqdnload window spawned by the flow.")
            except Exception:
                pass
            time.sleep(2)

    watcher = threading.Thread(target=reap_downloader, args=(proc.pid,),
                               daemon=True)
    watcher.start()
    try:
        wait_process(proc)
    finally:
        try:
            os.unlink(tcl_path)
        except OSError:
            pass
    if proc.returncode != 0:
        print(f"Error: hqfpga.exe 流程失败（code {proc.returncode}）。")
        sys.exit(1)
    # The flow can exit 0 even when implementation fails (e.g. JTAG capacity
    # overflow); only a fresh instrumented bitstream counts as success.
    # The bin is named after the .hqprj (not the top module).
    prj_stem = os.path.splitext(os.path.basename(proj["hqprj"]))[0]
    bin_candidates = glob.glob(os.path.join(proj["hqins_dir"], "hq_import",
                                             "hqins_impl", "*.bin"))
    fresh = [b for b in bin_candidates if os.path.getmtime(b) >= flow_start]
    if not fresh:
        if require_bin:
            print(f"Error: flow reported success but no fresh instrumented bitstream "
                  f"was produced under hqins_run/hq_import/hqins_impl/ (checked for "
                  f"{prj_stem}.bin). Check the reports there (place/route errors).")
            sys.exit(1)
        print("Note: 本次流程未产出新的插桩 bit——-xpn -from_src 只需布线结果，继续导出 XPN。")
    if fresh:
        stamp_dir = os.path.join(proj["hqins_dir"], "hq_import")
        with open(os.path.join(stamp_dir, ".bit_stamp"), "w") as sf:
            sf.write(str(max(os.path.getmtime(b) for b in fresh)))
        # record the signal set this bit was built with, so -capture can detect
        # -add/-del since the last -run (stale signal set => misplaced data view)
        info = _load_signal_info(proj)
        if info is not None:
            sigs = sorted(f"{s['name']}:{s['msb']}:{s['lsb']}"
                          for s in _collect_signals(info))
            with open(os.path.join(stamp_dir, ".bit_signals"), "w") as sf:
                sf.write("\n".join(sigs))

    # 常量探针预警：扫描实现目录的 log，报告被综合器常量折叠的探针信号
    impl_dir = os.path.join(proj["hqins_dir"], "hq_import", "hqins_impl")
    const_probes: set = set()
    # -xpn -ins -from_src path: the flow may exit 0 without creating hqins_impl
    for log_name in (os.listdir(impl_dir) if os.path.isdir(impl_dir) else []):
        if not log_name.endswith(".log"):
            continue
        log_path = os.path.join(impl_dir, log_name)
        # strict-utf8 then gbk: with errors="replace" the fallback loop below
        # could never trigger and GBK logs decoded as mojibake (regex still
        # matched by luck on ASCII anchors); strict makes the fallback real
        try:
            log_txt = open(log_path, "r", encoding="utf-8").read()
        except UnicodeDecodeError:
            log_txt = open(log_path, "r", encoding="gbk", errors="replace").read()
        except OSError:
            continue
        for m in re.finditer(r"Convert\s+\S+\s+(\S+__INS_\S+)\s", log_txt):
            const_probes.add(m.group(1))
        for m in re.finditer(r"(\S+)\s+to constant ZERO", log_txt):
            const_probes.add(m.group(1))
    if const_probes:
        print(f"\n⚠ 常量探针预警：{len(const_probes)} 个探针信号被综合器常量折叠，")
        print("  这些信号的任何触发条件都不会命中（探针陷阱）。")
        print("  建议：改用寄存器型信号做触发，或对目标信号加 (* keep *) 属性。")
        for p in sorted(const_probes):
            base = p.split("/")[-1].split("__INS")[0] if "__INS" in p else p
            print(f"    - {base}")

    print("[OK] Instrumented flow done.")


def run_refresh(proj: dict) -> None:
    """Handle 'hqbuddy -insight -refresh': in-place rebuild of insight_ip.v and
    hq_import_with_bscan.v while keeping every probe selection and armed trigger
    condition (CLI equivalent of clicking 保存 in the HqInsight GUI).

    ALWAYS re-runs hq_impor_t.tcl (rtl.elaborate -insight) first to refresh the
    signal database: the -new_rtl writer consumes the DB that elaborate seeds,
    so a skip-elaborate fast path risks silently dropping RTL attribute changes
    (HQ_LOC/keep/... — observed on a real design; the earlier optional fast path
    was removed with -reelab in 3.19.0). Selections are merged back into the
    rewritten .hqins (metadata keys re-seeded from the fresh dump)."""
    version = launcher.require_hqfpga_version()

    sig_info, la_info = _la_info_path(proj)
    la_list = la_info.get("la_list", [])
    if not la_list or not any(la_list[0].get(k) for k in ("s_list", "t_list", "st_list")):
        print("Error: .hqins 中没有任何信号选择——先 -insight -add（或 GUI 选好信号）再 -refresh。")
        sys.exit(1)

    tcl = os.path.join(proj["hqins_dir"], "hq_impor_t.tcl")
    if not os.path.isfile(tcl):
        _write_import_tcls(proj, _vfiles_from_hqins(proj))
    print("[1/2] Refreshing signal database (rtl.elaborate -insight) ...")
    proc = subprocess.Popen([version["hqfpga_path"], "-cmd", tcl],
                            cwd=proj["work_dir"])
    wait_process(proc)
    if proc.returncode != 0:
        print("Error: signal-database re-elaborate failed.")
        print("[FAIL] refresh")
        sys.exit(1)
    dump = os.path.join(proj["hqins_dir"], "hq_import",
                        "hq_import_parser_staticelab_dump.json")
    if not os.path.isfile(dump):
        print("Error: re-elaborate produced no signal database.")
        print("[FAIL] refresh")
        sys.exit(1)
    # hqfpga may rewrite .hqins during -insight elaborate; restore the probe
    # selections and re-seed the JSON metadata keys from the fresh dump.
    sig_new = dict(sig_info)
    sig_new["module_sample_list"] = sig_info.get("module_sample_list", [])
    sig_new.update(_dump_metadata(dump))
    _rewrite_hqins_sections(proj, sig_new, la_info)
    print("[1/2] Signal database refreshed (probe selections kept).")

    if not os.path.isfile(proj["ddf"]):
        print("[i] .ddf 缺失——按 .hqins 重建（触发条件已重置，稍后请重新 -trig）。")
        _write_ddf_from_la(proj, la_info)
    print("[2/2] Rebuilding insight_ip.v + hq_import_with_bscan.v ...")
    _rebuild_instrumented(proj, sig_new, la_info)
    netlist = os.path.join(proj["hqins_dir"], "hq_import", "hq_import_with_bscan.v")
    la = la_info["la_list"][0]
    n_probes = len(la["s_list"]) + len(la["t_list"]) + len(la["st_list"])
    # content fingerprint of the elaborated sources at refresh time —
    # hier-build reuses this netlist, and an mtime guard alone is defeated
    # by timestamp rollback (R5-D6)
    try:
        import hashlib as _h
        fp = []
        for vf in _vfiles_from_hqins(proj):
            if os.path.isfile(vf):
                h = _h.sha256()
                with open(vf, "rb") as _f:
                    for chunk in iter(lambda: _f.read(1 << 20), b""):
                        h.update(chunk)
                fp.append({"path": os.path.normpath(vf).replace(os.sep, "/"),
                           "sha256": h.hexdigest()})
        with open(os.path.join(proj["hqins_dir"], "hq_import",
                               ".refresh_fingerprint.json"), "w",
                  encoding="utf-8") as f:
            json.dump({"sources": fp}, f, indent=2)
    except OSError:
        pass
    print(f"[OK] Instrumented artifacts rebuilt ({n_probes} probe signal(s) preserved): {netlist}")
    print("Tip: 板上生效需 -insight -run 重新实现并下载（-run 只实现网表，不会重新探针插入）。")


# --- Signal selection (-init/-ls/-add/-del) ---

STYPE_TOKENS = {"sample": 2, "trigger": 3, "both": 4}


def _initial_hqins(proj: dict, vfiles: list) -> str:
    """Build the initial .hqins skeleton (as the GUI writes it on entering HqInsight)."""

    wdir = "$WORK_DIR"
    files = "\n".join(f.replace(proj["work_dir"].replace(os.sep, "/"), wdir) for f in vfiles)
    times = "\n".join(str(os.path.getmtime(f)) for f in vfiles)
    hqins_rel = f"{wdir}/hqins_run/hq_import.hqins"
    return f"""[HQINS PROJECT VERSION]
1.0

[OWNER NAME]
HqInsight

[PROJECT NAME]
{hqins_rel}


[PROJECT FILES]
{files}


[FILE TIMES]
{times}

[HQFPGA TCL]
{wdir}/hqins_run/hq_impor_t.tcl

[HQFPGA NEW RTL TCL]
{wdir}/hqins_run/hq_impor_new_rtl.tcl

[MEMORY DEPTH INFO]
0_LA:1024

[ADD REGISTER]
0_LA:YES

[TRIGGER POSITION]
0_LA:128

[WRITE FULL BRAM]
0_LA:true

[TRIGGER MULTI-WINDOW]
0_LA:1

[TRIGGER LEVEL]
0_LA:1

[LA NUMBER]
1

[CLOCK FREQUENCY]
100

[TOP MODULE NAME]
{proj['top']}

[FPGA DEVICE NAME]
{proj['family']}

[FPGA DEVICE DIE]
{proj['die']}
"""


def _write_import_tcls(proj: dict, vfiles: list) -> None:
    """Write hq_impor_t.tcl / hq_impor_new_rtl.tcl into hqins_run/ (GUI equivalents)."""
    wdir = proj["work_dir"].replace(os.sep, "/")
    lines = "\n".join(f"lappend vfiles {{{f}}}" for f in vfiles)
    base = f"""set WORK_DIR {{{wdir}}}
set vfiles {{}}
{lines}
dv.setup -synlib_only {proj['family']}
rtl.analyze $vfiles
"""
    t = base + f"""rtl.srcfiles.list -print -o> $WORK_DIR/hqins_run/hq_srcfile.f
rtl.elaborate -top {proj['top']} -insight $WORK_DIR/hqins_run/hq_import.hqins
exit
"""
    new_rtl = base + f"""rtl.elaborate -top {proj['top']} -new_rtl $WORK_DIR/hqins_run/hq_import.hqins
exit
"""
    with open(os.path.join(proj["hqins_dir"], "hq_impor_t.tcl"), "w", encoding="gbk") as f:
        f.write(t)
    with open(os.path.join(proj["hqins_dir"], "hq_impor_new_rtl.tcl"), "w", encoding="utf-8") as f:
        f.write(new_rtl)


def _vfiles_from_hqins(proj: dict) -> list:
    """Reconstruct the elaborated vfile list from .hqins [PROJECT FILES]
    ($WORK_DIR-prefixed or absolute), for regenerating the import tcls."""
    out = []
    wdir = proj["work_dir"].replace(os.sep, "/").rstrip("/")
    for line in read_hqins(proj["hqins"]).get("PROJECT FILES", []):
        f = line.strip()
        if not f:
            continue
        if f.startswith("$WORK_DIR$"):
            f = wdir + "/" + f[len("$WORK_DIR$"):]
        elif f.startswith("$WORK_DIR"):
            f = wdir + "/" + f[len("$WORK_DIR"):]
        elif not os.path.isabs(f):
            f = wdir + "/" + f
        out.append(f)
    if not out:
        print("Error: .hqins [PROJECT FILES] 为空，无法重建 import TCL。")
        sys.exit(1)
    return out


def _dump_metadata(dump_path: str) -> dict:
    """Build the GUI-style [SIGNAL JSON INFO] metadata keys from the static-elab dump.

    rtl.elaborate -new_rtl requires module_signals_name / expanded_module_inst /
    sub_module_inst_list to punch the sample-clock probe port through the module
    boundary; without them the LA refclk floats and capture reads all zeros.
    """
    with open(dump_path, "r", encoding="utf-8") as f:
        modules = json.load(f).get("modules", [])
    module_signals_name = [{"module_name": m["module"]["name"],
                            "signal_list": [s["name"] for s in m.get("normal_signals", [])]}
                           for m in modules]
    sub_module_inst_list = [{"module_name": m["module"]["name"],
                             "submod_list": [i["mod_name"] for i in m["module"].get("inst_mod", [])],
                             "subinst_list": [i["inst_name"] for i in m["module"].get("inst_mod", [])]}
                            for m in modules]
    expanded_module_inst = []
    for m in modules:
        inst_mod = m["module"].get("inst_mod", [])
        if not inst_mod or all(i.get("mod_property") == "blackbox" for i in inst_mod):
            continue
        expanded_module_inst.append({
            "module_name": m["module"]["name"],
            "inst_list": [{"disp_mod_name": i["mod_name"], "orig_mod_name": i["mod_name"],
                           "disp_inst_name": i["inst_name"], "orig_inst_name": i["inst_name"],
                           "is_array": "[" in i["inst_name"], "msb": -1, "lsb": -1,
                           "array_idx": -1, "line_num": i["first_line"]}
                          for i in inst_mod]})
    return {"expanded_module_inst": expanded_module_inst,
            "module_signals_name": module_signals_name,
            "module_to_orig_map": [],
            "sub_module_inst_list": sub_module_inst_list}


def _preflight_check(proj: dict) -> None:
    """Pre-flight diagnostics before -insight -init.  Reports ALL issues at
    once instead of failing one at a time during elaborate/run."""
    issues: list = []
    warns: list = []

    hqprj = proj["hqprj"]
    if not os.path.isfile(hqprj):
        print(f"Error: .hqprj not found: {hqprj}")
        sys.exit(1)

    info = parse_hqprj(hqprj)
    fields = info["fields"]
    file_src = info["sources"]        # resolved; FILE_SRC=NONE skipped
    file_disabled = info["disabled"]

    if not fields.get("TOP_MODULE"):
        issues.append("TOP_MODULE 为空——请用 `hqbuddy -set_top <模块名>` 设置顶层")
    if fields.get("TOP_MODULE") and not re.search(r"^\d+$", fields.get("STEP_CURR", "0")):
        pass  # normal
    # FILE_TC/FILE_PC live in the dedicated parser lists, never in `fields` —
    # a fields.get("FILE_PC") probe would misreport every project that HAS a
    # UPC as FILE_PC=NONE
    if fields.get("IS_PC_AUTO_CONS", "false") == "false" and not info["pc"]:
        warns.append("无管脚约束文件（FILE_PC=NONE）——bitgen 阶段会报 BIT-11")

    for f in file_src:
        if not os.path.isfile(f):
            issues.append(f"FILE_SRC 文件不存在: {f}")
    for f in file_disabled:
        if not os.path.isfile(f):
            warns.append(f"FILE_SRC_DISABLED 文件不存在: {f}")

    # _sim.v / testbench 文件不应出现在 FILE_SRC（会引发 SFE-E-58 重复声明）
    for f in file_src + file_disabled:
        base = os.path.basename(f)
        if "_sim.v" in base or "tb_" in base:
            warns.append(f"源文件疑似 testbench/仿真模型: {base}（可能引发重复声明错误）")

    # .hqip 器件一致性
    hqips = glob.glob(os.path.join(proj["work_dir"], "**", "*.hqip"), recursive=True)
    die = fields.get("DIE", "")
    for h in hqips:
        try:
            for line in open(h, encoding="utf-8", errors="replace"):
                if line.startswith("device="):
                    dev = line.split("=", 1)[1].strip()
                    if dev and die and dev != die:
                        warns.append(f"IP 器件不匹配: {os.path.basename(h)} device={dev} != DIE={die}")
                    break
        except OSError:
            pass

    if issues:
        print("Pre-flight 检查发现问题（必须修复才能 -init）：")
        for i, msg in enumerate(issues, 1):
            print(f"  {i}. {msg}")
        sys.exit(1)
    if warns:
        print("Pre-flight 警告（不阻塞，但可能影响后续流程）：")
        for w in warns:
            print(f"  ⚠ {w}")


def run_init(proj: dict, force: bool = False) -> None:
    """Handle 'hqbuddy -insight -init': create hqins_run skeleton and elaborate."""

    # -init writes a fresh .hqins skeleton over any existing one — with probe
    # selections inside.  Refuse unless explicitly forced (GUI-equivalent is
    # deleting the HqInsight project first).
    if os.path.isfile(proj["hqins"]) and not force:
        print(f"Error: HqInsight 工程已存在: {proj['hqins']}——重复 -init 会清空已登记的"
              "信号选择与触发条件。")
        print("       改了 RTL/IP 请用 -insight -refresh；确认要清空重来请删除 hqins_run/"
              " 或加 --force。")
        sys.exit(1)

    _preflight_check(proj)

    version = launcher.require_hqfpga_version()
    hqfpga_exe = version["hqfpga_path"]

    vfiles = extract_filelist(proj["hqprj"])
    vfiles = [f for f in vfiles if os.path.isfile(f)]
    if not vfiles:
        print("Error: no source files found in .hqprj FILE_SRC.")
        sys.exit(1)

    os.makedirs(proj["hqins_dir"], exist_ok=True)
    _write_import_tcls(proj, vfiles)
    with open(proj["hqins"], "w", encoding="utf-8") as f:
        f.write(_initial_hqins(proj, vfiles))

    tcl_path = os.path.join(proj["hqins_dir"], "hq_impor_t.tcl")
    proc = subprocess.Popen([hqfpga_exe, "-cmd", tcl_path],
                            cwd=proj["work_dir"])
    wait_process(proc)
    if proc.returncode != 0:
        print(f"Error: elaborate failed (code {proc.returncode}).")
        sys.exit(1)
    dump = os.path.join(proj["hqins_dir"], "hq_import", "hq_import_parser_staticelab_dump.json")
    if not os.path.isfile(dump):
        print("Error: elaborate produced no signal database.")
        sys.exit(1)

    # Seed [SIGNAL JSON INFO] with the dump-derived metadata keys the GUI writes,
    # so rtl.elaborate -new_rtl punches the sample-clock probe port (-add keeps them).
    sections = read_hqins(proj["hqins"])
    sig0 = {"version": "0.0.3", "module_sample_list": []}
    sig0.update(_dump_metadata(dump))
    sections["SIGNAL JSON INFO"] = [json.dumps(sig0, ensure_ascii=False, sort_keys=True)]
    parts = []
    for name, lines in sections.items():
        parts.append(f"[{name}]")
        parts.extend(lines)
        parts.append("")
    with open(proj["hqins"], "w", encoding="utf-8") as f:
        f.write("\n".join(parts))

    print(f"[OK] HqInsight project initialized: {proj['hqins']}")


def _load_dump_json(proj: dict) -> list:
    """Load the elaborate signal database; returns the modules list."""
    dump = os.path.join(proj["hqins_dir"], "hq_import", "hq_import_parser_staticelab_dump.json")
    if not os.path.isfile(dump):
        print("Error: 找不到信号数据库——请先执行 -insight -init。")
        sys.exit(1)
    with open(dump, "r", encoding="utf-8") as f:
        return json.load(f).get("modules", [])


def _signal_catalog(proj: dict) -> list:
    """Flatten the dump json into [{module, name, msb, lsb, hier}]."""
    modules = _load_dump_json(proj)

    def find_inst_path(target_name: str, from_mod: dict, prefix: str, seen: set) -> str | None:
        for inst in from_mod["module"].get("inst_mod", []):
            path = f"{prefix}/{inst['inst_name']}" if prefix else inst["inst_name"]
            if inst["mod_name"] == target_name:
                return path
            child = next((m for m in modules if m["module"]["name"] == inst["mod_name"]), None)
            if child and id(child) not in seen:
                seen.add(id(child))
                r = find_inst_path(target_name, child, path, seen)
                if r:
                    return r
        return None

    top_mod = next((m for m in modules if m["module"]["name"].split("[")[0] == proj["top"]), None)
    catalog = []
    for m in modules:
        mod_name = m["module"]["name"]
        hier = ""
        if top_mod and mod_name.split("[")[0] != proj["top"]:
            hier = find_inst_path(mod_name, top_mod, "", {id(top_mod)}) or ""
        for sig in m.get("normal_signals", []):
            catalog.append({
                "module": mod_name,
                "name": sig["name"],
                "msb": sig.get("range_msb", 0),
                "lsb": sig.get("range_lsb", 0),
                "hier": f"{proj['top']}/{hier}" if hier else proj["top"],
            })
    return catalog


def list_signals(proj: dict, keyword: str | None) -> None:
    """Handle 'hqbuddy -insight -ls [keyword]'."""
    catalog = _signal_catalog(proj)
    # selected may carry slice info (slice_msb/lsb) — mark by raw name but
    # show the exact registered slice so a bus slice isn't displayed as the
    # whole bus
    sel = {}
    info = _load_signal_info(proj)
    for s in (_collect_signals(info) if info else []):
        sel.setdefault(s["name"], s)
    if keyword:
        kw = keyword.lower()
        catalog = [c for c in catalog if kw in c["name"].lower()]
    print(f"Signals ({len(catalog)}): (* = selected)")
    for c in catalog:
        width = c["msb"] - c["lsb"] + 1
        mark = " " if c["name"] not in sel else "*"
        note = ""
        s = sel.get(c["name"])
        if s and s.get("slice_msb") is not None \
                and (s["slice_msb"], s["slice_lsb"]) != (c["msb"], c["lsb"]):
            note = f"  (已选切片 [{s['slice_msb']}:{s['slice_lsb']}])"
        print(f" {mark} {c['name']}[{width}b]  module={c['module']}  {c['hier']}{note}")


def _ip_name(name: str, module: str) -> str:
    return f"{name}__INS_{module}__INS0"


def _show_name(name: str, msb: int, lsb: int) -> str:
    return f"{name}[{msb}:{lsb}]" if msb != lsb else f"{name}[{lsb}]"


_VALID_DEPTHS = {256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536}


def set_sample_params(proj: dict, args: list) -> None:
    """Handle '-insight -depth N [-windows W] [-level L]' (GUI 采样参数 dialog).

    Writes [MEMORY DEPTH INFO]/[TRIGGER MULTI-WINDOW]/[TRIGGER LEVEL] (keys
    '0_LA:*' per LA_0).  Depth/windows are storage-architecture properties:
    after changing them the instrumented bitstream MUST be rebuilt (-run) and
    re-downloaded, otherwise capture misreads.  Trigger position must satisfy
    0 <= offset <= depth/windows - 5; with default offset 128 that requires
    depth/windows >= 133."""
    if not args:
        print("Usage: -insight -depth N [-windows W] [-level L] [-position P]")
        print(f"       N: {'/'.join(str(d) for d in sorted(_VALID_DEPTHS))}")
        print("       W: power of 2 >= 1 (multi-window storage split)")
        print("       L: trigger level >= 1")
        print("       P: trigger position, 0 <= P <= depth/windows - 5")
        sys.exit(1)
    depth, windows, level, position = None, None, None, None
    i = 0
    while i < len(args):
        if args[i] == "-depth" and i + 1 < len(args):
            try:
                depth = int(args[i + 1])
            except ValueError:
                print(f"Error: -depth expects an integer, got: {args[i + 1]}")
                sys.exit(1)
            i += 2
        elif args[i] == "-windows" and i + 1 < len(args):
            try:
                windows = int(args[i + 1])
            except ValueError:
                print(f"Error: -windows expects an integer, got: {args[i + 1]}")
                sys.exit(1)
            i += 2
        elif args[i] == "-level" and i + 1 < len(args):
            try:
                level = int(args[i + 1])
            except ValueError:
                print(f"Error: -level expects an integer, got: {args[i + 1]}")
                sys.exit(1)
            i += 2
        elif args[i] == '-position' and i + 1 < len(args):
            try:
                position = int(args[i + 1])
            except ValueError:
                print(f"Error: -position expects an integer, got: {args[i + 1]}")
                sys.exit(1)
            i += 2
        else:
            print(f"Error: unknown -depth option: {args[i]}")
            sys.exit(1)
    if depth is None and windows is None and level is None and position is None:
        print("Error: nothing to set (use -depth / -windows / -level / -position)")
        sys.exit(1)

    sections = read_hqins(proj["hqins"])

    def section_value(name: str, default: str) -> int:
        for ln in sections.get(name, []):
            if ":" in ln:
                return int(ln.split(":", 1)[1])
        return int(default)

    if depth is not None and depth not in _VALID_DEPTHS:
        print(f"Error: -depth must be one of {sorted(_VALID_DEPTHS)}, got: {depth}")
        sys.exit(1)
    cur_depth = section_value("MEMORY DEPTH INFO", "1024")
    cur_windows = section_value("TRIGGER MULTI-WINDOW", "1")
    new_depth = depth if depth is not None else cur_depth
    new_windows = windows if windows is not None else cur_windows
    if windows is not None and (windows < 1 or windows & (windows - 1) != 0):
        print(f"Error: -windows must be a power of 2 (1, 2, 4, ...), got: {windows}")
        sys.exit(1)
    if level is not None and level < 1:
        print(f"Error: -level must be >= 1, got: {level}")
        sys.exit(1)
    offset = section_value("TRIGGER POSITION", "128")
    max_pos = new_depth // new_windows - 5
    if position is not None and not (0 <= position <= max_pos):
        print(f"Error: -position {position} 对 depth={new_depth}/windows={new_windows} "
              f"非法（要求 0 <= pos <= {max_pos}）。")
        sys.exit(1)
    if position is None and offset > max_pos:
        print(f"Error: 当前触发位置 {offset} 对 depth={new_depth}/windows={new_windows} "
              f"非法（要求 0 <= pos <= {max_pos}）。先用 -position 调整触发位置或减小窗口数。")
        sys.exit(1)

    changes = []
    changed_storage = False

    # DDF is what the flow actually consumes (R43); read its current values so
    # the "already at requested values" check covers both files.
    ddf_depth = ddf_windows = ddf_level = ddf_offset = None
    if os.path.isfile(proj["ddf"]):
        ddf_txt = open(proj["ddf"], encoding="utf-8", errors="replace").read()
        m = re.search(r"<depth>(\d+)</depth>", ddf_txt)
        ddf_depth = int(m.group(1)) if m else None
        m = re.search(r"<window_num>(\d+)</window_num>", ddf_txt)
        ddf_windows = int(m.group(1)) if m else None
        m = re.search(r"<level>(\d+)</level>", ddf_txt)
        ddf_level = int(m.group(1)) if m else None
        m = re.search(r"<offset>(\d+)</offset>", ddf_txt)
        ddf_offset = int(m.group(1)) if m else None

    depth_pending = (depth is not None
                     and (depth != cur_depth or depth != ddf_depth))
    windows_pending = (windows is not None
                       and (windows != cur_windows or windows != ddf_windows))
    if depth is not None and depth_pending:
        sections["MEMORY DEPTH INFO"] = [f"0_LA:{depth}"]
        changes.append(f"depth={depth}")
        changed_storage = True
    if windows is not None and windows_pending:
        sections["TRIGGER MULTI-WINDOW"] = [f"0_LA:{windows}"]
        changes.append(f"windows={windows}")
        changed_storage = True
    if level is not None:
        sections["TRIGGER LEVEL"] = [f"0_LA:{level}"]
        changes.append(f"level={level}")
    if position is not None:
        sections["TRIGGER POSITION"] = [f"0_LA:{position}"]
        changes.append(f"position={position}")
    if not changes and ddf_depth == cur_depth and ddf_windows == cur_windows:
        print("[OK] Sampling parameters already at requested values; nothing to do.")
        return
    if changes:
        parts = []
        for name, lines in sections.items():
            parts.append(f"[{name}]")
            parts.extend(lines)
            parts.append("")
        with open(proj["hqins"], "w", encoding="utf-8") as f:
            f.write("\n".join(parts))

    # The flow consumes the DDF, not the .hqins depth (R43: flow crashes without
    # ddf; a .hqins-only depth edit never reaches ddf/netlist). Patch ddf tags too.
    if os.path.isfile(proj["ddf"]):
        ddf_txt = open(proj["ddf"], encoding="utf-8", errors="replace").read()
        ddf_changed = False
        if depth is not None and ddf_depth != depth:
            ddf_txt = re.sub(r"<depth>\d+</depth>", f"<depth>{depth}</depth>", ddf_txt, count=1)
            ddf_changed = True
        if windows is not None and ddf_windows != windows:
            ddf_txt = re.sub(r"<window_num>\d+</window_num>",
                             f"<window_num>{windows}</window_num>", ddf_txt, count=1)
            ddf_changed = True
        if level is not None and ddf_level != level:
            ddf_txt = re.sub(r"<level>\d+</level>",
                             f"<level>{level}</level>", ddf_txt, count=1)
            ddf_changed = True
        if position is not None and ddf_offset != position:
            ddf_txt = re.sub(r"<offset>\d+</offset>",
                             f"<offset>{position}</offset>", ddf_txt, count=1)
            ddf_changed = True
        if ddf_changed:
            with open(proj["ddf"], "w", encoding="utf-8", newline="") as f:
                f.write(ddf_txt)
            changes.append("ddf synced")
    print(f"[OK] Sampling parameters set: {', '.join(changes)}")
    if changed_storage:
        print("Tip: depth/windows 是存储架构属性——必须 -insight -run 重新生成插桩 "
              "bitstream 并重新下载后生效；否则 capture 读数错位。")


def _la_info_path(proj: dict) -> dict:
    """Return parsed [SIGNAL JSON INFO] and [LA SIGNAL INFO] (empty defaults)."""
    sections = read_hqins(proj["hqins"])
    sig_raw = "\n".join(sections.get("SIGNAL JSON INFO", [])).strip()
    la_raw = "\n".join(sections.get("LA SIGNAL INFO", [])).strip()
    sig_info = json.loads(sig_raw) if sig_raw else {"version": "0.0.3", "module_sample_list": []}
    la_info = json.loads(la_raw) if la_raw else {"la_list": []}
    return sig_info, la_info


def _rewrite_hqins_sections(proj: dict, sig_info: dict, la_info: dict) -> None:
    """Rewrite .hqins, replacing/adding [SIGNAL JSON INFO] and [LA SIGNAL INFO]."""
    sections = read_hqins(proj["hqins"])
    sections["SIGNAL JSON INFO"] = [json.dumps(sig_info, ensure_ascii=False)]
    sections["LA SIGNAL INFO"] = [json.dumps(la_info, ensure_ascii=False)]
    parts = []
    for name, lines in sections.items():
        parts.append(f"[{name}]")
        parts.extend(lines)
        parts.append("")
    with open(proj["hqins"], "w", encoding="utf-8") as f:
        f.write("\n".join(parts))


def _current_context_module(proj: dict) -> str | None:
    """Module of the most recently added signal (context for -clk/-module carry-over)."""
    info = _la_info_path(proj)[0]
    entries = info.get("module_sample_list", [])
    if not entries:
        return None
    datas = entries[-1].get("modules_sample_data", [])
    return datas[-1]["module_name"] if datas else entries[-1].get("clk_module_name")


def add_signal(proj: dict, name: str, clk: str | None, stype: int, module: str | None = None) -> None:
    """Handle 'hqbuddy -insight -add <signal>[:msb:lsb] [-clk <clk>] [-type ...] [-module <mod>]'."""
    catalog = _signal_catalog(proj)
    # 精确名优先：网表里存在字面名为 "cnt[7]" 的单比特网——能精确命中就不当切片解析
    # （否则 cnt[7:7] 会被切成总线 cnt 的一段，与 cnt[7] 命中不同网，行为不一致 R25）
    matches = [c for c in catalog if c["name"] == name]
    slice_rng = None
    if not matches:
        # 总线片选：name[msb:lsb] / name:msb:lsb 取一段；name[N] 等价 name[N:N]
        m = (re.match(r"^(.+)\[(-?\d+):(-?\d+)\]$", name)
             or re.match(r"^(.+):(-?\d+):(-?\d+)$", name)
             or re.match(r"^(.+)\[(-?\d+)\]$", name))
        if m:
            base = m.group(1)
            if m.lastindex == 2:  # cnt[7] → 等价 cnt[7:7]
                slice_rng = (int(m.group(2)), int(m.group(2)))
            else:
                slice_rng = (int(m.group(2)), int(m.group(3)))
            if slice_rng[0] < slice_rng[1]:
                print(f"Error: slice msb must be >= lsb: {base}[{slice_rng[0]}:{slice_rng[1]}]")
                sys.exit(1)
            name = base
        matches = [c for c in catalog if c["name"] == name]
    if module:
        matches = [c for c in matches if c["module"] == module or c["module"].split("[")[0] == module]
    elif len(matches) > 1:
        # Disambiguate via the module of the previously added signal.
        ctx = _current_context_module(proj)
        if ctx:
            narrowed = [c for c in matches if c["module"] == ctx]
            if len(narrowed) == 1:
                matches = narrowed
    if not matches:
        unfiltered = [c for c in catalog if c["name"] == name]
        if unfiltered:
            mods = ", ".join(sorted({c["module"] for c in unfiltered}))
            print(f"Error: 信号 {name} 存在于模块 {mods}，但与 -module 指定的模块不匹配。")
            print(f"       -module 应为模块名（可带 [N] 实例后缀），不能用实例路径片段（如 u_xxx）。")
            sys.exit(1)
        print(f"Error: 设计中找不到信号: {name}（用 -insight -ls 查看可用信号）")
        print("       若该信号来自刚改过的 RTL：信号库还是旧的，先 -insight -refresh 刷新。")
        sys.exit(1)
    if len(matches) > 1:
        mods = ", ".join(c["module"] for c in matches)
        print(f"Error: 信号 {name} 存在于多个模块: {mods}——用 -module 消歧")
        sys.exit(1)
    sig = matches[0]
    if slice_rng:
        hi, lo = slice_rng
        if hi > sig["msb"] or lo < sig["lsb"]:
            print(f"Error: slice {name}[{hi}:{lo}] out of range ({name}[{sig['msb']}:{sig['lsb']}])")
            sys.exit(1)
        sig = {**sig, "msb": hi, "lsb": lo}

    # per-module instrumentation: a module with several instances cannot be
    # distinguished per instance yet — say so up front instead of silently
    # binding the trigger to one of them later
    try:
        insts = probes_mod._instance_paths(_load_dump_json(proj),
                                           proj["top"]).get(sig["module"], [])
        if len(insts) > 1:
            print(f"Warning: 信号 {name} 所在模块 {sig['module']} 有 {len(insts)} 个实例"
                  f"（{'/'.join(insts)}）——当前插桩按模块粒度，触发表达式按信号名绑定，"
                  "无法按实例区分；跨层次按实例选择将在后续版本交付。")
    except (OSError, json.JSONDecodeError):
        pass

    catalog_names = {c["name"] for c in catalog}
    if clk and clk not in catalog_names:
        print(f"Error: 采样时钟 {clk} 不在信号数据库中（assign 中转线/派生网不会被 elaborate 收录）。")
        print("       请改用其驱动信号名（如端口名或寄存器名）作为 -clk。")
        sys.exit(1)

    sig_info, la_info = _la_info_path(proj)
    msl = sig_info.setdefault("module_sample_list", [])
    if msl:
        # 硬件限制：一个 LA 只支持一个采样时钟（GUI 同样强制）。
        # 后续信号（无论哪个模块）都并入现有时钟组，绝不允许第二时钟条目。
        clk_entry = msl[0]
        clk_name = clk_entry["clk_signal_name"]
        if clk and clk != clk_name:
            print(f"Error: 本 LA 已使用采样时钟 {clk_name}（每个 LA 只支持一个采样时钟）。")
            print(f"       信号 {name}（模块 {sig['module']}）不能使用 -clk {clk}。")
            print(f"       若该信号确实由 {clk_name} 驱动，请去掉 -clk 直接添加；否则请先 -del 清空后重建。")
            sys.exit(1)
    else:
        if not clk:
            print("Error: 首个信号需要 -clk <时钟信号>。")
            sys.exit(1)
        clk_entry = {"clk_module_name": sig["module"], "clk_signal_name": clk,
                     "modules_sample_data": []}
        msl.append(clk_entry)
    clk_name = clk_entry["clk_signal_name"]
    mod_data = next((d for d in clk_entry["modules_sample_data"]
                     if d["module_name"] == sig["module"]), None)
    if mod_data is None:
        mod_data = {"module_name": sig["module"], "sample_list": [], "trigger_list": [],
                    "sample_and_trigger_list": [], "disable_list": [], "normal_signals": [],
                    "two_packed_array_signals": [], "one_packed_one_unpacked_array_signals": [],
                    "one_unpacked_array_signals": [], "two_unpacked_array_signals": [],
                    "signal_to_root": {}, "root_to_signals": {}, "struct_tree_data": []}
        clk_entry["modules_sample_data"].append(mod_data)

    if any(s["signal_name"] == name for s in mod_data["normal_signals"]):
        print(f"Error: 信号已登记过: {name}（重复 -add 无需执行）")
        sys.exit(1)
    key = {2: "sample_list", 3: "trigger_list", 4: "sample_and_trigger_list"}[stype]
    mod_data[key].append(name)
    raw_hi, raw_lo = next((c["msb"], c["lsb"]) for c in catalog
                          if c["name"] == name and c["module"] == sig["module"])
    mod_data["normal_signals"].append({
        "signal_name": name, "sample_type": stype,
        "raw_msb": raw_hi, "raw_lsb": raw_lo,
        "slice_msb": sig["msb"], "slice_lsb": sig["lsb"]})

    # [LA SIGNAL INFO]
    la_list = la_info.setdefault("la_list", [])
    la = la_list[0] if la_list else None
    if la is None:
        la = {"clk_list": [], "data_in_order": [], "s_list": [], "st_list": [],
              "t_list": [], "trig_in_order": []}
        la_list.append(la)
    clk_sig = next((c for c in catalog if c["name"] == clk_name
                    and (c["module"] == sig["module"] or c["module"].split("[")[0] == sig["module"].split("[")[0])), None)
    if clk_sig is None:
        # 时钟常在顶层而首个信号在子模块：按名在任意模块解析（存在性校验只按名做过）。
        # clk_list 必须记时钟自己所在模块，否则 ddf refclk 网名错误。clk_module_name
        # （module_sample_list）保持 GUI 语义记首个信号模块，不受影响。
        clk_sig = next((c for c in catalog if c["name"] == clk_name), None)
    if not la["clk_list"] and clk_sig:
        la["clk_list"].append({
            "ip_signal_name": _ip_name(clk_name, clk_sig["module"]), "lsb": 0, "msb": 0,
            "module_name": clk_sig["module"], "raw_signal_name": clk_name,
            "show_hier_name": clk_name, "show_name": clk_name})
    entry = {"ip_signal_name": _ip_name(name, sig["module"]), "lsb": sig["lsb"],
             "msb": sig["msb"], "module_name": sig["module"], "raw_signal_name": name,
             "show_hier_name": f"{sig['hier']}/{_show_name(name, sig['msb'], sig['lsb'])}",
             "show_name": _show_name(name, sig["msb"], sig["lsb"])}
    if stype == 2:
        la["s_list"].append(entry)
        la["data_in_order"].append(entry["ip_signal_name"])
    elif stype == 3:
        la["t_list"].append(entry)
        la["trig_in_order"].append(entry["ip_signal_name"])
    else:  # 4: sample+trigger lives only in st_list, but appears in both orders
        la["st_list"].append(entry)
        la["data_in_order"].append(entry["ip_signal_name"])
        la["trig_in_order"].append(entry["ip_signal_name"])

    _rewrite_hqins_sections(proj, sig_info, la_info)
    _regenerate_ddf(proj, sig_info, la_info)
    shown = f"{name}[{sig['msb']}:{sig['lsb']}]" if (sig['msb'] != sig['lsb']
                                                     or slice_rng) else name
    stype_name = {2: "sample", 3: "trigger", 4: "sample+trigger"}[stype]
    print(f"[OK] Signal added: {shown} (type={stype_name}, clk={clk_name})")
    print("Tip: run -insight -run to rebuild the instrumented bitstream.")


class BreakLoop(Exception):
    pass


def del_signal(proj: dict, name: str) -> None:
    """Handle 'hqbuddy -insight -del <signal>'."""
    sig_info, la_info = _la_info_path(proj)
    removed = False
    for clk_entry in sig_info.get("module_sample_list", []):
        for mod_data in clk_entry.get("modules_sample_data", []):
            for key in ("sample_list", "trigger_list", "sample_and_trigger_list"):
                if name in mod_data[key]:
                    mod_data[key].remove(name)
                    removed = True
            mod_data["normal_signals"] = [s for s in mod_data["normal_signals"]
                                          if s["signal_name"] != name]
    for la in la_info.get("la_list", []):
        for key in ("s_list", "t_list", "st_list"):
            la[key] = [e for e in la[key] if e["raw_signal_name"] != name]
        la["data_in_order"] = [n for n in la["data_in_order"] if not n.startswith(name + "__INS")]
        la["trig_in_order"] = [n for n in la["trig_in_order"] if not n.startswith(name + "__INS")]
    if not removed:
        print(f"Error: 信号不在 HqInsight 工程中: {name}")
        sys.exit(1)
    # 空 probe 集会让 insight.debugip.create 段错误（R47：删除最后一个触发信号
    # 后的 ddf 触发集为空；红线同源）。拒绝并给出指引。
    remaining_trig = sum(len(l.get("t_list", [])) + len(l.get("st_list", []))
                         for l in la_info.get("la_list", []))
    if remaining_trig == 0:
        print("Error: 删除该信号后触发信号集为空——insight.debugip.create 会在空"
              "触发集上段错误（R47 实测）。请先 -add 另一个触发信号（-type both/"
              "trigger），或保留此信号。")
        sys.exit(1)
    _rewrite_hqins_sections(proj, sig_info, la_info)
    _regenerate_ddf(proj, sig_info, la_info)
    # 悬空触发表达式提示：被删信号若仍被 trigger 条件引用，布防会失效
    cond_path = os.path.join(proj["hqins_dir"], "hq_import", "trigger_cond.json")
    if os.path.isfile(cond_path):
        try:
            with open(cond_path, "r", encoding="utf-8") as f:
                d = json.load(f)
            for cgroup in d.get("conditions", {}).values():
                for cond in cgroup:
                    for op in cond.get("operands", []):
                        if op.get("signal_name") == name:
                            print(f"Warning: 已删除的 {name} 仍被触发条件引用（悬空）。")
                            print("         请重新 -insight -trig 设置不含它的条件，否则布防可能失效。")
                            raise BreakLoop
        except BreakLoop:
            pass
        except (OSError, json.JSONDecodeError):
            pass
    print(f"[OK] Signal removed: {name}")
    print("Tip: run -insight -run to rebuild the instrumented bitstream.")


def _write_ddf_from_la(proj: dict, la_info: dict) -> None:
    """Build the .ddf XML from .hqins [LA SIGNAL INFO] (GUI DDFGeneration equivalent).

    Trigger conditions come out as inert placeholders (ignore=yes); real armed
    conditions are written by -trig and are LOST whenever the ddf is rebuilt —
    callers that must keep the user's trigger config must not call this."""
    la = la_info["la_list"][0]
    sections = read_hqins(proj["hqins"])
    depth = _section_value(sections.get("MEMORY DEPTH INFO", [])) or "1024"
    offset = _section_value(sections.get("TRIGGER POSITION", [])) or "128"
    freq = float(_section_value(sections.get("CLOCK FREQUENCY", []), la="") or 100)
    if freq <= 0:
        # .hqins [CLOCK FREQUENCY] can be hand-edited to 0 in the GUI; keep the
        # 100 MHz default instead of ZeroDivisionError at int(1000/freq)
        print("Warning: .hqins CLOCK FREQUENCY 非法（<=0），按 100 MHz 处理。")
        freq = 100.0
    period = f"{int(1000 / freq)}ns"
    level = _section_value(sections.get("TRIGGER LEVEL", [])) or "1"
    win = "1"
    if os.path.isfile(proj["ddf"]):
        m_win = re.search(r"<window_num>(\d+)</window_num>",
                          open(proj["ddf"], encoding="utf-8", errors="replace").read())
        if m_win:
            win = m_win.group(1)
    if not la.get("clk_list"):
        print("Error: LA 缺少采样时钟条目（clk_list 为空）——多为旧版登记跨模块时钟时的")
        print("       遗留状态。请 -del 相关信号后重新 -add（首个信号需带 -clk）。")
        sys.exit(1)
    clk_net = la["clk_list"][0]["ip_signal_name"]

    def signal_xml(e, nbits, indent):
        pad = "\t" * indent
        bits = "".join(f"{pad}\t<bit>\n{pad}\t\t<net></net>\n{pad}\t</bit>\n" for _ in range(nbits))
        return (f"{pad}<signal>\n"
                f"{pad}\t<name>{e['ip_signal_name']}</name>\n"
                f"{pad}\t<show_name>{e['show_name']}</show_name>\n"
                f"{pad}\t<show_hier_name>{e['show_hier_name']}</show_hier_name>\n"
                f"{pad}\t<file></file>\n{pad}\t<lineno></lineno>\n{bits}{pad}</signal>\n")

    out = ['<?xml version="1.0" encoding="utf-8"?>', "<root>", "<version>1.0</version>",
           f"<design>{proj['top']}</design>", "<edif></edif>", f"<family>{proj['family']}</family>",
           "\t<la_core>", "\t\t<refclk>", f"\t\t\t<net>{clk_net}</net>",
           f"\t\t\t<period>{period}</period>", "\t\t</refclk>",
           "\t\t<trigger>", f"\t\t\t<level>{level}</level>"]
    for e in la["t_list"] + la["st_list"]:
        width = e["msb"] - e["lsb"] + 1
        for ctype, op, operand in (("EDGE", "RISE", None),
                                   ("ARITHM", "EQ", "1" * width),
                                   ("RANGE", "GE,LE", f"{'0' * width},{'1' * width}")):
            out.append("\t\t\t<condition>")
            out.append(f"\t\t\t\t<type>{ctype}</type>")
            out.append(f"\t\t\t\t<op>{op}</op>")
            out.append("\t\t\t\t<mask>0</mask>" if ctype == "EDGE"
                       else f"\t\t\t\t<mask>{'0' * width}</mask>")
            if operand is not None:
                out.append(f"\t\t\t\t<operand>{operand}</operand>")
            out.append(signal_xml(e, width, 4).rstrip("\n"))
            out.append("\t\t\t\t<ignore>yes</ignore>")
            out.append("\t\t\t</condition>")
    out += ["\t\t</trigger>", "\t\t<storage>", f"\t\t\t<depth>{depth}</depth>",
            f"\t\t\t<offset>{offset}</offset>", f"\t\t\t<window_num>{win}</window_num>"]
    for e in la["s_list"] + la["st_list"]:
        out.append(signal_xml(e, e["msb"] - e["lsb"] + 1, 3).rstrip("\n"))
    for e in la["clk_list"]:
        out.append(signal_xml(e, 1, 3).rstrip("\n"))
    out += ["\t\t</storage>", "\t</la_core>", "</root>"]
    with open(proj["ddf"], "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")


def _rebuild_instrumented(proj: dict, sig_info: dict, la_info: dict) -> None:
    """Rebuild insight_ip.v + hq_import_with_bscan.v from the existing .ddf — the
    GUI 保存 sequence (insight.load -> insight.debugip.create -> rtl.elaborate
    -new_rtl). Probe selections and armed trigger conditions live in the .ddf and
    are preserved; afterwards signal.inf is rewritten (elaborate blanks the hier
    column) and the .hqins JSON/LA sections are restored (elaborate loses
    show_hier_name)."""
    version = launcher.require_hqfpga_version()

    import_dir = os.path.join(proj["hqins_dir"], "hq_import")
    insight_ip = os.path.join(import_dir, "insight_ip.v")
    new_rtl_tcl = os.path.join(proj["hqins_dir"], "hq_impor_new_rtl.tcl")
    if not os.path.isfile(new_rtl_tcl):
        _write_import_tcls(proj, _vfiles_from_hqins(proj))
    _run_hqfpga_cmds(version["hqfpga_path"], [
        f"insight.load {{{_tcl_path(proj['ddf'])}}}",
        f"insight.debugip.create 1 False -f {{{_tcl_path(insight_ip)}}}",
    ], cwd=proj["work_dir"])
    if not os.path.isfile(insight_ip):
        print("Error: insight.debugip.create did not produce insight_ip.v")
        sys.exit(1)
    # regenerate the instrumented netlist (hq_import_with_bscan.v)
    proc = subprocess.Popen([version["hqfpga_path"], "-cmd", new_rtl_tcl],
                            cwd=proj["work_dir"], stdout=subprocess.DEVNULL,
                            stderr=subprocess.DEVNULL)
    wait_process(proc)
    if proc.returncode != 0:
        print("Error: rtl.elaborate -new_rtl failed.")
        print("Tip: 选中的信号若已不存在（RTL 层次变了），先 -insight -del 再重试。")
        sys.exit(1)
    open(os.path.join(proj["hqins_dir"], ".hq_ins.chk_ok"), "w").close()
    la = la_info["la_list"][0]
    # signal.inf: "<name>:<module>::<hier>" lines in s/t/st order.
    # Written AFTER -new_rtl, because elaborate rewrites it with an empty hier.
    def hier_of(e):
        return e["show_hier_name"].rsplit("/", 1)[0]
    inf_lines = [f"{e['raw_signal_name']}:{e['module_name']}::{hier_of(e)}"
                 for e in la["s_list"] + la["t_list"] + la["st_list"]]
    with open(os.path.join(import_dir, "signal.inf"), "w", encoding="utf-8") as f:
        f.write("\n".join(inf_lines) + "\n")
    # elaborate -new_rtl rewrites the JSON sections (losing show_hier_name); restore
    _rewrite_hqins_sections(proj, sig_info, la_info)


def _regenerate_ddf(proj: dict, sig_info: dict, la_info: dict) -> None:
    """-add/-del path: rebuild the .ddf from .hqins [LA SIGNAL INFO] — which
    resets armed trigger conditions, since the probe set changed — then
    regenerate the instrumented artifacts."""
    _write_ddf_from_la(proj, la_info)
    _rebuild_instrumented(proj, sig_info, la_info)


def run_selftest(proj: dict, signal: str, eq_value: int) -> None:
    """Regression selftest on a deterministic-counter style design.

    Arms `signal == eq_value`, captures, and asserts: (a) contiguous samples,
    (b) value increments by exactly 1 per sample post-trigger.  Any HqFPGA
    upgrade that breaks the insight chain will fail here."""
    print(f"Selftest: {signal} == {eq_value} on {proj['hqins']}")
    trig_files = [
        os.path.join(proj["hqins_dir"], "hq_import", "trigger_expr.json"),
        os.path.join(proj["hqins_dir"], "hq_import", "trigger_cond.json"),
        proj["ddf"],
    ]
    snapshot = {}
    for p in trig_files:
        if os.path.isfile(p):
            with open(p, "rb") as f:
                snapshot[p] = f.read()
    try:
        write_trigger_files(proj, parse_trig_expr([f"{signal}", "EQ", str(eq_value)]))
        run_capture(proj, timeout=30, force=False)
    finally:
        for p, data in snapshot.items():
            with open(p, "wb") as f:
                f.write(data)

    vcd = os.path.join(proj["hqins_dir"], "hq_import",
                       f"{proj['top']}_insight_0_ww.vcd")
    txt = open(vcd, encoding="utf-8", errors="replace").read()
    head, body = txt.split("$enddefinitions", 1)
    sig_id = None
    width = 0
    for m in re.finditer(r"\$var\s+\w+\s+(\d+)\s+(\S+)\s+(\S+)", head):
        if m.group(3).split("/")[-1].startswith(f"{signal}["):
            sig_id = m.group(2)
            width = int(m.group(1))
    if sig_id is None:
        print(f"FAIL: signal {signal} not found in VCD")
        sys.exit(1)
    samples = []
    t = 0
    for line in body.splitlines():
        line = line.strip()
        if line.startswith("#"):
            t = int(line[1:])
        elif line.startswith("b") and sig_id in line.split()[1:]:
            samples.append((t, line.split()[0][1:]))
    if len(samples) < 2:
        print("FAIL: no sample data")
        sys.exit(1)
    dropped = 0
    while len(samples) >= 2 and samples[-1][1] == samples[-2][1]:
        samples.pop()
        dropped += 1
    if dropped:
        print(f"(dropped {dropped} trailing re-dump artifact sample(s))")
    contig = all(samples[i + 1][0] - samples[i][0] == 1 for i in range(len(samples) - 1))
    # +1 per sample, modulo the signal width (a free counter wraps 255->0)
    mod = 1 << width if width else None
    if mod:
        inc = all((int(samples[i + 1][1], 2) - int(samples[i][1], 2)) % mod == 1
                  and samples[i + 1][0] - samples[i][0] == 1
                  for i in range(len(samples) - 1))
    else:
        inc = False
    hits = [t for t, v in samples if int(v, 2) == eq_value]
    print(f"samples={len(samples)} width={width or '?'} contiguous={contig} "
          f"+1-per-sample={inc} eq_value@{hits[0] if hits else 'never'}")
    if contig and inc:
        print("[PASS] insight chain OK (arm/trigger/capture/dump all correct)")
    else:
        print("[FAIL] insight chain broken")
        sys.exit(1)


def run_insight(args: list) -> None:
    """Entry point for 'hqbuddy -insight'."""
    hqprj_arg = None
    rest = []
    for a in args:
        if a.endswith(".hqprj") and hqprj_arg is None:
            hqprj_arg = a
        else:
            rest.append(a)

    if rest and rest[0] == "-init":
        force = "--force" in rest[1:]
        proj = resolve_insight_project(hqprj_arg, require_hqins=False)
        run_init(proj, force=force)
        return

    proj = resolve_insight_project(hqprj_arg)

    if not rest:
        show_status(proj)
        return

    if rest[0] == "-refresh":
        if len(rest) > 1:
            hint = ("（-reelab 已移除：refresh 总是重新插桩刷新信号库，无需参数。）"
                    if rest[1] == "-reelab" else "")
            print(f"Error: unknown -refresh option: {' '.join(rest[1:])}{hint}")
            sys.exit(1)
        run_refresh(proj)
        return

    if rest[0] in ("-depth", "-windows", "-level", "-position"):
        set_sample_params(proj, rest)
        return

    if rest[0] == "-ls":
        list_signals(proj, rest[1] if len(rest) > 1 else None)
        return

    if rest[0] == "-add":
        if len(rest) < 2:
            print("Error: -add requires a signal name: -insight -add <signal> [-clk <clk>] [-type sample|trigger|both]")
            sys.exit(1)
        name = rest[1]
        clk = None
        module = None
        stype = 2
        i = 2
        while i < len(rest):
            if rest[i] == "-clk" and i + 1 < len(rest):
                clk = rest[i + 1]
                i += 1
            elif rest[i] == "-module" and i + 1 < len(rest):
                module = rest[i + 1]
                i += 1
            elif rest[i] == "-type" and i + 1 < len(rest):
                if rest[i + 1] not in STYPE_TOKENS:
                    print(f"Error: invalid type: {rest[i + 1]} (sample/trigger/both)")
                    sys.exit(1)
                stype = STYPE_TOKENS[rest[i + 1]]
                i += 1
            else:
                print(f"Error: unknown -add option: {rest[i]}")
                sys.exit(1)
            i += 1
        add_signal(proj, name, clk, stype, module)
        return

    if rest[0] == "-del":
        if len(rest) < 2:
            print("Error: -del requires a signal name: -insight -del <signal>")
            sys.exit(1)
        del_signal(proj, rest[1])
        return

    if rest[0] == "-trig":
        if len(rest) == 1:
            _trig_wizard(proj)
            return
        cmd_trig(proj, rest[1:])
        return

    if rest[0] == "-capture":
        timeout = 60
        force = False
        out_prefix = None
        i = 1
        while i < len(rest):
            if rest[i] == "-force":
                force = True
            elif rest[i] == "-timeout" and i + 1 < len(rest):
                try:
                    timeout = int(rest[i + 1])
                except ValueError:
                    print(f"Error: invalid timeout: {rest[i + 1]}")
                    sys.exit(1)
                if timeout <= 0:
                    print(f"Error: -timeout 必须为正整数，得到: {timeout}")
                    sys.exit(1)
                i += 1
            elif rest[i] == "-o" and i + 1 < len(rest):
                out_prefix = os.path.abspath(rest[i + 1])
                i += 1
            else:
                print(f"Error: unknown -capture option: {rest[i]}")
                sys.exit(1)
            i += 1
        run_capture(proj, timeout, force, out_prefix)
        return

    if rest[0] == "-run":
        reuse_only = False
        legacy = False
        for a in rest[1:]:
            if a == "--reuse-only":
                reuse_only = True
            elif a == "--legacy":
                legacy = True
            else:
                print(f"Error: unknown -run option: {a} (supported: --reuse-only, --legacy)")
                sys.exit(1)
        run_flow(proj, reuse_only=reuse_only, legacy=legacy)
        return

    if rest[0] == "-program":
        allow_violation = "--allow-violation" in rest[1:]
        unknown = [a for a in rest[1:] if a != "--allow-violation"]
        if unknown:
            print(f"Error: unknown -program option: {' '.join(unknown)}")
            sys.exit(1)
        run_program(proj, allow_violation)
        return

    if rest[0] == "-sample-period":
        if len(rest) < 2:
            print("Usage: -insight -sample-period <ns>   (显式指定采样时钟周期，"
                  "对齐 ddf/hqins 并修正 VCD 时间轴)")
            sys.exit(1)
        try:
            period = float(rest[1])
        except ValueError:
            print(f"Error: -sample-period expects a number (ns), got: {rest[1]}")
            sys.exit(1)
        if period <= 0:
            print("Error: -sample-period must be > 0")
            sys.exit(1)
        sync_sample_freq(proj, explicit_period=period)
        return

    if rest[0] == "-selftest":
        signal, eq_value = "sig", 128
        i = 1
        while i < len(rest):
            if rest[i] == "-signal" and i + 1 < len(rest):
                signal = rest[i + 1]
                i += 1
            elif rest[i] == "-value" and i + 1 < len(rest):
                eq_value = int(rest[i + 1], 0)
                i += 1
            else:
                print(f"Error: unknown -selftest option: {rest[i]}")
                sys.exit(1)
            i += 1
        run_selftest(proj, signal, eq_value)
        return

    print(f"Error: unknown -insight option: {' '.join(rest)}")
    sys.exit(1)
