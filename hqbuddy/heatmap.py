"""Routing heatmap: generate rtheatmap viewer JSON from a routed XPN.

Reproduces the GUI's routing-heatmap flow headlessly: xpn.read the routed
physical netlist, run the internal 'rt.genResourceUsage command to write the
viewer input JSON (the .rt_heatmap.json the GUI generates into hq_temp), then
launch build/rtheatmap/rtheatmap.exe -w <json> -l <lang>.
"""

import glob
import json
import os
import re
import subprocess
import sys

from . import launcher


def _tcl_path(path: str) -> str:
    """Absolute path with forward slashes (TCL-safe)."""
    return os.path.abspath(path).replace(os.sep, "/")


def _count_route_sections(xpn_path: str) -> int:
    """Count per-signal route sections — 0 means the XPN was never routed."""
    try:
        with open(xpn_path, encoding="utf-8", errors="replace") as f:
            return len(re.findall(r"^\s*route\s*$", f.read(), re.MULTILINE))
    except OSError:
        return -1


def _generate_heatmap_tcl(xpn_abs: str, json_abs: str) -> str:
    temp_tcl = os.path.join(os.path.dirname(json_abs), "_hqbuddy_heatmap.tcl")
    with open(temp_tcl, "w", encoding="utf-8") as f:
        f.write(f"xpn.read {_tcl_path(xpn_abs)}\n"
                f"'rt.genResourceUsage -filename {_tcl_path(json_abs)}\n"
                f"exit\n")
    return temp_tcl


def _print_summary(json_abs: str) -> None:
    """Print a one-screen digest of the generated heatmap JSON."""
    try:
        with open(json_abs, encoding="utf-8") as f:
            d = json.load(f)
    except (OSError, ValueError) as e:
        print(f"Warning: cannot parse generated JSON for summary: {e}")
        return
    dev = d.get("devicedata", {})
    wires = d.get("wiredata", [[]])
    cells = [v for row in wires[0] for v in row] if wires and wires[0] else []
    nz = sum(1 for v in cells if v)
    print(f"Device : {dev.get('adiename', '?')}"
          f" ({dev.get('acol', '?')}x{dev.get('arow', '?')},"
          f" {len(dev.get('data', []))} tiles)")
    if cells:
        print(f"Usage  : {nz}/{len(cells)} wire-usage cells nonzero"
              f" (sum {sum(cells)}, max {max(cells)})")
        if nz == 0:
            print("Warning: all-zero usage — the XPN carried no routing"
                  " (placed-only?), the heatmap will be empty.")


def _launch_viewer(version: dict, json_abs: str, lang: str) -> None:
    rtheatmap = os.path.join(version["path"], "build", "rtheatmap", "rtheatmap.exe")
    if not os.path.isfile(rtheatmap):
        print(f"Warning: rtheatmap.exe not found: {rtheatmap}")
        print(f"  Open the JSON manually with the rtheatmap viewer.")
        return
    creationflags = subprocess.DETACHED_PROCESS | subprocess.CREATE_NEW_PROCESS_GROUP
    subprocess.Popen([rtheatmap, "-w", json_abs, "-l", lang],
                     creationflags=creationflags, close_fds=True)
    print(f"Launched routing heatmap viewer ({lang})")


def run_heatmap(xpn_path: str | None, output_name: str | None = None,
                open_viewer: bool = True, lang: str = "chs") -> None:
    """
    Generate the routing-heatmap viewer JSON from a routed XPN and open it.

    Args:
        xpn_path: Routed XPN physical netlist; None auto-detects a single
            *.xpn in the current directory.
        output_name: Output JSON path; default <xpn stem>_heatmap.json next
            to the input.
        open_viewer: Launch rtheatmap.exe after generation (default True;
            pass False via -no_open for agent/silent workflows).
        lang: Viewer language, 'chs' (default) or 'eng'.
    """
    if xpn_path is None:
        candidates = sorted(glob.glob("*.xpn"))
        if not candidates:
            print("Error: no .xpn file in the current directory "
                  "(pass one explicitly: hqbuddy -heatmap <file.xpn>)")
            sys.exit(1)
        if len(candidates) > 1:
            print("Error: multiple .xpn files in cwd, pass one explicitly:")
            for c in candidates:
                print(f"  {c}")
            sys.exit(1)
        xpn_path = candidates[0]

    xpn_path = os.path.abspath(xpn_path)
    if not os.path.isfile(xpn_path):
        print(f"Error: file not found: {xpn_path}")
        sys.exit(1)
    if xpn_path.lower().endswith((".hqprj", ".cexpn")):
        print(f"Error: -heatmap needs a routed .xpn physical netlist.")
        if xpn_path.lower().endswith(".hqprj"):
            print(f"  For a project flow result, run 'hqbuddy -xpn' first,")
            print(f"  then 'hqbuddy -heatmap hq.xpn'.")
        else:
            print(f"  .cexpn is the flow's internal binary netlist — "
                  f"xpn.read cannot parse it.")
        sys.exit(1)

    if output_name:
        json_abs = os.path.abspath(
            output_name if output_name.lower().endswith(".json")
            else output_name + ".json")
    else:
        json_abs = os.path.splitext(xpn_path)[0] + "_heatmap.json"
    os.makedirs(os.path.dirname(json_abs), exist_ok=True)

    n_routes = _count_route_sections(xpn_path)
    if n_routes == 0:
        print("Warning: this XPN has no route sections (placed-only?) — "
              "the heatmap will be all-zero.")
    elif n_routes > 0:
        print(f"XPN: {os.path.basename(xpn_path)} ({n_routes} routed signals)")

    version = launcher.require_hqfpga_version()

    temp_tcl = _generate_heatmap_tcl(xpn_path, json_abs)
    try:
        print(f"Generated temp TCL: {temp_tcl}")
        print(f"Output: {json_abs}")
        cmd = [version["hqfpga_path"], "-cmd", temp_tcl]
        print(f"Launching: {' '.join(cmd)}")
        print("")
        proc = subprocess.Popen(cmd)
        try:
            proc.wait()
        except KeyboardInterrupt:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
            raise
        if proc.returncode != 0:
            print("")
            print(f"Warning: hqfpga exited with code {proc.returncode}")
    finally:
        if os.path.exists(temp_tcl):
            os.remove(temp_tcl)
            print("")
            print(f"Cleaned up temp TCL: {temp_tcl}")

    print("")
    if not os.path.isfile(json_abs):
        print(f"Error: heatmap JSON was not generated: {json_abs}")
        print(f"  xpn.read likely failed — check the hqfpga output above")
        print(f"  (input must be a text-format routed .xpn, not .cexpn/.edif).")
        sys.exit(1)

    print(f"Heatmap JSON ready: {json_abs}")
    _print_summary(json_abs)

    if open_viewer:
        print("")
        _launch_viewer(version, json_abs, lang)
