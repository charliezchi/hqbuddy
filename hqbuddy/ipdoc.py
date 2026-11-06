# -*- coding: utf-8 -*-
"""IP manual locator: hqbuddy -ipdoc <ip> [--list] [--no_open]

Locates the user manual (UG*.pdf) of an IP under <HQ>/build/ipcreator/
sup_files/ipdepot/<IP>/ and opens it.  Read-only; the index of all manuals
lives in the hqfpga skill (references/ip_doc_index.md).
"""
import fnmatch
import glob
import os
import sys

from . import launcher


def _ipdepot_dir() -> str:
    root = launcher.resolve_hqfpga_root()
    if not root:
        print("Error: no HqFPGA versions found.")
        sys.exit(1)
    d = os.path.join(root, "build", "ipcreator", "sup_files", "ipdepot")
    if not os.path.isdir(d):
        print(f"Error: ipdepot not found in this installation: {d}")
        sys.exit(1)
    return d


def _match_ips(depot: str, pattern: str) -> list:
    names = sorted(n for n in os.listdir(depot)
                   if os.path.isdir(os.path.join(depot, n)))
    low = pattern.lower()
    exact = [n for n in names if n.lower() == low]
    if exact:
        return exact
    globbed = [n for n in names if fnmatch.fnmatch(n.lower(), low)]
    if globbed:
        return globbed
    return [n for n in names if low in n.lower()]


def run_ipdoc(args: list) -> None:
    """Entry for 'hqbuddy -ipdoc <ip> [--list] [--no_open]'."""
    listing = "--list" in args
    no_open = "--no_open" in args
    args = [a for a in args if a not in ("--list", "--no_open")]
    if args and args[0].startswith("-"):
        print(f"Error: unknown -ipdoc option: {args[0]}")
        sys.exit(1)
    if not args and not listing:
        print("Usage: hqbuddy -ipdoc <ip> [--list] [--no_open]")
        print("       定位并打开 IP 的 UG 用户手册（PDF）；--list 列出匹配的 IP 与手册；")
        print("       全量索引见 hqfpga skill references/ip_doc_index.md（84 IP / 97 UG）。")
        sys.exit(1)

    depot = _ipdepot_dir()
    pattern = args[0] if args else "*"
    matches = _match_ips(depot, pattern)
    if not matches:
        print(f"Error: no IP matches '{pattern}' in ipdepot.")
        print("Tip: hqbuddy -ipdoc --list 列出全部 IP；或用 hqbuddy -gen_hqip 的交互选择器搜索。")
        sys.exit(1)

    if listing or (len(matches) > 1 and not args):
        print(f"IPs matching '{pattern}' ({len(matches)}):")
        for n in matches:
            ugs = sorted(glob.glob(os.path.join(depot, n, "**", "UG*.pdf"),
                                   recursive=True))
            tag = f"  ({len(ugs)} UG manual)" if ugs else ""
            print(f"  {n}{tag}")
        if listing:
            return
        if len(matches) > 1:
            print("Error: multiple IPs match — pass one explicitly.")
            sys.exit(1)
    name = matches[0]
    ip_dir = os.path.join(depot, name)
    ugs = sorted(set(glob.glob(os.path.join(ip_dir, "**", "UG*.pdf"),
                               recursive=True)))
    print(f"IP: {name}")
    if not ugs:
        aux = sorted(glob.glob(os.path.join(ip_dir, "**", "*.pdf"), recursive=True)) \
            + sorted(glob.glob(os.path.join(ip_dir, "**", "readme*.txt"),
                               recursive=True))
        print("Error: no UG manual for this IP.")
        for a in aux[:5]:
            print(f"  aux doc: {a}")
        sys.exit(1)
    for u in ugs:
        print(f"  manual: {u}")
    target = ugs[0]
    if no_open:
        return
    try:
        os.startfile(target)  # noqa: S606 - Windows only
        print(f"[OK] opened: {os.path.basename(target)}")
        if len(ugs) > 1:
            print(f"Note: {len(ugs)} UG manuals found — opened the first; "
                  f"see the list above for the rest.")
    except OSError as e:
        print(f"Error: cannot open PDF: {e}")
        sys.exit(1)
