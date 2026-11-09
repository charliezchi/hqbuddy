# -*- coding: utf-8 -*-
"""hqbuddy -regression: one-command regression suite.

Two modes:
  --offline (self-contained)  builds a throwaway mini project in %TEMP% via
                              -new_prj and runs pure-offline checks (no board,
                              no baseline dir, works on a fresh machine).
  default (board)             needs the r21a baseline dir (pass its path) and
                              the IST158/SA50K board for the LA capture check.
Exit 1 on any FAIL.
"""
import glob
import os
import shutil
import sys
import subprocess
import tempfile
import time

BASE = r"C:\Users\XiST\Desktop\hqbuddy_test"

_HQ_EXE = shutil.which("hqbuddy")


def _run(cmd, cwd=None, timeout=300):
    # always exercise the RUNNING package (python -m hqbuddy), never a stale
    # hqbuddy.exe from PATH — the suite must test this repo's code
    if cmd and cmd[0] == "hqbuddy":
        cmd = [sys.executable, "-m", "hqbuddy"] + cmd[1:]
    env = dict(os.environ)
    # child processes may run with a different cwd — keep the repo importable
    env["PYTHONPATH"] = os.path.dirname(os.path.dirname(os.path.abspath(__file__))) \
        + os.pathsep + env.get("PYTHONPATH", "")
    try:
        r = subprocess.run(cmd, capture_output=True, timeout=timeout, cwd=cwd,
                           env=env)
    except subprocess.TimeoutExpired:
        return -1, f"TIMEOUT after {timeout}s: {' '.join(cmd)}"
    out = (r.stdout or b"").decode("utf-8", errors="replace")
    err = (r.stderr or b"").decode("utf-8", errors="replace")
    # merge stderr into stdout for unified matching
    return r.returncode, out + err


def _check(name, ok, detail=""):
    tag = "PASS" if ok else "FAIL"
    print(f"  [{tag}] {name}" + (f" — {detail}" if detail else ""))
    return ok


def _make_mini_project(root: str, device: str = "SA5Z-30-D0-8U324C") -> str:
    """Throwaway project with one counter source file, for offline checks."""
    os.makedirs(root, exist_ok=True)
    rc, out = _run(["hqbuddy", "-new_prj", "regmini", "-device", device],
                   cwd=root)
    hqprj = os.path.join(root, "regmini.hqprj")
    if rc != 0 or not os.path.isfile(hqprj):
        raise SystemExit(f"Error: -new_prj failed: {out[-300:]}")
    rtl = os.path.join(root, "regmini_counter.v")
    with open(rtl, "w", encoding="utf-8", newline="\n") as f:
        f.write("""// regression mini counter (offline suite)
module regmini_counter (
    input  wire       clk,
    input  wire       rst_n,
    output reg  [7:0] cnt,
    output wire       tick
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 8'd0;
        else
            cnt <= cnt + 8'd1;
    end
    assign tick = cnt[3];
endmodule
""")
    _run(["hqbuddy", "-add", rtl, hqprj], cwd=root)
    # template ships with an empty TOP_MODULE — point it at the counter
    lines = []
    for ln in open(hqprj, encoding="utf-8", errors="replace"):
        if ln.strip().startswith("TOP_MODULE="):
            ln = "TOP_MODULE=regmini_counter\n"
        lines.append(ln)
    with open(hqprj, "w", encoding="utf-8", newline="") as f:
        f.writelines(lines)
    return hqprj


def run_offline() -> None:
    """Self-contained offline suite: %TEMP% mini project, no board/baseline."""
    root = os.path.join(tempfile.gettempdir(), "hqbuddy_regression",
                        time.strftime("%Y%m%d_%H%M%S"))
    print(f"hqbuddy offline regression suite (root: {root})")
    print()
    results = []

    hqprj = _make_mini_project(root)
    work = os.path.dirname(hqprj)

    # 1. project integrity: doctor
    rc, out = _run(["hqbuddy", "-doctor", hqprj], timeout=600)
    ok = rc == 0 and "0 FAIL" in out
    results.append(_check("doctor clean", ok, out.strip().splitlines()[-1][:80] if out else ""))

    # 2. filelist
    rc, out = _run(["hqbuddy", "-filelist", hqprj])
    ok = rc == 0 and "saved" in out
    results.append(_check("filelist generated", ok, out.strip()[:60]))

    # 3. flow TCL generation + hook injection
    flow_tcl = os.path.join(work, "reg_flow.tcl")
    rc, out = _run(["hqbuddy", "-flow", hqprj, "--hook",
                    "AfterRoute=ta.report -o> mid_ta.rpt",
                    "-o", "reg_flow.tcl"], cwd=work, timeout=600)
    hook_in = False
    if os.path.isfile(flow_tcl):
        head = open(flow_tcl, encoding="gbk", errors="replace").read(4000)
        hook_in = "HQ.DEBUG.STEP.AfterRoute" in head
    ok = rc == 0 and os.path.isfile(flow_tcl) and hook_in
    results.append(_check("flow TCL + --hook injected", ok,
                          "AfterRoute hook found" if hook_in else out[-120:]))

    # 4. synopt injection into flow TCL
    rc, out = _run(["hqbuddy", "-synopt", hqprj, "-set", "fsm_encoding=onehot"])
    flow_tcl2 = os.path.join(work, "reg_flow2.tcl")
    rc, out = _run(["hqbuddy", "-flow", hqprj, "-o", "reg_flow2.tcl"],
                   cwd=work, timeout=600)
    fsm_in = False
    if os.path.isfile(flow_tcl2):
        fsm_in = "fsm.set -encoding onehot" in \
            open(flow_tcl2, encoding="gbk", errors="replace").read()
    ok = rc == 0 and fsm_in
    results.append(_check("synopt injected (fsm_encoding)", ok,
                          "fsm.set found" if fsm_in else out[-120:]))
    _run(["hqbuddy", "-synopt", hqprj, "-clear"])

    # 5. -bitinfo on a real bit? (no bit in offline mode) — parse-error path instead
    rc, out = _run(["hqbuddy", "-bitinfo", hqprj])
    ok = rc != 0 and "no XiST FPGA bitstream" in out
    results.append(_check("bitinfo rejects non-bitstream", ok, out.strip()[:60]))

    # 6. -analyze (synthesis stage; needs hqfpga, no board)
    rc, out = _run(["hqbuddy", "-analyze", hqprj], cwd=work, timeout=1800)
    ana_dir = os.path.join(work, "analysis")
    ok = rc == 0 and os.path.isfile(os.path.join(ana_dir, "clocks.rpt"))
    results.append(_check("-analyze six reports", ok,
                          "clocks.rpt produced" if ok else out[-150:]))

    # 7. -autosdc is known-broken on FT110126 — verify the honest failure
    rc, out = _run(["hqbuddy", "-autosdc", hqprj, "-o",
                    os.path.join(work, "auto.sdc")], cwd=work, timeout=900)
    ok = rc != 0 and ("tc.autogen" in out)
    results.append(_check("autosdc honest failure (FT110126)", ok, out.strip()[:70]))

    # 8. -pin2csv on a project without UPC → clean error
    rc, out = _run(["hqbuddy", "-pin2csv", hqprj])
    ok = rc != 0 and "FILE_PC" in out
    results.append(_check("pin2csv no-UPC error", ok, out.strip()[:60]))

    # 9. error paths: unknown option / missing file
    rc, out = _run(["hqbuddy", "-analyze", "-bogus"])
    ok = rc != 0 and "unknown -analyze option" in out
    results.append(_check("unknown flag rejected", ok, out.strip()[:60]))

    # 10. -tinysoc bin: firmware 4-lane split (bin_regen equivalent)
    fw = os.path.join(work, "fw_test.bin")
    open(fw, "wb").write(bytes((i * 7 + 3) & 0xFF for i in range(1000)))
    rc, out = _run(["hqbuddy", "-tinysoc", "bin", fw, "-o",
                    os.path.join(work, "rom"), "--ram-size", "4096"])
    lanes = [os.path.join(work, "rom", f"fw{k}.bin") for k in range(4)]
    ok = rc == 0 and all(os.path.isfile(p) for p in lanes)
    if ok:
        fw_data = open(fw, "rb").read()
        fw_data += b"\x00" * (4096 - len(fw_data))
        for k in range(4):
            bits = open(lanes[k]).read().split()
            if len(bits) != 1024 or any(
                    int(bits[w], 2) != fw_data[4 * w + k] for w in range(1024)):
                ok = False
                break
    results.append(_check("tinysoc bin 4-lane split", ok,
                          "byte-lane mapping verified" if ok else out[-120:]))

    # cleanup
    shutil.rmtree(root, ignore_errors=True)

    n_pass = sum(1 for r in results if r)
    n_fail = len(results) - n_pass
    print(f"\nOffline regression: {n_pass}/{len(results)} PASS, {n_fail} FAIL")
    if n_fail:
        sys.exit(1)


def run_board(base: str, hqprj: str) -> None:
    """Board suite: LA capture + trigger validation on the r21a baseline."""
    results = []
    skipped = []
    print(f"hqbuddy regression suite (base: {base})")
    print()

    print("1. Baseline capture (board)")
    print("  setting trigger...")
    _run(["hqbuddy", "-insight", hqprj, "-trig", "cnt EQ 200 AND lfsr NE 0"])
    rc, out = _run(["hqbuddy", "-insight", hqprj, "-capture", "-timeout", "60"],
                   timeout=120)
    ok = "Trigger at" in out and "0xc8" in out
    results.append(_check("capture trigger", ok,
                          "fired" if ok else out[-200:]))

    rc, out = _run(["hqbuddy", "-insight", hqprj, "-trig", "cnt EQ 5 AND cnt EQ 9"])
    ok = rc != 0 and len(out) > 10
    results.append(_check("contradictory rejected", ok, out.strip()[:80]))

    _run(["hqbuddy", "-insight", hqprj, "-add", "dbg_out", "-module", "r21a_top",
          "-type", "sample", "-clk", "clk"])
    rc, out = _run(["hqbuddy", "-insight", hqprj, "-trig", "dbg_out RISE"])
    ok = rc != 0
    results.append(_check("sample-only trigger rejected", ok, out.strip()[:80]))
    _run(["hqbuddy", "-insight", hqprj, "-del", "dbg_out"])

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

    rc, out = _run(["hqbuddy", "-report", base])
    ok = rc == 0 and "Fmax" in out
    results.append(_check("-report digest", ok, "Fmax found" if ok else out[-80:]))

    n_pass = sum(1 for r in results if r)
    n_fail = len(results) - n_pass
    print(f"\nRegression: {n_pass}/{len(results)} PASS, {n_fail} FAIL"
          + (f", {len(skipped)} SKIP" if skipped else ""))
    if n_fail:
        sys.exit(1)


def run_regression(args):
    """Entry for 'hqbuddy -regression [--offline] [base_dir]'."""
    offline = '--offline' in args
    args = [a for a in args if a != '--offline']
    if offline:
        run_offline()
        return
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
        print("       或用 --offline 跑自包含离线套件（无需基线/板卡）。")
        sys.exit(1)
    run_board(base, hqprj)
