# -*- coding: utf-8 -*-
"""Bitstream header info: hqbuddy -bitinfo <file.bin> [<more>|<glob> ...]

Pure-Python parse of the XiST FPGA bitstream header (same parser the -dl
downloader GUI uses): design name / device / date / size.  Read-only, no
hqfpga session, no board — useful as a download(-adjacent) sanity check
("is this really the bin I think it is, for which device?").
"""
import glob
import os
import sys

from .downloader import read_bitstream_header


def _fmt_size(n: int) -> str:
    return f"{n:,} B ({n / 1024:.1f} KB)" if n < 1024 * 1024 \
        else f"{n:,} B ({n / 1024 / 1024:.2f} MB)"


def run_bitinfo(args: list) -> None:
    """Entry for 'hqbuddy -bitinfo [<file.bin> ...] [--json]' (globs allowed)."""
    as_json = "--json" in args
    args = [a for a in args if a != "--json"]
    if not args:
        print("Usage: hqbuddy -bitinfo <file.bin> [<more>|<glob> ...] [--json]")
        print("       解析 XiST FPGA 位流头（设计名/器件/日期/大小），只读无板卡。")
        sys.exit(1)

    files: list = []
    for a in args:
        if a.startswith('-'):
            print(f"Error: unknown -bitinfo option: {a}")
            sys.exit(1)
        hits = sorted(glob.glob(a)) if any(c in a for c in "*?[") else [a]
        if not hits:
            print(f"Error: file not found: {a}")
            sys.exit(1)
        files.extend(hits)

    results = []
    for f in files:
        if not os.path.isfile(f):
            results.append({"path": f, "fpga": False, "reason": "not a file"})
            continue
        h = read_bitstream_header(f)
        if h is None:
            results.append({"path": f, "fpga": False,
                            "reason": "no XiST bitstream header"})
            continue
        h["fpga"] = True
        results.append(h)

    if as_json:
        import json
        print(json.dumps(results, ensure_ascii=False, indent=2))
    else:
        n_fpga = 0
        for r in results:
            if not r.get("fpga", True):
                print(f"[skip] {r['reason']}: {r['path']}")
                continue
            n_fpga += 1
            print(f"[FPGA] {r['path']}")
            print(f"       design: {r['design'] or '?'}")
            print(f"       device: {r['device'] or '?'}")
            if r['architecture'] or r['status']:
                print(f"       arch:   {r['architecture'] or '?'}  ({r['status'] or '?'})")
            if r['date']:
                print(f"       date:   {r['date']}")
            print(f"       size:   {_fmt_size(r['size'])}")
        if n_fpga == 0:
            print("Error: no XiST FPGA bitstream found in the given files.")
            sys.exit(1)
