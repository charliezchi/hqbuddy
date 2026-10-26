# -*- coding: utf-8 -*-
"""hqbuddy -regression: one-command regression suite.

Aggregates critical checks from blind eval into a single command.
Offline checks run without a board; online checks need the SA50K board
with the r21a clean baseline bit.  Exit 1 on any FAIL.
"""
import os
import shutil
import glob
import sys
import subprocess

BASE = r"C:\Users\XiST\Desktop\hqbuddy_test"

_HQ_EXE = shutil.which("hqbuddy")


def _run(cmd, cwd=None, timeout=300):
    if cmd and cmd[0] == "hqbuddy" and _HQ_EXE is None:
        cmd = [sys.executable, "-m", "hqbuddy"] + cmd[1:]
    r = subprocess.run(cmd, capture_output=True, timeout=timeout, cwd=cwd)
    out = (r.stdout or b"").decode("utf-8", errors="replace")
    err = (r.stderr or b"").decode("utf-8", errors="replace")
    # merge stderr into stdout for unified matching
    return r.returncode, out + err

def _check(name, ok, detail=""):
    tag = "PASS" if ok else "FAIL"
    print(f"  [{tag}] {name}" + (f" — {detail}" if detail else ""))
    return ok

def run_regression(args):
    """Entry for 'hqbuddy -regression [--offline] [base_dir]'."""
    offline = '--offline' in args
    args = [a for a in args if a != '--offline']
    if args:
        base = os.path.abspath(args[0])
        cands = sorted(glob.glob(os.path.join(base, "*.hqprj")))
        hqprj = next((p for p in cands
                      if os.path.basename(p) == "r21a.hqprj"),
                     cands[0] if len(cands) == 1 else None)
        if hqprj is None:
            print(f"Error: pass the r21a baseline dir (found {len(cands)} .hqprj in {base})")
            sys.exit(1)
    else:
        base = os.path.join(BASE, "r21a")
        hqprj = os.path.join(base, "r21a.hqprj")
    if not os.path.isfile(hqprj):
        print(f"Error: baseline project not found: {hqprj}")
        print("       Usage: hqbuddy -regression [--offline] <base_dir>")
        sys.exit(1)

    results = []
    skipped = []
    print(f"hqbuddy regression suite (base: {base})" + ("  [--offline]" if offline else ""))
    print()

    # 1. baseline capture (needs board + LA bit)
    if offline:
        print("1. Baseline capture (board)")
        print("  [SKIP] board required (--offline)")
        skipped.append("board capture")
    else:
        print("1. Baseline capture (board)")
        print("  setting trigger...")
        _run(["hqbuddy", "-insight", hqprj, "-trig", "cnt EQ 200 AND lfsr NE 0"])
        rc, out = _run(["hqbuddy", "-insight", hqprj, "-capture", "-timeout", "60"], timeout=120)
        ok = "Trigger at" in out and "0xc8" in out
        results.append(_check("capture trigger", ok,
                              "fired" if ok else out[-200:]))

    # 2. contradictory trigger rejection (offline)
    rc, out = _run(["hqbuddy", "-insight", hqprj, "-trig", "cnt EQ 5 AND cnt EQ 9"])
    ok = rc != 0 and len(out) > 10
    results.append(_check("contradictory rejected", ok, out.strip()[:80]))

    # 3. sample-only trigger rejection (offline)
    _run(["hqbuddy", "-insight", hqprj, "-add", "dbg_out", "-module", "r21a_top",
          "-type", "sample", "-clk", "clk"])
    rc, out = _run(["hqbuddy", "-insight", hqprj, "-trig", "dbg_out RISE"])
    ok = rc != 0
    results.append(_check("sample-only trigger rejected", ok, out.strip()[:80]))
    _run(["hqbuddy", "-insight", hqprj, "-del", "dbg_out"])

    # 4. filelist (offline)
    rc, out = _run(["hqbuddy", "-filelist", hqprj])
    ok = rc == 0 and "saved" in out
    results.append(_check("filelist generated", ok, out.strip()[:60]))

    # 5. -edf2v smoke
    sib = os.path.dirname(base)
    edif = os.path.join(sib, "r30syn", "a.edif")
    if os.path.isfile(edif):
        outv = os.path.join(sib, "r30syn", "reg_smoke.v")
        rc, out = _run(["hqbuddy", "-edf2v", edif, "-o", outv])
        ok = rc == 0 and os.path.isfile(outv) and os.path.getsize(outv) > 1000
        results.append(_check("edf2v conversion", ok, outv if ok else out[-100:]))
    else:
        print("  [SKIP] r30syn/a.edif not found")
        skipped.append("edf2v")

    # 6. -report smoke
    rc, out = _run(["hqbuddy", "-report", base])
    ok = rc == 0 and "Fmax" in out
    results.append(_check("-report digest", ok, "Fmax found" if ok else out[-80:]))

    n_pass = sum(1 for r in results if r)
    n_fail = len(results) - n_pass
    print(f"\nRegression: {n_pass}/{len(results)} PASS, {n_fail} FAIL"
          + (f", {len(skipped)} SKIP" if skipped else ""))
    if n_fail:
        sys.exit(1)
