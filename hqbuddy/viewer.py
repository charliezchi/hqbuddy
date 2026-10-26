"""XPN viewers: shared hqfpga-TCL plumbing plus the ChipEditor floorplan and
rtviewer routing viewers.

Mirrors the officially documented usage (hqfpga xpn_util.tcl): xpn.read the
physical netlist, run the per-viewer generation command(s) via hqfpga -cmd,
then launch the viewer exe under build/<tool>/ detached.  Unlike the official
scripts the generated inputs persist next to the XPN (same semantics as
-heatmap) so the viewer can be reopened later.
"""

import glob
import os
import re
import subprocess
import sys

from . import launcher


def tcl_path(path: str) -> str:
    """Absolute path with forward slashes (TCL-safe)."""
    return os.path.abspath(path).replace(os.sep, "/")


def count_route_sections(xpn_path: str) -> int:
    """Count per-signal route sections — 0 means the XPN was never routed."""
    try:
        with open(xpn_path, encoding="utf-8", errors="replace") as f:
            return len(re.findall(r"^\s*route\s*$", f.read(), re.MULTILINE))
    except OSError:
        return -1


def locate_xpn(xpn_path: str | None, cmd: str, routed: bool = True) -> str:
    """Resolve the input XPN for a viewer command: auto-detect a single *.xpn
    in the current directory; reject project/internal-netlist inputs.

    Args:
        xpn_path: User-supplied path or None for auto-detect.
        cmd: Command name used in error messages (e.g. '-heatmap').
        routed: Whether the command needs routing info (wording only).
    Returns:
        Absolute XPN path (exits on error).
    """
    if xpn_path is None:
        candidates = sorted(glob.glob("*.xpn"))
        if not candidates:
            print(f"Error: no .xpn file in the current directory "
                  f"(pass one explicitly: hqbuddy {cmd} <file.xpn>)")
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
        need = "a routed .xpn physical netlist" if routed \
            else "a text-format .xpn physical netlist"
        print(f"Error: {cmd} needs {need}.")
        if xpn_path.lower().endswith(".hqprj"):
            print(f"  For a project flow result, run 'hqbuddy -xpn' first,")
            print(f"  then 'hqbuddy {cmd} hq.xpn'.")
        else:
            print(f"  .cexpn is the flow's internal binary netlist — "
                  f"xpn.read cannot parse it.")
        sys.exit(1)
    return xpn_path


def warn_unrouted(xpn_abs: str, consequence: str) -> None:
    """Pre-check route sections and warn when the XPN carries none."""
    n_routes = count_route_sections(xpn_abs)
    if n_routes == 0:
        print(f"Warning: this XPN has no route sections (placed-only?) — "
              f"{consequence}.")
    elif n_routes > 0:
        print(f"XPN: {os.path.basename(xpn_abs)} ({n_routes} routed signals)")


def run_xpn_tcl(version: dict, xpn_abs: str, body: list[str],
                workdir: str, tag: str) -> None:
    """Write a temp TCL (xpn.read + body + exit), run it via hqfpga -cmd in
    the foreground, then remove the TCL."""
    temp_tcl = os.path.join(workdir, f"_hqbuddy_{tag}.tcl")
    with open(temp_tcl, "w", encoding="utf-8") as f:
        f.write(f"xpn.read {tcl_path(xpn_abs)}\n")
        for line in body:
            f.write(line + "\n")
        f.write("exit\n")
    try:
        print(f"Generated temp TCL: {temp_tcl}")
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


def find_viewer_exe(version: dict, subdir: str, exe: str) -> str:
    """Path of a viewer exe under build/<subdir>/ of the install."""
    return os.path.join(version["path"], "build", subdir, exe)


def launch_viewer(exe_path: str, args: list[str], label: str) -> None:
    """Launch a viewer GUI detached so hqbuddy can exit independently."""
    if not os.path.isfile(exe_path):
        print(f"Warning: {os.path.basename(exe_path)} not found: {exe_path}")
        print(f"  Open the generated input manually with the viewer.")
        return
    creationflags = subprocess.DETACHED_PROCESS | subprocess.CREATE_NEW_PROCESS_GROUP
    subprocess.Popen([exe_path] + args, creationflags=creationflags,
                     close_fds=True)
    print(f"Launched {label}")


def run_floorplan(xpn_path: str | None, output_prefix: str | None = None,
                  open_viewer: bool = True, lang: str = "chs") -> None:
    """
    Generate ChipEditor inputs from an XPN and open the floorplan viewer.

    Args:
        xpn_path: XPN physical netlist; None auto-detects a single *.xpn in
            the current directory.
        output_prefix: Output prefix; default <xpn stem>_floorplan next to the
            input.  Writes <prefix>.cdev and <prefix>.cexpn (plus the
            .cexpn.json the converter emits alongside).
        open_viewer: Launch ChipEditor.exe after generation (default True;
            pass False via -no_open for agent/silent workflows).
        lang: Viewer language, 'chs' (default) or 'eng'.
    """
    xpn_abs = locate_xpn(xpn_path, "-floorplan", routed=False)

    if output_prefix:
        p = output_prefix
        for ext in (".cexpn", ".cdev"):
            if p.lower().endswith(ext):
                p = p[:-len(ext)]
        if os.path.isdir(p) or p.endswith(("/", "\\")):
            stem = os.path.splitext(os.path.basename(xpn_abs))[0]
            p = os.path.join(p, stem + "_floorplan")
        prefix = os.path.abspath(p)
    else:
        prefix = os.path.splitext(xpn_abs)[0] + "_floorplan"
    os.makedirs(os.path.dirname(prefix), exist_ok=True)
    cdev = prefix + ".cdev"
    cexpn = prefix + ".cexpn"

    print(f"XPN: {os.path.basename(xpn_abs)}")
    version = launcher.require_hqfpga_version()

    run_xpn_tcl(version, xpn_abs, [
        f"dconv.dev2chipedit {tcl_path(cdev)}",
        f"dconv.xpn2chipedit {tcl_path(cexpn)}",
    ], os.path.dirname(prefix), "floorplan")

    print("")
    missing = [p for p in (cdev, cexpn) if not os.path.isfile(p)]
    if missing:
        print(f"Error: ChipEditor input(s) were not generated: "
              f"{', '.join(missing)}")
        print(f"  xpn.read/dconv likely failed — check the hqfpga output above")
        print(f"  (input must be a text-format .xpn, not .cexpn/.edif).")
        sys.exit(1)
    print(f"Floorplan inputs ready: {cdev}")
    print(f"                        {cexpn}")
    if os.path.isfile(cexpn + ".json"):
        print(f"                        {cexpn}.json (converter sidecar)")

    if open_viewer:
        print("")
        launch_viewer(find_viewer_exe(version, "chipeditor", "ChipEditor.exe"),
                      ["-d", cdev, "-x", cexpn, "-lang", lang],
                      f"floorplan viewer ({lang})")


def run_routing(xpn_path: str | None, output_name: str | None = None,
                open_viewer: bool = True, lang: str = "chs") -> None:
    """
    Generate the rtviewer routing-result JSON from a routed XPN and open it.

    Args:
        xpn_path: Routed XPN physical netlist; None auto-detects a single
            *.xpn in the current directory.
        output_name: Output JSON path; default <xpn stem>_routing.json next
            to the input.
        open_viewer: Launch rtviewer.exe after generation (default True;
            pass False via -no_open for agent/silent workflows).
        lang: Viewer language, 'chs' (default) or 'eng'.
    """
    xpn_abs = locate_xpn(xpn_path, "-routing")

    if output_name:
        json_abs = os.path.abspath(
            output_name if output_name.lower().endswith(".json")
            else output_name + ".json")
    else:
        json_abs = os.path.splitext(xpn_abs)[0] + "_routing.json"
    os.makedirs(os.path.dirname(json_abs), exist_ok=True)

    warn_unrouted(xpn_abs, "the routing view will be empty")
    version = launcher.require_hqfpga_version()

    # rtviewer -d wants the full part name; dv.info name is authoritative
    # (the XPN header splits device/performance/package), so have the TCL
    # write it to a sidecar we read and delete afterwards.
    devname_f = json_abs + ".devname"
    run_xpn_tcl(version, xpn_abs, [
        f"rt.genRoutingResult -filename {tcl_path(json_abs)}",
        f"set __f [open {tcl_path(devname_f)} w];"
        f" puts $__f [dv.info name]; close $__f",
    ], os.path.dirname(json_abs), "routing")

    print("")
    if not os.path.isfile(json_abs):
        print(f"Error: routing JSON was not generated: {json_abs}")
        print(f"  xpn.read likely failed — check the hqfpga output above")
        print(f"  (input must be a text-format routed .xpn, not .cexpn/.edif).")
        sys.exit(1)

    dev = ""
    if os.path.isfile(devname_f):
        with open(devname_f, encoding="utf-8", errors="replace") as f:
            dev = f.read().strip()
        os.remove(devname_f)
    print(f"Routing JSON ready: {json_abs}")
    if not dev:
        print("Warning: device name unavailable (dv.info name) — "
              "launch the viewer manually:")
        print(f"  rtviewer.exe -d <part> -r {json_abs} -l {lang}")

    if open_viewer and dev:
        print("")
        launch_viewer(find_viewer_exe(version, "rtviewer", "rtviewer.exe"),
                      ["-d", dev, "-r", json_abs, "-l", lang],
                      f"routing viewer ({lang})")
