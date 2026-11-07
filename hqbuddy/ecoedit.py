# -*- coding: utf-8 -*-
"""Text-level XPN program edits for -eco (recipes verified on FT110126).

Program fields in the XPN are plain text (e.g. "A5LUT:#LUT:O5=(A2@A4) ";
@=XOR * =AND + =OR ~=NOT; #OFF = unused), so equation/attribute edits are
direct file rewrites and need no re-route.
"""
import re


def load_xpn_text(xpn: str) -> str:
    return open(xpn, encoding="utf-8", errors="replace").read()


def comp_block(text: str, comp: str) -> str:
    """The `comp "name" { ... }` block of one component (non-greedy to the
    closing brace at column 3)."""
    m = re.search(r'comp "' + re.escape(comp) + r'"\s*\{[\s\S]*?\n   \}', text)
    return m.group(0) if m else ""


def _lut_line(block: str, lut_name: str):
    return re.search(r'"' + re.escape(lut_name) + r':#[A-Z]+[^"]*"', block)


# FF slot -> (mux program name, driving LUT program name, lut output pin)
_FF_SLOTS = {
    "AFF": ("AFFMUX", "A6LUT", "O6"),
    "A5FF": ("A5FFMUX", "A5LUT", "O5"),
    "BFF": ("BFFMUX", "B6LUT", "O6"),
    "B5FF": ("B5FFMUX", "B5LUT", "O5"),
}


def _tautology(lut_name: str, val: int) -> str:
    pin = lut_name[:2]  # A6/B5/...: the LUT's own input pin family
    if val:
        return f"({pin}+(~{pin}))"  # constant 1
    return f"({pin}*(~{pin}))"  # constant 0


def find_ff_slot(block: str, instance: str) -> str:
    m = re.search(r'primitive (\w+FF) "' + re.escape(instance) + r'"', block)
    if not m:
        return ""
    slot = m.group(1)
    return slot if slot in _FF_SLOTS else ""


def edit_force_ff(text: str, comp: str, instance: str, val: int) -> str:
    """Force one slice FF to a constant: switch its D-mux onto the local LUT
    and write a tautology/contradiction into that LUT (two coordinated program
    edits, the board-verified pattern).  Returns the new full XPN text."""
    block = comp_block(text, comp)
    if not block:
        raise SystemExit(f"Error: comp not found in XPN: {comp}")
    slot = find_ff_slot(block, instance)
    if not slot:
        raise SystemExit(f"Error: FF instance '{instance}' not found in comp {comp} "
                         f"(or not a forceable slice FF: A5FF/AFF/B5FF/BFF)")
    mux_name, lut_name, out_pin = _FF_SLOTS[slot]
    mux_old = None
    for cand in (f'"{mux_name}:AX "', f'"{mux_name}:BX "', f'"{mux_name}:#OFF "'):
        if cand in block:
            mux_old = cand
            break
    if mux_old is None:
        raise SystemExit(f"Error: {mux_name} is not AX/BX/#OFF in {comp} — its D is "
                         f"already muxed to a LUT output; use --set-lut to change "
                         f"that LUT's equation instead.")
    mux_new = f'"{mux_name}:{out_pin} "'
    line = _lut_line(block, lut_name)
    if line is None:
        raise SystemExit(f"Error: {lut_name} program line not found in {comp}")
    lut_new = f'"{lut_name}:#LUT:{out_pin}={_tautology(lut_name, val)} "'
    nb = block.replace(mux_old, mux_new, 1).replace(line.group(0), lut_new, 1)
    print(f"  [ECO] {comp}/{instance} ({slot}) -> forced {val}")
    print(f"    {mux_old.strip()}  ->  {mux_new.strip()}")
    print(f"    {line.group(0).strip()}\n    ->  {lut_new.strip()}")
    return text.replace(block, nb, 1)


def edit_set_lut(text: str, comp: str, equation: str) -> str:
    """Set the wide LUT (A6LUT) equation of one comp; enables it when #OFF."""
    block = comp_block(text, comp)
    if not block:
        raise SystemExit(f"Error: comp not found in XPN: {comp}")
    line = _lut_line(block, "A6LUT")
    if line is None:
        raise SystemExit(f"Error: A6LUT program line not found in {comp}")
    new = f'"A6LUT:#LUT:O6={equation} "'
    print(f"  [ECO] {comp}/A6LUT")
    print(f"    {line.group(0).strip()}\n    ->  {new.strip()}")
    return text.replace(block, block.replace(line.group(0), new, 1), 1)


def similar_comps(text: str, comp: str, limit: int = 5) -> list:
    low = comp.lower()
    return [n for n in re.findall(r'comp "([^"]+)"', text)
            if low in n.lower()][:limit]
