"""Main-flow report digest: parse implementation reports into a compact summary.

Understands BOTH report families:
- hqbuddy -build flow (project root): fmax.rpt, <top>_slack.rpt / final_ta.rpt,
  res_place.rpt / res_pack.rpt / res_rtl.rpt
- GUI / insight flows (hq_run/, hqins_impl/): ratio.rpt, <top>_slack.rpt,
  res_perspective.rpt, _place.rpt

Timing reports in both English and Chinese (GBK) formats are supported:
  English: '* Path N' / 'Slack : X ps' / 'Type : Setup|Hold'
  Chinese: '* 路径 N' / '时间余量 : X ps' / '类型 : 建立(setup)|保持(hold)'
"""

import glob
import os
import re
import sys
from typing import Optional


def _read(path: str) -> str:
    """Read a report; try UTF-8 then GBK (Chinese-locale reports are GBK)."""
    for enc in ("utf-8", "gbk"):
        try:
            with open(path, "r", encoding=enc, errors="strict") as f:
                return f.read()
        except UnicodeDecodeError:
            continue
        except OSError:
            return ""
    return ""


def _report_roots(work: str) -> list:
    """Report locations: -build puts reports in the project root; GUI/insight
    flows put them in hq_run/ (main flow) or hqins_impl/ (insight flow)."""
    return [work,
            os.path.join(work, "hq_run"),
            os.path.join(work, "hqins_run", "hq_import", "hqins_impl")]


def _find_report(work: str, names: list) -> Optional[str]:
    for root in _report_roots(work):
        for name in names:
            p = os.path.join(root, name)
            if os.path.isfile(p):
                return p
    return None


def _top_name(work: str) -> Optional[str]:
    for f in glob.glob(os.path.join(work, "*.hqprj")):
        try:
            with open(f, "r", encoding="utf-8", errors="replace") as fh:
                for line in fh:
                    if line.startswith("TOP_MODULE="):
                        t = line.split("=", 1)[1].strip()
                        if t and t != "NONE":
                            return t
        except OSError:
            continue
    return None


def _parse_fmax(work: str) -> list:
    out = []
    path = _find_report(work, ["fmax.rpt", "pl_ta.rpt"])
    if not path:
        return out
    txt = _read(path)
    m = re.search(r"# FMAX Summary\s*#+\s*\n(.*?)(?=\n#|\Z)", txt, re.S)
    if not m:
        return out
    block = m.group(1)
    clk = re.search(r"Slowest clock\s*:\s*(\S+)", block)
    per = re.search(r"Minimum period\s*:\s*([\d.]+)\s*([pn]s)", block)
    fmax = re.search(r"Maximum frequency\s*:\s*([\d.]+)\s*(MHz|GHz|kHz)", block)
    out.append({
        "clock": clk.group(1) if clk else "?",
        "period": per.group(1) + per.group(2) if per else "?",
        "fmax": (fmax.group(1) + " " + fmax.group(2)) if fmax else "?",
        "src": os.path.basename(path),
    })
    return out


def _parse_wns(work: str, top: Optional[str]) -> Optional[dict]:
    """Parse worst setup/hold slack; English and Chinese (GBK) formats both OK."""
    candidates = []
    if top:
        candidates.append(f"{top}_slack.rpt")
    candidates.append("final_ta.rpt")
    path = _find_report(work, candidates)
    if not path:
        return None
    txt = _read(path)
    kind_map = {"建立": "Setup", "Setup": "Setup", "保持": "Hold", "Hold": "Hold",
                "Removal": "Removal", "Recovery": "Recovery"}
    worst: dict = {}
    count: dict = {}
    blocks = re.split(r"\*{4,}\s*\*\s*(?:Path|路径)\s+(\d+)\s*\*{4,}", txt)
    for seg in blocks[1:]:
        m = (re.search(r"Slack\s*:\s*(-?[\d.]+)\s*(ps|ns)", seg)
             or re.search(r"时间余量\s*[:：]\s*(-?[\d.]+)\s*(ps|ns)", seg))
        if not m:
            continue
        val = float(m.group(1)) * (1000 if m.group(2) == "ns" else 1)
        tm = (re.search(r"Type\s*[:：]\s*(\S+)", seg)
              or re.search(r"类型\s*[:：]\s*(\S+)", seg))
        raw_kind = (tm.group(1) if tm else "").rstrip(":").rstrip("()")
        kind = kind_map.get(raw_kind, kind_map.get(raw_kind[:2], ""))
        cur = worst.get(kind)
        if cur is None or val < cur:
            worst[kind] = val
        count[kind] = count.get(kind, 0) + 1
    setup = worst.get("Setup")
    hold = worst.get("Hold")
    if setup is None and hold is None:
        return None
    return {
        "wns_setup_ps": setup,
        "wns_hold_ps": hold,
        "setup_met": setup is None or setup >= 0,
        "hold_met": hold is None or hold >= 0,
        "paths": sum(count.values()),
        "src": os.path.basename(path),
    }


def _parse_util(work: str) -> Optional[dict]:
    for root in _report_roots(work):
        for name in ("res_place.rpt", "ratio.rpt", "res_pack.rpt", "res_rtl.rpt"):
            path = os.path.join(root, name)
            if not os.path.isfile(path):
                continue
            txt = _read(path)
            if "Device Utilization Summary" not in txt:
                continue
            rows: dict = {}
            for m in re.finditer(
                    r"^\|\s*([A-Za-z][A-Za-z0-9 ()\/+\-]*?)\s*\|\s*(\d+)\s*\|"
                    r"\s*(\d+)\s*\|\s*(\d+)\s*%", txt, re.M):
                key = m.group(1).strip()
                if key in ("IO", "SLICE", "LUT", "FFLAT") or "BLOCK-RAM" in key \
                        or key.startswith("DSP") or key.startswith("SERDES"):
                    rows.setdefault(key, (int(m.group(2)), int(m.group(3)),
                                          int(m.group(4))))
            if rows:
                return {"src": os.path.basename(path), "rows": rows,
                        "root": os.path.dirname(path)}
    return None


def _bit_files(work: str) -> list:
    out = []
    for pat in ("*.bin", "*.bit"):
        out.extend(glob.glob(os.path.join(work, pat)))
        out.extend(glob.glob(os.path.join(work, "hq_run", pat)))
        out.extend(glob.glob(os.path.join(work, "hqins_run", "hq_import",
                                          "hqins_impl", pat)))
    return sorted(set(out))


def run_report(args: list) -> None:
    """Entry point for 'hqbuddy -report [<dir-or-hqprj>]'."""
    if args and (args[0].endswith(".hqprj") or os.path.isdir(args[0])):
        target = args[0]
        work = (os.path.dirname(os.path.abspath(target))
                if target.endswith(".hqprj") else os.path.abspath(target))
    else:
        matches = glob.glob("*.hqprj")
        if not matches:
            print("Error: no .hqprj in current directory; pass a project or directory.")
            sys.exit(1)
        work = os.getcwd()

    print(f"Project dir : {work}")
    top = _top_name(work)

    def locate(names: list) -> Optional[str]:
        return _find_report(work, names)

    slack_names = ([f"{top}_slack.rpt"] if top else []) + ["final_ta.rpt"]
    fmax_path = _find_report(work, ["fmax.rpt", "pl_ta.rpt"])
    slack_path = _find_report(work, slack_names)
    util_path = None
    for root in _report_roots(work):
        for name in ("res_place.rpt", "ratio.rpt", "res_pack.rpt", "res_rtl.rpt"):
            p = os.path.join(root, name)
            if os.path.isfile(p):
                util_path = p
                break
        if util_path:
            break

    rows = [
        ("flow tcl", ["run_hqprj.tcl"]),
        ("fmax", ["fmax.rpt", "pl_ta.rpt"]),
        ("slack", slack_names),
        ("util", ["res_place.rpt", "ratio.rpt", "res_pack.rpt", "res_rtl.rpt"]),
        ("netlist view", ["aft_place.xpn"]),
    ]
    for label, names in rows:
        found = _find_report(work, names)
        print(f"  {label:13s}: {'YES' if found else '-  '}  {found or names[0]}")

    bins = _bit_files(work)
    if bins:
        import time
        print("  bitstream    : " + ", ".join(
            os.path.basename(b)
            + f" ({time.strftime('%H:%M', time.localtime(os.path.getmtime(b)))})"
            for b in bins))

    print()
    for f in _parse_fmax(work):
        print(f"Fmax      : {f['clock']} = {f['fmax']}  (min period {f['period']})")
    w = _parse_wns(work, top)
    if w:
        s, h = w["wns_setup_ps"], w["wns_hold_ps"]
        if s is not None:
            print(f"WNS setup : {'+' if s >= 0 else ''}{s} ps  "
                  f"({'MET' if w['setup_met'] else 'VIOLATED'})")
        if h is not None:
            print(f"WNS hold  : {'+' if h >= 0 else ''}{h} ps  "
                  f"({'MET' if w['hold_met'] else 'VIOLATED'})")
        print(f"            (worst of {w['paths']} reported paths, {w['src']})")
    u = _parse_util(work)
    if u:
        print(f"Utilization ({u['src']}):")
        for key, (used, avail, ratio) in u["rows"].items():
            print(f"  {key:16s}: {used:6d} / {avail:6d}  ({ratio}%)")
    if not (_parse_fmax(work) or w or u):
        print("No reports found. Run the implementation flow first (hqbuddy -build).")
