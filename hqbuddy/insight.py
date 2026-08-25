"""HqInsight online logic analyzer: status view, trigger setup, waveform capture."""

import glob
import json
import os
import sys

# sample_type encoding in .hqins [SIGNAL JSON INFO]
SAMPLE_TYPES = {2: "sample", 3: "trigger", 4: "sample+trigger"}


def _read_hqprj_fields(hqprj_path: str, keys: tuple) -> dict:
    """Read selected KEY=VALUE fields from a .hqprj file."""
    result = {}
    with open(hqprj_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if "=" not in line:
                continue
            key, value = line.split("=", 1)
            if key in keys:
                result[key] = value
    return result


def resolve_insight_project(hqprj_arg: str | None) -> dict:
    """Resolve the HqInsight project from a .hqprj path or auto-detection.

    Returns dict with: hqprj, work_dir, hqins_dir, hqins, ddf, top, die.
    Exits with an error if the HqInsight project (hqins_run/) is missing.
    """
    if hqprj_arg:
        hqprj = hqprj_arg
    else:
        matches = glob.glob("*.hqprj")
        if not matches:
            print("Error: no .hqprj file specified and none found in current directory.")
            sys.exit(1)
        hqprj = matches[0]

    if not os.path.isfile(hqprj):
        print(f"Error: file not found: {hqprj}")
        sys.exit(1)

    hqprj = os.path.abspath(hqprj)
    work_dir = os.path.dirname(hqprj)
    fields = _read_hqprj_fields(hqprj, ("TOP_MODULE", "DIE"))
    top = fields.get("TOP_MODULE")
    die = fields.get("DIE")
    if not top or not die:
        print("Error: missing TOP_MODULE or DIE in .hqprj")
        sys.exit(1)

    hqins_dir = os.path.join(work_dir, "hqins_run")
    hqins = os.path.join(hqins_dir, "hq_import.hqins")
    ddf = os.path.join(hqins_dir, "hq_import", f"{top}_insight.ddf")

    if not os.path.isfile(hqins):
        print("Error: HqInsight project not found (no hqins_run/hq_import.hqins).")
        print("Tip: configure signals in the HqFpga GUI first, then save the project.")
        sys.exit(1)

    return {
        "hqprj": hqprj,
        "work_dir": work_dir,
        "hqins_dir": hqins_dir,
        "hqins": hqins,
        "ddf": ddf,
        "top": top,
        "die": die,
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
    """Flatten normal_signals from [SIGNAL JSON INFO] into a signal list."""
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
    print(f"Depth   : {depth or '?'}   Trigger position: {trig_pos or '?'}")
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


def run_insight(args: list) -> None:
    """Entry point for 'hqbuddy -insight'."""
    hqprj_arg = None
    rest = []
    for a in args:
        if a.endswith(".hqprj") and hqprj_arg is None:
            hqprj_arg = a
        else:
            rest.append(a)

    proj = resolve_insight_project(hqprj_arg)
    if not rest:
        show_status(proj)
        return

    print(f"Error: unknown -insight option: {' '.join(rest)}")
    sys.exit(1)
