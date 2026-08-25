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


def resolve_insight_project(hqprj_arg: str | None, require_hqins: bool = True) -> dict:
    """Resolve the HqInsight project from a .hqprj path or auto-detection.

    Returns dict with: hqprj, work_dir, hqins_dir, hqins, ddf, top, die, family.
    Exits with an error if the HqInsight project (hqins_run/) is missing,
    unless require_hqins is False (e.g. for -init).
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
    fields = _read_hqprj_fields(hqprj, ("TOP_MODULE", "DIE", "FAMILY"))
    top = fields.get("TOP_MODULE")
    die = fields.get("DIE")
    family = fields.get("FAMILY")
    if not top or not die:
        print("Error: missing TOP_MODULE or DIE in .hqprj")
        sys.exit(1)

    hqins_dir = os.path.join(work_dir, "hqins_run")
    hqins = os.path.join(hqins_dir, "hq_import.hqins")
    ddf = os.path.join(hqins_dir, "hq_import", f"{top}_insight.ddf")

    if require_hqins and not os.path.isfile(hqins):
        print("Error: HqInsight project not found (no hqins_run/hq_import.hqins).")
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


# --- Trigger condition setup (-trig) ---

ARITH_OPS = ("EQ", "GT", "LT", "NE", "LE", "GE")
EDGE_OPS = {"RISE": "Rising Edge", "FALL": "Falling Edge", "BOTH": "B Edge", "X": "X"}


def _bits_lsb_first(value: int, width: int) -> str:
    """Binary string, LSB first (ddf operand encoding: 16'd1 -> '1000000000000000')."""
    return bin(value)[2:].zfill(width)[::-1]


def _parse_value(token: str) -> int:
    """Parse an integer literal (decimal or 0x hex)."""
    try:
        return int(token, 0)
    except ValueError:
        print(f"Error: invalid value: {token}")
        sys.exit(1)


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
                print("Error: missing condition before AND/OR")
                sys.exit(1)
            groups.append(current)
            if combine and combine != w.upper():
                print("Error: cannot mix AND and OR")
                sys.exit(1)
            combine = w.upper()
            current = []
        else:
            current.append(w)
    if current:
        groups.append(current)

    if len(groups) > 2:
        print("Error: at most 2 trigger conditions (hardware has 2 compare units)")
        sys.exit(1)
    if len(groups) == 2 and not combine:
        print("Error: two conditions require AND or OR between them")
        sys.exit(1)

    conds = []
    for g in groups:
        negate = False
        if g and g[0].upper() == "NOT":
            negate = True
            g = g[1:]
        if len(g) < 2:
            print(f"Error: incomplete condition: {' '.join(g)}")
            sys.exit(1)
        signal, op = g[0], g[1].upper()
        if op in ARITH_OPS:
            if len(g) != 3:
                print(f"Error: {op} requires a value: {signal} {op} <value>")
                sys.exit(1)
            conds.append({"signal": signal, "kind": "arith", "op": op,
                          "value": _parse_value(g[2]), "negate": negate})
        elif op == "RANGE":
            if len(g) != 4:
                print(f"Error: RANGE requires two bounds: {signal} RANGE <lo> <hi>")
                sys.exit(1)
            conds.append({"signal": signal, "kind": "range",
                          "lo": _parse_value(g[2]), "hi": _parse_value(g[3]),
                          "negate": negate})
        elif op in EDGE_OPS:
            if len(g) != 2:
                print(f"Error: {op} takes no value: {signal} {op}")
                sys.exit(1)
            conds.append({"signal": signal, "kind": "edge", "op": op, "negate": negate})
        else:
            print(f"Error: unknown trigger operator: {op}")
            print(f"       arithmetic: {'/'.join(ARITH_OPS)}; range: RANGE lo hi; edge: RISE/FALL/BOTH/X")
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
            print(f"Error: signal not found in HqInsight project: {cond['signal']}")
            print(f"       trigger-capable signals: {avail or '(none)'}")
            sys.exit(1)
        sig = match[0]
        if sig["sample_type"] not in (3, 4):
            print(f"Error: signal is sample-only, cannot trigger: {cond['signal']}")
            sys.exit(1)
        if cond["kind"] == "edge" and sig["msb"] != sig["lsb"]:
            print(f"Error: edge trigger requires a 1-bit signal: {cond['signal']}")
            sys.exit(1)
        result.append(sig)
    return result


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
            level["trigger_type"] = "Range"
            level["left_value_type"] = "GT"
            level["left_value_v"] = f"{width}'d{cond['lo']}"
            level["left_value_b"] = bin(cond["lo"])[2:].zfill(width)
            level["right_value_type"] = "LT"
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


def _write_trigger_cond(proj: dict, parsed: dict, sigs: list) -> None:
    """Write trigger_cond.json (runtime combination expression)."""
    multi = len(parsed["conds"]) == 2
    if multi:
        or_eq = parsed["combine"] == "OR"
        expr = "B0|B1" if or_eq else "B0&B1"
        base_op = 0b101 if or_eq else 0b011
    else:
        or_eq = False
        expr = "B0"
        base_op = 0

    operands = []
    for i, (cond, sig) in enumerate(zip(parsed["conds"], sigs)):
        op_bits = base_op | (0b1000 if cond["negate"] else 0)
        if cond["negate"]:
            expr = expr.replace(f"B{i}", f"!B{i}")
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
            "and_eq": not or_eq, "or_eq": or_eq,
            "negate_eq": parsed["negate_all"], "operands": operands}]}}, f, indent=2)


def _write_ddf(proj: dict, parsed: dict, sigs: list) -> None:
    """Update the .ddf comparator blocks (ignore flag, op, mask, operand)."""
    import xml.etree.ElementTree as ET

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
                mask_el.text = "0" * width
            if operand_el is not None:
                operand_el.text = _bits_lsb_first(cond["value"], width)
        elif cond["kind"] == "range":
            if op_el is not None:
                op_el.text = "GT,LT"
            if mask_el is not None:
                mask_el.text = "0" * width
            if operand_el is not None:
                operand_el.text = (f"{_bits_lsb_first(cond['lo'], width)},"
                                   f"{_bits_lsb_first(cond['hi'], width)}")
        else:  # edge: ddf op uses GUI spelling (RISE/FALL/BOTH)
            if op_el is not None:
                op_el.text = cond["op"]

    tree.write(proj["ddf"], encoding="utf-8", xml_declaration=True)


def write_trigger_files(proj: dict, parsed: dict) -> None:
    """Validate and write all three trigger files consistently."""
    sigs = _check_trigger_signals(proj, parsed)
    _write_trigger_expr(proj, parsed, sigs)
    _write_trigger_cond(proj, parsed, sigs)
    _write_ddf(proj, parsed, sigs)


def cmd_trig(proj: dict, tokens: list) -> None:
    """Handle 'hqbuddy -insight -trig ...'."""
    parsed = parse_trig_expr(tokens)
    write_trigger_files(proj, parsed)
    desc = []
    for c in parsed["conds"]:
        prefix = "NOT " if c["negate"] else ""
        if c["kind"] == "arith":
            desc.append(f"{prefix}{c['signal']} {c['op']} {c['value']}")
        elif c["kind"] == "range":
            desc.append(f"{prefix}{c['signal']} RANGE {c['lo']} {c['hi']}")
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
        print("Error: no trigger-capable signals in HqInsight project.")
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
            lo = input("Lower bound (exclusive): ").strip()
            hi = input("Upper bound (exclusive): ").strip()
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


def _run_hqfpga_cmds(hqfpga_exe: str, cmds: list, cwd: str) -> None:
    """Run hqfpga.exe -cmd with a temporary tcl; abort on abnormal exit."""
    import subprocess
    import tempfile

    tcl = "\n".join(cmds) + "\nexit\n"
    with tempfile.NamedTemporaryFile("w", suffix=".tcl", delete=False, encoding="utf-8") as f:
        f.write(tcl)
        tcl_path = f.name
    try:
        proc = subprocess.run([hqfpga_exe, "-cmd", tcl_path], cwd=cwd,
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    finally:
        os.unlink(tcl_path)
    if proc.returncode != 0:
        print(f"Error: hqfpga.exe exited abnormally (code {proc.returncode}).")
        sys.exit(1)


def _play_svf(cable_exe: str, svf_path: str) -> list:
    """Play an SVF via cable.exe; return the Received:TDO values from svf.log.

    cable.exe rewrites svf.log (next to itself) on every run.
    """
    import subprocess

    log_path = os.path.join(os.path.dirname(cable_exe), "svf.log")
    proc = subprocess.run([cable_exe, "--svf", _tcl_path(svf_path),
                           "--outTDO", CAPTURE_OUT_TDO, "--debug"],
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if proc.returncode != 0:
        print(f"Error: cable.exe failed to play SVF (code {proc.returncode}).")
        sys.exit(1)
    values = []
    try:
        with open(log_path, "r", encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
    except OSError:
        lines = []
    for line in lines:
        line = line.strip()
        if line.startswith("Received:TDO(") and line.endswith(")"):
            values.append(line[len("Received:TDO("):-1])
    return values


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
    """Combined trigger (is_ct) = two conditions in trigger_cond.json."""
    try:
        with open(cond_path, "r", encoding="utf-8") as f:
            cond = json.load(f)
        return len(cond["conditions"]["0"][0].get("operands", [])) == 2
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
    import xml.etree.ElementTree as ET

    force_ddf = proj["ddf"].replace(".ddf", "_force.ddf")
    tree = ET.parse(proj["ddf"])
    for ignore in tree.getroot().iter("ignore"):
        ignore.text = "yes"
    tree.write(force_ddf, encoding="utf-8", xml_declaration=True)
    return force_ddf


def run_capture(proj: dict, timeout: int, force: bool) -> None:
    """Handle 'hqbuddy -insight -capture': arm trigger, wait, read waveform, dump VCD."""
    import time

    from . import launcher

    version = launcher.resolve_hqfpga_version()
    if not version:
        print("Error: no HqFPGA installation found (use -cfg to set up).")
        sys.exit(1)
    hqfpga_exe = version["hqfpga_path"]
    cable_exe = version["cable_path"]
    if not version.get("has_cable") or not os.path.isfile(cable_exe):
        print(f"Error: cable.exe not found in {version['path']}")
        sys.exit(1)

    import_dir = os.path.join(proj["hqins_dir"], "hq_import")
    prefix = os.path.join(import_dir, f"{proj['top']}_insight")
    cond_path = os.path.join(import_dir, "trigger_cond.json")
    if not os.path.isfile(cond_path):
        print("Error: no trigger condition set. Use -insight -trig first.")
        sys.exit(1)
    if not os.path.isfile(proj["ddf"]):
        print(f"Error: .ddf not found: {proj['ddf']}")
        sys.exit(1)

    sections = read_hqins(proj["hqins"])
    depth = int(_section_value(sections.get("MEMORY DEPTH INFO", [])) or 1024)
    status_bits = depth.bit_length() - 1 + 2
    offset = int(_section_value(sections.get("TRIGGER POSITION", [])) or 0)
    expr_op = _capture_expr_op(cond_path)
    is_ct = _is_combined_trigger(cond_path)

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
                     f"-ct_no C0 -cond_path {_tcl_path(cond_path)}")
    else:
        trig_args = f"-is_continuous False -is_ct False -expr_op {expr_op}"

    # 1. Arm the trigger
    _run_hqfpga_cmds(hqfpga_exe, [
        f"{gen}.start -svf_file_path {_tcl_path(svf('arm.svf'))} "
        f"-device_die {proj['die']} -ddf_file {_tcl_path(ddf)}",
        f"{gen}.jtag_detect",
        f"{gen}.la_reset {common}",
        f"{gen}.la_offset {common} -offset {offset}",
        f"{gen}.la_set_trig_cond {common} {trig_args}",
        f"{gen}.la_reset {common}",
        f"{gen}.write",
    ], cwd=proj["work_dir"])
    _play_svf(cable_exe, svf("arm.svf"))
    print("[OK] Trigger armed.")

    # 2. Wait for the trigger (status done bit), unless -force
    _run_hqfpga_cmds(hqfpga_exe, [
        f"{gen}.start -svf_file_path {_tcl_path(svf('status.svf'))} "
        f"-device_die {proj['die']} -ddf_file {_tcl_path(ddf)}",
        f"{gen}.la_status {common}",
        f"{gen}.write",
    ], cwd=proj["work_dir"])

    overflow, pointer = False, 0
    if force:
        print("[OK] Force trigger, capturing immediately.")
    else:
        print(f"Waiting for trigger (timeout {timeout}s, Ctrl-C to abort)...")
        deadline = time.time() + timeout
        while True:
            time.sleep(0.5)
            tdo = _play_svf(cable_exe, svf("status.svf"))
            if len(tdo) >= 2:
                overflow, done, pointer = _parse_status(tdo[1], status_bits)
                if done:
                    print(f"[OK] Triggered (pointer={pointer}, overflow={overflow}).")
                    break
            if time.time() >= deadline:
                print(f"Error: trigger timeout ({timeout}s). Re-run with -force to capture immediately.")
                sys.exit(1)

    # 3. Read status + waveform (only 'pointer' words if the buffer never wrapped)
    limit = depth if (force or overflow) else max(pointer, 1)
    _run_hqfpga_cmds(hqfpga_exe, [
        f"{gen}.start -svf_file_path {_tcl_path(svf('dump.svf'))} "
        f"-device_die {proj['die']} -ddf_file {_tcl_path(ddf)}",
        f"{gen}.la_status {common}",
        f"{gen}.write",
        f"{gen}.la_waveform {common} -limit {limit}",
        f"{gen}.write",
    ], cwd=proj["work_dir"])
    tdo = _play_svf(cable_exe, svf("dump.svf"))

    # TDO lines: the first two are status words (short hex), the rest are
    # waveform words whose hex length depends on the LA data width (do NOT
    # hardcode a length — narrow designs read back short words).
    def _is_hex(v: str) -> bool:
        return bool(v) and all(c in "0123456789abcdefABCDEF" for c in v)
    header = list(tdo[:2])
    data = [v for v in tdo[2:] if _is_hex(v)]
    if not force and len(tdo) >= 2:
        overflow, done, pointer = _parse_status(tdo[1], status_bits)
    if len(data) < limit:
        print(f"Error: expected {limit} waveform words, got {len(data)}.")
        sys.exit(1)
    while len(header) < 2:
        header.insert(0, "0")
    tdo_path = os.path.join(import_dir, "tdo_data.txt")
    with open(tdo_path, "w", encoding="utf-8") as f:
        f.write("\n".join(header + data[:limit]) + "\n")

    # 4. Convert to VCD
    _run_hqfpga_cmds(hqfpga_exe, [
        f"{gen}.start -svf_file_path {_tcl_path(svf('vcd.svf'))} "
        f"-device_die {proj['die']} -ddf_file {_tcl_path(proj['ddf'])}",
        f"{gen}.dump_vcd {common} -tdo_path {_tcl_path(tdo_path)} -window_num 1 "
        f"-is_hier True -out_path_prefix {_tcl_path(prefix)} "
        f"-diff_info {overflow}|{pointer}",
    ], cwd=proj["work_dir"])

    vcd = f"{prefix}_0_ww.vcd"
    if not os.path.isfile(vcd):
        print("Error: VCD was not generated (dump_vcd failed silently).")
        sys.exit(1)
    print(f"[OK] Waveform captured: {vcd}")
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
        print("Trigger moment: not found in VCD.")


def run_flow(proj: dict) -> None:
    """Handle 'hqbuddy -insight -run': run the instrumented implementation flow."""
    from . import launcher

    version = launcher.resolve_hqfpga_version()
    if not version:
        print("Error: no HqFPGA installation found (use -cfg to set up).")
        sys.exit(1)
    hqfpga_exe = version["hqfpga_path"]

    import subprocess
    import tempfile

    tcl = f"run_hqprj2hqins_flow {{{_tcl_path(proj['hqprj'])}}}\nexit\n"
    with tempfile.NamedTemporaryFile("w", suffix=".tcl", delete=False, encoding="utf-8") as f:
        f.write(tcl)
        tcl_path = f.name
    print(f"Running instrumented flow for {proj['hqprj']} ...")
    try:
        proc = subprocess.run([hqfpga_exe, "-cmd", tcl_path], cwd=proj["work_dir"])
    finally:
        os.unlink(tcl_path)
    if proc.returncode != 0:
        print(f"Error: hqfpga.exe flow failed (code {proc.returncode}).")
        sys.exit(1)
    print("[OK] Instrumented flow done.")


# --- Signal selection (-init/-ls/-add/-del) ---

STYPE_TOKENS = {"sample": 2, "trigger": 3, "both": 4}


def _initial_hqins(proj: dict, vfiles: list) -> str:
    """Build the initial .hqins skeleton (as the GUI writes it on entering HqInsight)."""
    import time

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
    lines = "\n".join(f"lappend vfiles {f}" for f in vfiles)
    base = f"""set WORK_DIR {wdir}
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
    with open(os.path.join(proj["hqins_dir"], "hq_impor_t.tcl"), "w", encoding="utf-8") as f:
        f.write(t)
    with open(os.path.join(proj["hqins_dir"], "hq_impor_new_rtl.tcl"), "w", encoding="utf-8") as f:
        f.write(new_rtl)


def run_init(proj: dict) -> None:
    """Handle 'hqbuddy -insight -init': create hqins_run skeleton and elaborate."""
    from . import launcher
    from .hqprj_parser import extract_filelist

    version = launcher.resolve_hqfpga_version()
    if not version:
        print("Error: no HqFPGA installation found (use -cfg to set up).")
        sys.exit(1)
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

    import subprocess
    tcl_path = os.path.join(proj["hqins_dir"], "hq_impor_t.tcl")
    proc = subprocess.run([hqfpga_exe, "-cmd", tcl_path], cwd=proj["work_dir"])
    if proc.returncode != 0:
        print(f"Error: elaborate failed (code {proc.returncode}).")
        sys.exit(1)
    dump = os.path.join(proj["hqins_dir"], "hq_import", "hq_import_parser_staticelab_dump.json")
    if not os.path.isfile(dump):
        print("Error: elaborate produced no signal database.")
        sys.exit(1)
    print(f"[OK] HqInsight project initialized: {proj['hqins']}")


def _load_dump_json(proj: dict) -> list:
    """Load the elaborate signal database; returns the modules list."""
    dump = os.path.join(proj["hqins_dir"], "hq_import", "hq_import_parser_staticelab_dump.json")
    if not os.path.isfile(dump):
        print("Error: signal database not found. Run -insight -init first.")
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
    selected = {s["name"] for s in _collect_signals(_load_signal_info(proj) or {})}
    if keyword:
        kw = keyword.lower()
        catalog = [c for c in catalog if kw in c["name"].lower()]
    print(f"Signals ({len(catalog)}): (* = selected)")
    for c in catalog:
        width = c["msb"] - c["lsb"] + 1
        mark = "*" if c["name"] in selected else " "
        print(f" {mark} {c['name']}[{width}b]  module={c['module']}")


def _ip_name(name: str, module: str) -> str:
    return f"{name}__INS_{module}__INS0"


def _show_name(name: str, msb: int, lsb: int) -> str:
    return f"{name}[{msb}:{lsb}]" if msb != lsb else f"{name}[{lsb}]"


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


def add_signal(proj: dict, name: str, clk: str | None, stype: int, module: str | None = None) -> None:
    """Handle 'hqbuddy -insight -add <signal> [-clk <clk>] [-type ...] [-module <mod>]'."""
    catalog = _signal_catalog(proj)
    matches = [c for c in catalog if c["name"] == name]
    if module:
        matches = [c for c in matches if c["module"] == module or c["module"].split("[")[0] == module]
    if not matches:
        print(f"Error: signal not found in design: {name}")
        sys.exit(1)
    if len(matches) > 1:
        mods = ", ".join(c["module"] for c in matches)
        print(f"Error: '{name}' exists in multiple modules: {mods}; pick one with -module")
        sys.exit(1)
    sig = matches[0]

    sig_info, la_info = _la_info_path(proj)
    msl = sig_info.setdefault("module_sample_list", [])
    clk_entry = next((e for e in msl if e["clk_module_name"] == sig["module"]), None)
    if clk_entry is None:
        if not clk:
            print(f"Error: first signal of module {sig['module']} requires -clk <clock signal>.")
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
        print(f"Error: signal already added: {name}")
        sys.exit(1)
    key = {2: "sample_list", 3: "trigger_list", 4: "sample_and_trigger_list"}[stype]
    mod_data[key].append(name)
    mod_data["normal_signals"].append({
        "signal_name": name, "sample_type": stype,
        "raw_msb": sig["msb"], "raw_lsb": sig["lsb"],
        "slice_msb": sig["msb"], "slice_lsb": sig["lsb"]})

    # [LA SIGNAL INFO]
    la_list = la_info.setdefault("la_list", [])
    la = la_list[0] if la_list else None
    if la is None:
        la = {"clk_list": [], "data_in_order": [], "s_list": [], "st_list": [],
              "t_list": [], "trig_in_order": []}
        la_list.append(la)
    clk_sig = next((c for c in catalog if c["name"] == clk_name and c["module"] == sig["module"]), None)
    if not la["clk_list"] and clk_sig:
        la["clk_list"].append({
            "ip_signal_name": _ip_name(clk_name, sig["module"]), "lsb": 0, "msb": 0,
            "module_name": sig["module"], "raw_signal_name": clk_name,
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
    print(f"[OK] Signal added: {name} (type={stype}, clk={clk_name})")
    print("Tip: run -insight -run to rebuild the instrumented bitstream.")


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
        print(f"Error: signal not in HqInsight project: {name}")
        sys.exit(1)
    _rewrite_hqins_sections(proj, sig_info, la_info)
    _regenerate_ddf(proj, sig_info, la_info)
    print(f"[OK] Signal removed: {name}")
    print("Tip: run -insight -run to rebuild the instrumented bitstream.")


def _regenerate_ddf(proj: dict, sig_info: dict, la_info: dict) -> None:
    """Regenerate the .ddf from .hqins [LA SIGNAL INFO], then refresh insight_ip.v
    and the instrumented netlist. rtl.elaborate -new_rtl rewrites the .hqins JSON
    sections (and loses show_hier_name), so the sections are restored afterwards."""
    from . import launcher

    la = la_info["la_list"][0]
    sections = read_hqins(proj["hqins"])
    depth = _section_value(sections.get("MEMORY DEPTH INFO", [])) or "1024"
    offset = _section_value(sections.get("TRIGGER POSITION", [])) or "128"
    freq = float(_section_value(sections.get("CLOCK FREQUENCY", []), la="") or 100)
    period = f"{int(1000 / freq)}ns"
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
           "\t\t<trigger>", "\t\t\t<level>1</level>"]
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
            f"\t\t\t<offset>{offset}</offset>", "\t\t\t<window_num>1</window_num>"]
    for e in la["s_list"] + la["st_list"]:
        out.append(signal_xml(e, e["msb"] - e["lsb"] + 1, 3).rstrip("\n"))
    for e in la["clk_list"]:
        out.append(signal_xml(e, 1, 3).rstrip("\n"))
    out += ["\t\t</storage>", "\t</la_core>", "</root>"]
    with open(proj["ddf"], "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")

    version = launcher.resolve_hqfpga_version()
    if not version:
        print("Error: no HqFPGA installation found (use -cfg to set up).")
        sys.exit(1)

    import_dir = os.path.join(proj["hqins_dir"], "hq_import")
    insight_ip = os.path.join(import_dir, "insight_ip.v")
    new_rtl_tcl = os.path.join(proj["hqins_dir"], "hq_impor_new_rtl.tcl")
    _run_hqfpga_cmds(version["hqfpga_path"], [
        f"insight.load {_tcl_path(proj['ddf'])}",
        f"insight.debugip.create 1 False -f {_tcl_path(insight_ip)}",
    ], cwd=proj["work_dir"])
    if not os.path.isfile(insight_ip):
        print("Error: insight.debugip.create did not produce insight_ip.v")
        sys.exit(1)
    # regenerate the instrumented netlist (hq_import_with_bscan.v)
    if os.path.isfile(new_rtl_tcl):
        import subprocess
        proc = subprocess.run([version["hqfpga_path"], "-cmd", new_rtl_tcl],
                              cwd=proj["work_dir"], stdout=subprocess.DEVNULL,
                              stderr=subprocess.DEVNULL)
        if proc.returncode != 0:
            print("Error: rtl.elaborate -new_rtl failed.")
            sys.exit(1)
    open(os.path.join(proj["hqins_dir"], ".hq_ins.chk_ok"), "w").close()
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


def run_insight(args: list) -> None:
    """Entry point for 'hqbuddy -insight'."""
    hqprj_arg = None
    rest = []
    for a in args:
        if a.endswith(".hqprj") and hqprj_arg is None:
            hqprj_arg = a
        else:
            rest.append(a)

    if rest[0] == "-init":
        proj = resolve_insight_project(hqprj_arg, require_hqins=False)
        run_init(proj)
        return

    proj = resolve_insight_project(hqprj_arg)
    if not rest:
        show_status(proj)
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
                i += 1
            else:
                print(f"Error: unknown -capture option: {rest[i]}")
                sys.exit(1)
            i += 1
        run_capture(proj, timeout, force)
        return

    if rest[0] == "-run":
        run_flow(proj)
        return

    print(f"Error: unknown -insight option: {' '.join(rest)}")
    sys.exit(1)
