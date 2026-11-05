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
    """Entry for 'hqbuddy -bitinfo <file.bin> [...]' (globs allowed)."""
    if not args:
        print("Usage: hqbuddy -bitinfo <file.bin> [<more>|<glob> ...]")
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

    n_fpga = 0
    for f in files:
        if not os.path.isfile(f):
            print(f"[skip] not a file: {f}")
            continue
        h = read_bitstream_header(f)
        if h is None:
            print(f"[skip] 非 XiST FPGA 位流（无位流头）: {f}")
            continue
        n_fpga += 1
        print(f"[FPGA] {h['path']}")
        print(f"       design: {h['design'] or '?'}")
        print(f"       device: {h['device'] or '?'}")
        if h['architecture'] or h['status']:
            print(f"       arch:   {h['architecture'] or '?'}  ({h['status'] or '?'})")
        if h['date']:
            print(f"       date:   {h['date']}")
        print(f"       size:   {_fmt_size(h['size'])}")

    if n_fpga == 0:
        print("Error: 未找到任何 XiST FPGA 位流。")
        sys.exit(1)
