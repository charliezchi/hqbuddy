"""Device reports via the native 'udev.* commands — no design netlist needed.

Wraps dv.setup + 'udev.report / 'udev.iotype.report / 'udev.pkg.report in a
throwaway hqfpga session and post-processes the output:

- arch   : tile-grid map (two 36xN grids: tile types and site names), resource
           Count summary.  Rendered as colored HTML (default), CSV, or the raw
           native text.
- iotype : IO electrical-standard support table (native text).
- pkg    : package pins (IO/site/tile/bank/desc), native text + a CSV for
           spreadsheet filtering.
"""

import glob
import os
import re
import subprocess
import sys

from . import device, launcher


def _resolve_part(target: str | None) -> str | None:
    """Positional target -> device part.  None triggers cwd .hqprj lookup,
    then the interactive part picker."""
    if target:
        if target.lower().endswith(".hqprj"):
            if not os.path.isfile(target):
                print(f"Error: file not found: {target}")
                sys.exit(1)
            return device.get_device(target)
        return target

    candidates = sorted(glob.glob("*.hqprj"))
    if len(candidates) == 1:
        print(f"Using project device from {candidates[0]}")
        return device.get_device(candidates[0])
    if len(candidates) > 1:
        print("Error: multiple .hqprj files in cwd, pass one explicitly:")
        for c in candidates:
            print(f"  {c}")
        sys.exit(1)

    print("No .hqprj in cwd — pick a device (type to search, Enter to confirm):")
    return device.pick_device_interactive()


def _run_hqfpga_sections(family: str, part: str, sections: list,
                         base: str) -> dict:
    """One hqfpga session per section (the 'udev.* commands interfere with
    each other within a single session).

    arch / iotype print to stdout and capture fine; 'udev.pkg.report writes
    console-direct (lost under pipes) but supports native -file."""
    version = launcher.require_hqfpga_version()
    sections_out: dict = {}
    for name in sections:
        out_path = f"{base}_{name}.txt"
        tcl_path = os.path.join(os.environ.get("TEMP", os.getcwd()),
                                "_hqbuddy_udev.tcl")
        tcl_path = tcl_path.replace(os.sep, "/")
        if name == "pkg":
            out_tcl = out_path.replace(os.sep, "/")
            body = (f"dv.setup {family} {part}\n"
                    f"'udev.pkg.report -file {{{out_tcl}}}\nexit\n")
        else:
            body = (f"dv.setup {family} {part}\n"
                    f"puts \"@@UDEV@@\"\n'udev.report\nexit\n"
                    if name == "arch" else
                    f"dv.setup {family} {part}\n"
                    f"puts \"@@UDEV@@\"\n'udev.iotype.report\nexit\n")
        with open(tcl_path, "w", encoding="utf-8") as f:
            f.write(body)
        try:
            proc = subprocess.run([version["hqfpga_path"], "-cmd", tcl_path],
                                  capture_output=True)
            out = proc.stdout.decode("utf-8", errors="replace")
            if not out.strip():
                out = proc.stdout.decode("gbk", errors="replace")
        finally:
            if os.path.exists(tcl_path):
                os.remove(tcl_path)

        if name == "pkg":
            if not os.path.isfile(out_path):
                print(f"Error: section '{name}' produced no file ({out_path}).")
                _die_section(name, proc)
            sections_out[name] = open(out_path, encoding="utf-8",
                                      errors="replace").read()
            continue

        lines = []
        seen = False
        for line in out.splitlines():
            if "@@UDEV@@" in line:
                seen = True
                continue
            if seen:
                lines.append(line)
        while lines and (not lines[0].strip()
                         or lines[0].startswith(("Info:", "====", "####", "= "))
                         or "HqFpga(TM)" in lines[0]
                         or lines[0].startswith(("Launching", "Copyright"))):
            lines.pop(0)
        if not seen or not lines:
            print(f"Error: section '{name}' produced no output.")
            _die_section(name, proc)
        sections_out[name] = "\n".join(lines)
    return sections_out


def _die_section(name: str, proc) -> None:
    tail = (proc.stderr or b"").decode("utf-8", errors="replace").strip()
    if tail:
        print(tail[-400:])
    print(f"  (section '{name}' failed — check the part name)")
    sys.exit(1)


def _parse_grids(arch_text: str) -> tuple[list, list]:
    """Extract the two RxC grids that follow the '[V]: Grid:' header.

    Grid 1 holds tile types (PLB/CIB/EBR/DSP/PT/PB/...), grid 2 the site
    names.  Returns (tile_grid, site_grid), each a list of token rows."""
    lines = arch_text.splitlines()
    grids = []
    i = 0
    while i < len(lines):
        m = re.match(r"\[V\]:\s*Grid:\s*\((\d+),\s*(\d+)\)", lines[i])
        if m:
            rows_wanted = int(m.group(1))
            i += 2  # skip the column-index header line
            grid = []
            while i < len(lines) and len(grid) < rows_wanted \
                    and re.match(r"^\d+\t", lines[i]):
                grid.append(lines[i].split("\t")[1:])
                i += 1
            grids.append(grid)
            # 紧随其后的第二张同尺寸网格（site 名称图），无独立标题
            if i < len(lines) and re.match(r"^\d+\t", lines[i]):
                grid2 = []
                while i < len(lines) and len(grid2) < rows_wanted \
                        and re.match(r"^\d+\t", lines[i]):
                    grid2.append(lines[i].split("\t")[1:])
                    i += 1
                grids.append(grid2)
        else:
            i += 1
    tile_grid = grids[0] if grids else []
    site_grid = grids[1] if len(grids) > 1 else []
    return tile_grid, site_grid


def _parse_counts(arch_text: str) -> list:
    return [(m.group(1), int(m.group(2)))
            for m in re.finditer(r"Count (\S+) : (\d+)", arch_text)]


def _token_class(tok: str) -> str:
    if tok in (".", ""):
        return "empty"
    for prefix, cls in (("PLB", "plb"), ("CIB", "cib"), ("EBR", "ebr"),
                        ("DSP", "dsp"), ("PT", "io"), ("PB", "io"),
                        ("PTS", "io")):
        if tok.startswith(prefix):
            return cls
    return "ip"


_COLORS = {"plb": "#c8e6c9", "cib": "#cfd8dc", "ebr": "#ffe0b2",
           "dsp": "#e1bee7", "io": "#b3e5fc", "ip": "#ffcdd2"}
_LEGEND = [("PLB", "plb", "逻辑块"), ("CIB", "cib", "互连开关"),
           ("EBR", "ebr", "块存储"), ("DSP", "dsp", "DSP"),
           ("PT/PB/PTS", "io", "IO tile"), ("其它硬核", "ip", "PLL/JTAG/CM3 等")]


def _render_html(part: str, tile_grid, site_grid, counts) -> str:
    def render_grid(grid, show_text: bool):
        rows = []
        for r, row in enumerate(grid):
            cells = [f'<td class="idx">{r}</td>']
            for c, tok in enumerate(row):
                cls = _token_class(tok)
                tip = f"R{r}C{c} = {tok}" if tok != "." else f"R{r}C{c}"
                text = tok if show_text and tok != "." else ""
                cells.append(f'<td class="{cls}" title="{tip}">{text}</td>')
            rows.append("<tr>" + "".join(cells) + "</tr>")
        header = "<tr><td></td>" + "".join(
            f'<td class="idx">{c}</td>' for c in range(len(grid[0]))) + "</tr>"
        return ("<table class='grid'>" + header + "".join(rows) + "</table>")

    legend = "".join(
        f'<span class="lg"><span class="sw" style="background:{_COLORS[cls]}"></span>'
        f'{label}（{desc}）</span>'
        for label, cls, desc in _LEGEND)
    count_rows = "".join(
        f"<tr><td>{n}</td><td>{v}</td></tr>" for n, v in counts)
    site_tbl = ""
    if site_grid:
        site_tbl = ("<h2>Site 名称图（悬停查看坐标）</h2>"
                    + render_grid(site_grid, show_text=True))
    return f"""<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>{part} — device architecture</title>
<style>
body {{ font-family: Consolas, monospace; margin: 16px; }}
h2 {{ font-size: 15px; margin: 14px 0 6px; }}
.lg {{ margin-right: 14px; font-family: sans-serif; font-size: 13px; }}
.sw {{ display: inline-block; width: 12px; height: 12px;
      border: 1px solid #999; vertical-align: -1px; margin-right: 4px; }}
table.grid {{ border-collapse: collapse; }}
table.grid td {{ width: 15px; height: 15px; font-size: 9px;
                border: 1px solid #eee; text-align: center;
                vertical-align: middle; overflow: hidden; }}
td.idx {{ background: #f5f5f5; width: 24px; font-size: 9px; color: #666; }}
td.plb {{ background: {_COLORS['plb']}; }}
td.cib {{ background: {_COLORS['cib']}; }}
td.ebr {{ background: {_COLORS['ebr']}; }}
td.dsp {{ background: {_COLORS['dsp']}; }}
td.io  {{ background: {_COLORS['io']}; }}
td.ip  {{ background: {_COLORS['ip']}; }}
table.cnt {{ border-collapse: collapse; font-family: sans-serif; font-size: 13px; }}
table.cnt td, table.cnt th {{ border: 1px solid #ccc; padding: 2px 10px; }}
</style></head><body>
<h1>{part}</h1>
<p>{legend}</p>
<h2>Tile 类型图</h2>
{render_grid(tile_grid, show_text=False)}
{site_tbl}
<h2>资源 Count</h2>
<table class="cnt"><tr><th>Resource</th><th>Count</th></tr>{count_rows}</table>
</body></html>"""


def _grid_csv(grid) -> str:
    lines = []
    for r, row in enumerate(grid):
        lines.append(str(r) + "," + ",".join(row))
    return "\n".join(lines) + "\n"


_PKG_RE = re.compile(r"IO = (.*?), site = (.*?), tile = (.*?), bank = (.*?), desc = (.*)$")


def _pkg_csv(pkg_text: str) -> str:
    lines = ["IO,site,tile,bank,desc"]
    for line in pkg_text.splitlines():
        m = _PKG_RE.match(line.strip())
        if m:
            lines.append(",".join(g.strip() for g in m.groups()))
    return "\n".join(lines) + "\n"


def run_udev(target: str | None, sections: list, out_dir: str | None = None,
             arch_fmt: str = "html") -> None:
    """
    Generate native device reports ('udev.*), no design netlist required.

    Args:
        target: Part name, .hqprj path, or None.  None looks for a single
            .hqprj in cwd first, then opens the interactive part picker.
        sections: Subset of ('arch', 'iotype', 'pkg').
        out_dir: Output directory (default cwd).
        arch_fmt: 'html' (colored tile map), 'csv', or 'text' (native dump).
    """
    part = _resolve_part(target)
    if not part:
        print("Error: no device selected.")
        sys.exit(1)
    family = device.get_family_for_device(part)
    if not family:
        print(f"Error: unknown part '{part}' (not in this version's dv_list.xml).")
        sys.exit(1)

    out_dir = out_dir or os.getcwd()
    os.makedirs(out_dir, exist_ok=True)
    base = os.path.join(out_dir, part)

    print(f"Device: {part} (family {family})")
    sections_out = _run_hqfpga_sections(family, part, sections, base)

    written = []
    if "arch" in sections_out:
        p = base + "_arch.txt"
        open(p, "w", encoding="utf-8").write(sections_out["arch"].strip("\n") + "\n")
        written.append(p)
        text = sections_out["arch"]
        tile_grid, site_grid = _parse_grids(text)
        if arch_fmt == "html":
            p = base + "_arch.html"
            open(p, "w", encoding="utf-8").write(
                _render_html(part, tile_grid, site_grid, _parse_counts(text)))
            written.append(p)
        elif arch_fmt == "csv":
            p = base + "_arch_tiles.csv"
            open(p, "w", encoding="utf-8").write(_grid_csv(tile_grid))
            written.append(p)
            if site_grid:
                p = base + "_arch_sites.csv"
                open(p, "w", encoding="utf-8").write(_grid_csv(site_grid))
                written.append(p)
    if "iotype" in sections_out:
        p = base + "_iotype.txt"
        open(p, "w", encoding="utf-8").write(sections_out["iotype"].strip("\n") + "\n")
        written.append(p)
    if "pkg" in sections_out:
        # <base>_pkg.txt was written natively via 'udev.pkg.report -file
        written.append(base + "_pkg.txt")
        p = base + "_pkg.csv"
        open(p, "w", encoding="utf-8").write(_pkg_csv(sections_out["pkg"]))
        written.append(p)

    print("")
    for p in written:
        print(f"Written: {p}")
