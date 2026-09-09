"""Main-flow report digest: parse implementation reports into a compact summary.

Parses the standard HqFpga report family produced by the implementation flow
(``run_hqprj.tcl`` / ``run_hqprj2hqins_flow``):

- ``fmax.rpt``          -> per-clock Fmax
- ``<top>_slack.rpt`` / ``final_ta.rpt`` -> worst slack (WNS)
- ``res_place.rpt`` / ``res_pack.rpt`` / ``res_rtl.rpt`` -> device utilization
- ``hqfpga.log`` / ``run_hqprj.tcl`` presence -> flow stage heuristics
"""

import glob
import os
import re
import sys


def _top_name(work: str) -> str | None:
    for f in glob.glob(os.path.join(work, "*.hqprj")):
        try:
            with open(f, "r", encoding="utf-8") as fh:
                for line in fh:
                    if line.startswith("TOP_MODULE="):
                        t = line.split("=", 1)[1].strip()
                        if t and t != "NONE":
                            return t
        except OSError:
            continue
    return None


def _read(path: str) -> str:
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            return f.read()
    except OSError:
        return ""


def _parse_fmax(work: str) -> list:
    out = []
    for name in ("fmax.rpt", "pl_ta.rpt"):
        txt = _read(os.path.join(work, name))
        m = re.search(r"# FMAX Summary\s*#+\s*\n(.*?)(?=\n#|\Z)", txt, re.S)
        if not m:
            continue
        block = m.group(1)
        clk = re.search(r"Slowest clock\s*:\s*(\S+)", block)
        per = re.search(r"Minimum period\s*:\s*([\d.]+)\s*([pn]s)", block)
        fmax = re.search(r"Maximum frequency\s*:\s*([\d.]+)\s*(MHz|GHz|kHz)", block)
        out.append({
            "clock": clk.group(1) if clk else "?",
            "period": per.group(1) + per.group(2) if per else "?",
            "fmax": (fmax.group(1) + " " + fmax.group(2)) if fmax else "?",
            "src": name,
        })
        break
    return out


def _parse_wns(work: str, top: str | None) -> dict | None:
    candidates = []
    if top:
        candidates.append(os.path.join(work, f"{top}_slack.rpt"))
    candidates.append(os.path.join(work, "final_ta.rpt"))
    for path in candidates:
        txt = _read(path)
        if not txt:
            continue
        # Split into per-path blocks; classify Setup vs Hold so the worst
        # setup slack is not polluted by hold paths (they are independent
        # sign-off checks and differ by orders of magnitude).
        blocks = re.split(r"\*{4,}\s*\*\s*Path\s+(\d+)\s*\*{4,}", txt)
        worst = {"Setup": None, "Hold": None, "": None}
        count = {"Setup": 0, "Hold": 0, "": 0}
        for seg in blocks[1:]:
            m = re.search(r"Slack\s*:\s*(-?[\d.]+)\s*(ps|ns)", seg)
            if not m:
                continue
            val = float(m.group(1)) * (1000 if m.group(2) == "ns" else 1)
            tmatch = re.search(r"Type\s*:\s*(\S+)", seg)
            kind = (tmatch.group(1) if tmatch else "").rstrip(":")
            kind = kind if kind in worst else ""
            cur = worst[kind]
            if cur is None or val < cur:
                worst[kind] = val
            count[kind] += 1
        setup, hold = worst["Setup"], worst["Hold"]
        if setup is None and hold is None:
            continue
        return {
            "wns_setup_ps": setup,
            "wns_hold_ps": hold,
            "setup_met": setup is None or setup >= 0,
            "hold_met": hold is None or hold >= 0,
            "paths": sum(count.values()),
            "src": os.path.basename(path),
        }
    return None


def _parse_util(work: str) -> dict | None:
    for name in ("res_place.rpt", "res_pack.rpt", "res_rtl.rpt"):
        txt = _read(os.path.join(work, name))
        if "Device Utilization Summary" not in txt:
            continue
        rows = {}
        for m in re.finditer(r"^\|\s*([A-Za-z][A-Za-z0-9 ()\/+\-]*?)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*%", txt, re.M):
            key = m.group(1).strip()
            if key in ("IO", "SLICE", "LUT", "FFLAT") or "BLOCK-RAM" in key or key.startswith("DSP"):
                rows.setdefault(key, (int(m.group(2)), int(m.group(3)), int(m.group(4))))
        if rows:
            return {"src": name, "rows": rows}
    return None


def _bit_files(work: str) -> list:
    out = []
    for pat in ("*.bin", "*.bit"):
        out.extend(glob.glob(os.path.join(work, pat)))
        out.extend(glob.glob(os.path.join(work, "hq_run", pat)))
    return sorted(set(out))


def run_report(args: list) -> None:
    """Entry point for 'hqbuddy -report [<dir-or-hqprj>]'."""
    if args and (args[0].endswith(".hqprj") or os.path.isdir(args[0])):
        target = args[0]
        work = os.path.dirname(os.path.abspath(target)) if target.endswith(".hqprj") else os.path.abspath(target)
    else:
        matches = glob.glob("*.hqprj")
        if not matches:
            print("Error: no .hqprj in current directory; pass a project or directory.")
            sys.exit(1)
        work = os.getcwd()

    print(f"Project dir : {work}")
    top = _top_name(work)

    files = {
        "flow tcl": "run_hqprj.tcl",
        "fmax": "fmax.rpt",
        "final TA": "final_ta.rpt",
        "slack": f"{top}_slack.rpt" if top else None,
        "util": "res_place.rpt",
        "netlist view": "aft_place.xpn",
    }
    for label, name in files.items():
        if name:
            p = os.path.join(work, name)
            print(f"  {label:13s}: {'YES' if os.path.isfile(p) else '-  '}  {name}")

    bins = _bit_files(work)
    if bins:
        import time
        print("  bitstream    : " + ", ".join(
            os.path.basename(b) + f" ({time.strftime('%H:%M', time.localtime(os.path.getmtime(b)))})"
            for b in bins))

    print()
    for f in _parse_fmax(work):
        print(f"Fmax      : {f['clock']} = {f['fmax']}  (min period {f['period']})")
    w = _parse_wns(work, top)
    if w:
        s = w["wns_setup_ps"]
        h = w["wns_hold_ps"]
        print(f"WNS setup : {'+' if s is not None and s >= 0 else ''}{s} ps  "
              f"({'MET' if w['setup_met'] else 'VIOLATED'})")
        if h is not None:
            print(f"WNS hold  : {'+' if h >= 0 else ''}{h} ps  ({'MET' if w['hold_met'] else 'VIOLATED'})")
        print(f"            (worst of {w['paths']} reported paths, {w['src']})")
    u = _parse_util(work)
    if u:
        print(f"Utilization ({u['src']}):")
        for key, (used, avail, ratio) in u["rows"].items():
            print(f"  {key:16s}: {used:6d} / {avail:6d}  ({ratio}%)")
    if not (_parse_fmax(work) or w or u):
        print("No reports found. Run the implementation flow first (hqbuddy -build).")
