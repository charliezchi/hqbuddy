"""Clock-domain FF location extraction from an XPN.

Ports the official extr_slice_ff_loc utility (hqfpga xpn_util.tcl): walk the
pins of a clock net, keep the SLICEL/SLICEM loads, and emit one line per FF
primitive — physical location (sloc + FF slot, e.g. R22C32.A5FF) plus the
driven net name.  Useful for clock-region / congestion analysis.
"""

import glob
import os
import re
import sys

from . import launcher
from .viewer import locate_xpn, run_xpn_tcl

# Official extr_slice_ff_loc body, minus the xpn.read handling (hqbuddy
# generates the xpn.read line itself).
_FFLOC_PROC = """\
proc hqbuddy_ffloc {clk_name to_listf} {
    set net [obj.get "\\{$clk_name\\}"]
    if {$net == ""} {
        puts "Unable to get clock net $clk_name"
        return
    }

    set outf [open $to_listf "w"]

    set fflist ""

    obj.foreach pin p $net {
        set inst [obj.info $p owner]
        if {[obj.info $inst type] == "instance"} {
            set vw [obj.inst.info $inst view]
            set cell [obj.info $vw owner]
            set cellnm [obj.info $cell name]
            if {$cellnm == "SLICEL" || $cellnm == "SLICEM"} {
                #
                # get SLICE location -- from xdata "@sloc"
                set sloc [obj.xdata.info $inst @sloc value]
                #
                # get FF sub-location -- from xdata "@ncl.prim"
                set prim_list [obj.xdata.info $inst @ncl.prim value]
                set pm_len [llength $prim_list]
                for {set i 0} {$i < $pm_len} {incr i} {
                    set loc [lindex $prim_list $i]
                    incr i
                    set name [lindex $prim_list $i]
                    if {[string first "FF" $loc] >= 0} {
                        lappend fflist [list "${sloc}.${loc}" $name]
                    }
                }
            }
        };# if is instance
    }
    puts "-> output locations of FF in clock domain {$clk_name} to file $to_listf "
    set sorted_list [lsort -dict -index 0 $fflist]
    foreach pair $sorted_list {
        set loc [lindex $pair 0]
        set name [lindex $pair 1]
        puts $outf [format "%-20s %s" $loc $name]
    }
    close $outf
};# proc hqbuddy_ffloc"""


def _print_summary(txt_abs: str, clk: str) -> None:
    """One-screen digest: FF count, slice count, row/col span."""
    try:
        with open(txt_abs, encoding="utf-8", errors="replace") as f:
            locs = [m.group(1) for line in f
                    if (m := re.match(r"^(R\d+C\d+)", line))]
    except OSError as e:
        print(f"Warning: cannot read output for summary: {e}")
        return
    n = len(locs)
    if n == 0:
        print(f"Warning: 0 FF locations extracted — clock net '{clk}' was "
              f"not found or drives no SLICEL/SLICEM FFs "
              f"(check the exact net name, e.g. via -xpn inspect).")
        return
    rows = [int(re.match(r"R(\d+)C", s).group(1)) for s in locs]
    cols = [int(re.search(r"C(\d+)", s).group(1)) for s in locs]
    print(f"FF locations: {n} in {len(set(locs))} slices "
          f"(rows R{min(rows)}-R{max(rows)}, cols C{min(cols)}-C{max(cols)})")


def run_ffloc(clk: str, xpn_path: str | None = None,
              output_name: str | None = None) -> None:
    """
    Extract SLICE FF locations of one clock domain from an XPN to a text file.

    Args:
        clk: Clock net name (exact, e.g. wscanclk).
        xpn_path: XPN physical netlist; None auto-detects a single *.xpn in
            the current directory.  Placement info is enough — routing not
            required.
        output_name: Output text path; default
            <xpn stem>_<clk>_ffloc.txt next to the input.
    """
    xpn_abs = locate_xpn(xpn_path, "-ffloc", routed=False)

    if output_name:
        txt_abs = os.path.abspath(
            output_name if output_name.lower().endswith(".txt")
            else output_name + ".txt")
    else:
        safe_clk = re.sub(r"[^A-Za-z0-9_.-]+", "_", clk)
        txt_abs = os.path.splitext(xpn_abs)[0] + f"_{safe_clk}_ffloc.txt"
    os.makedirs(os.path.dirname(txt_abs), exist_ok=True)

    print(f"XPN: {os.path.basename(xpn_abs)}")
    version = launcher.require_hqfpga_version()

    body = _FFLOC_PROC.splitlines()
    body.append(f"hqbuddy_ffloc {{{clk}}} {{{txt_abs}}}")
    run_xpn_tcl(version, xpn_abs, body, os.path.dirname(txt_abs), "ffloc")

    print("")
    if not os.path.isfile(txt_abs):
        print(f"Error: FF location file was not generated: {txt_abs}")
        print(f"  Check the hqfpga output above — common causes:")
        print(f"  - clock net '{clk}' not found in this XPN (verify with:")
        print(f"      hqbuddy -xpn inspect {os.path.basename(xpn_abs)});")
        print(f"  - xpn.read failed (input must be a text-format .xpn, not .cexpn/.edif).")
        sys.exit(1)

    print(f"FF location file ready: {txt_abs}")
    _print_summary(txt_abs, clk)
