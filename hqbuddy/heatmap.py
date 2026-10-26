"""Routing heatmap: generate rtheatmap viewer JSON from a routed XPN.

The officially documented flow (hqfpga xpn_util.tcl, gui_show_heatmap):
xpn.read the routed physical netlist, run the internal 'rt.genResourceUsage
command to write the viewer input JSON (the .rt_heatmap.json the GUI
generates into hq_temp), then launch build/rtheatmap/rtheatmap.exe -w <json>
-l <lang>.
"""

import json
import os
import sys

from . import launcher
from .viewer import (find_viewer_exe, launch_viewer, locate_xpn, run_xpn_tcl,
                     tcl_path, warn_unrouted)


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
    xpn_abs = locate_xpn(xpn_path, "-heatmap")

    if output_name:
        json_abs = os.path.abspath(
            output_name if output_name.lower().endswith(".json")
            else output_name + ".json")
    else:
        json_abs = os.path.splitext(xpn_abs)[0] + "_heatmap.json"
    os.makedirs(os.path.dirname(json_abs), exist_ok=True)

    warn_unrouted(xpn_abs, "the heatmap will be all-zero")
    version = launcher.require_hqfpga_version()

    run_xpn_tcl(version, xpn_abs,
                [f"'rt.genResourceUsage -filename {tcl_path(json_abs)}"],
                os.path.dirname(json_abs), "heatmap")

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
        launch_viewer(find_viewer_exe(version, "rtheatmap", "rtheatmap.exe"),
                      ["-w", json_abs, "-l", lang],
                      f"routing heatmap viewer ({lang})")
