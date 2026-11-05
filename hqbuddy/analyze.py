# -*- coding: utf-8 -*-
"""Pre-implementation design analysis: hqbuddy -analyze.

Synthesizes the project in a throwaway hqfpga session (design.rtlsyn, no
P&R), then runs the netlist/timing report family and writes per-section
reports into <prj_dir>/analysis/ (cleared on rerun) plus a stdout digest:

  clocks.rpt    nl.clock.detect + ta.clock.list(-name [-uncst_only]) + ta.clock.report
  fanout.rpt    nl.stat.fanout all -n N [-detail]   (after nl.flatten -nmnc)
  clkdom.rpt    nl.clkdom.report [-detail]          (clock domains + CDC leads)
  hier.rpt      nl.hier.report                      (empty output on some versions)
  power.rpt     nl.power.report                     (needs an implemented design -> WARN)
  loop.rpt      nl.loop.report                      (combinational loops)

Every section is catch-guarded: a vendor command crash (e.g. nl.clkdom.report
on pre-synthesis netlists, FT110126) cannot take down the remaining sections.

Output formats are verified on 3.1.1 FT110126 (return-value commands are
puts()'d; print-style commands are captured as-is).
"""
import os
import re
import subprocess
import sys
import tempfile
import time

from . import launcher


SECTIONS = [
    # (marker, report file base name)
    ("CLKS", "clocks"),
    ("FANOUT", "fanout"),
    ("CLKDOM", "clkdom"),
    ("HIER", "hier"),
    ("POWER", "power"),
    ("LOOP", "loop"),
]

_MARK = "@@ANALYZE:"


def _usage() -> None:
    print("Usage: hqbuddy -analyze [<.hqprj>] [-n N] [-detail] [-toggle_rate X] [-o <dir>]")
    print("       综合一次（不 P&R），输出实现前设计体检报告到 <工程根>/analysis/")
    print("  -n N           扇出排行取前 N（缺省 20）")
    print("  -detail        扇出/时钟域报告附加逐 net 明细")
    print("  -toggle_rate X 功耗翻转率（0~1，缺省工具默认；实现前仅能出 WARN，见 README）")
    print("  -o <dir>       报告输出目录（缺省 <工程根>/analysis/）")
    sys.exit(1)


def _parse_args(args: list) -> dict:
    """Position-independent: flags anywhere, .hqprj last (single positional)."""
    opt = {"hqprj": None, "n": 20, "detail": False, "toggle_rate": None,
           "outdir": None}
    i = 0
    while i < len(args):
        a = args[i]
        if a == "-n" and i + 1 < len(args):
            try:
                opt["n"] = int(args[i + 1])
            except ValueError:
                print(f"Error: -n 需要整数，得到: {args[i + 1]}")
                sys.exit(1)
            if opt["n"] < 1:
                print("Error: -n 必须 >= 1")
                sys.exit(1)
            i += 2
        elif a == "-detail":
            opt["detail"] = True
            i += 1
        elif a == "-toggle_rate" and i + 1 < len(args):
            try:
                opt["toggle_rate"] = float(args[i + 1])
            except ValueError:
                print(f"Error: -toggle_rate 需要数值（0~1），得到: {args[i + 1]}")
                sys.exit(1)
            i += 2
        elif a == "-o" and i + 1 < len(args):
            opt["outdir"] = args[i + 1]
            i += 2
        elif a.startswith("-"):
            print(f"Error: unknown -analyze option: {a}")
            _usage()
        elif opt["hqprj"] is None:
            opt["hqprj"] = a
            i += 1
        else:
            print(f"Error: unexpected argument: {a}")
            _usage()
    return opt


def _read_project(hqprj: str) -> dict:
    """Parse the fields -analyze needs from the .hqprj."""
    top = None
    family = None
    srcs = []
    sdc = None
    work = os.path.dirname(os.path.abspath(hqprj)).replace(os.sep, "/")
    for ln in open(hqprj, encoding="utf-8", errors="replace"):
        ln = ln.strip()
        if ln.startswith("TOP_MODULE="):
            top = ln.split("=", 1)[1]
        elif ln.startswith("FAMILY="):
            family = ln.split("=", 1)[1]
        elif ln.startswith("FILE_SRC=") and ln != "FILE_SRC=NONE":
            srcs.append(ln.split("=", 1)[1])
        elif ln.startswith("FILE_TC=") and ln != "FILE_TC=NONE":
            sdc = ln.split("=", 1)[1]
    def resolve(p):
        return p.replace("$WORK_DIR$", work + "/") if p else p
    return {"top": top, "family": family, "srcs": [resolve(s) for s in srcs],
            "sdc": resolve(sdc), "work": work}


def _build_tcl(prj: dict, opt: dict) -> str:
    vlines = "\n".join(f"lappend vfiles {{{s}}}" for s in prj["srcs"])
    fanout_cmd = f"nl.stat.fanout all -n {opt['n']}"
    if opt["detail"]:
        fanout_cmd += " -detail"
    clkdom_cmd = "nl.clkdom.report -detail" if opt["detail"] else "nl.clkdom.report"
    power_cmd = ("nl.power.report -toggle_rate %g" % opt["toggle_rate"]
                 if opt["toggle_rate"] is not None else "nl.power.report")
    sdc_line = ""
    if prj["sdc"]:
        sdc_line = (f'if {{[catch {{sdc.read {{{prj["sdc"]}}}}} e]}} '
                    f'{{ puts "SDC-ERROR: $e" }}\n')

    def guarded(cmd: str) -> str:
        return (f'if {{[catch {{{cmd}}} e]}} {{ puts "SECTION-ERROR: $e" }}\n')

    def guarded_ret(cmd: str, tag: str) -> str:
        # return-value style command: puts() its result ourselves
        return (f'if {{[catch {{set r [{cmd}]; puts "{tag} $r"}} e]}} '
                f'{{ puts "SECTION-ERROR: $e" }}\n')

    tcl = f"""set vfiles {{}}
{vlines}
dv.setup -synlib_only {prj['family'] or 'SEAL'}
if {{[catch {{
design.analyze $vfiles
design.rtlsyn -top {prj['top']}
}} emsg]}} {{ puts "SYNTH-ERROR: $emsg" }}
{sdc_line}
if {{[catch {{nl.flatten -nmnc}} e]}} {{ puts "FLATTEN-WARN: $e" }}
"""
    for mark, _ in SECTIONS:
        tcl += f'puts "{_MARK}{mark}@@"\n'
        if mark == "CLKS":
            tcl += guarded_ret("nl.clock.detect", "NETLIST-CLOCKS:")
            tcl += guarded_ret("ta.clock.list -name", "DEFINED-CLOCKS:")
            tcl += guarded_ret("ta.clock.list -name -uncst_only", "UNCST-CLOCKS:")
            tcl += guarded("ta.clock.report")
        elif mark == "FANOUT":
            tcl += guarded(fanout_cmd)
        elif mark == "CLKDOM":
            tcl += guarded(clkdom_cmd)
        elif mark == "HIER":
            tcl += guarded("nl.hier.report -inc_devcnt -inc_header -inc_level -inc_self")
        elif mark == "POWER":
            tcl += guarded(power_cmd)
        elif mark == "LOOP":
            tcl += guarded("nl.loop.report")
    tcl += f'puts "{_MARK}END@@"\n'
    return tcl


def _run(hqfpga_path: str, tcl_text: str, work: str) -> str:
    tf = tempfile.NamedTemporaryFile("w", suffix=".tcl", delete=False,
                                     encoding="utf-8")
    tf.write(tcl_text)
    tf.close()
    try:
        proc = subprocess.run(launcher.side_session_cmd(hqfpga_path, tf.name),
                              cwd=work,
                              capture_output=True, text=True, errors="replace",
                              timeout=1800)
    except subprocess.TimeoutExpired:
        print("Error: hqfpga analyze 超时（1800s）——设计可能过大或工具挂起。")
        sys.exit(1)
    finally:
        try:
            os.unlink(tf.name)
        except OSError:
            pass
    if "SYNTH-ERROR:" in (proc.stdout or ""):
        # design.rtlsyn failed (empty emsg happens): every section would only
        # print confusing FOBJ003 "Top view is NULL" — fail fast instead
        tail = "\n".join((proc.stdout or "").splitlines()[-12:])
        print(f"Error: 综合（design.rtlsyn）失败，hqfpga 输出尾部：\n{tail}")
        sys.exit(1)
    return proc.stdout or ""


def _section(out: str, mark: str) -> str:
    """Extract one marker-delimited section (empty string when absent)."""
    begin = f"{_MARK}{mark}@@"
    if begin not in out:
        return ""
    seg = out.split(begin, 1)[1]
    nxt = seg.find(_MARK)
    seg = seg[:nxt] if nxt >= 0 else seg
    stop = seg.find(f"{_MARK}END@@")
    return (seg[:stop] if stop >= 0 else seg).strip("\n")


def _digest(out_dir: str, secs: dict, opt: dict) -> None:
    print("")
    print("=" * 64)
    print("设计分析摘要（实现前：已综合，未布局布线）")
    print("=" * 64)

    # clocks
    c = secs.get("CLKS", "")
    det = re.search(r"NETLIST-CLOCKS: (.*)", c)
    defined = re.search(r"DEFINED-CLOCKS: (.*)", c)
    uncst = re.search(r"UNCST-CLOCKS: (.*)", c)
    if "SDC-ERROR" in c:
        print(f"[时钟] SDC 读取失败，时钟约束检查不可用")
    elif det is None:
        print("[时钟] nl.clock.detect 无输出（该命令在此版本/网表上不产数据）")
    else:
        nets = det.group(1).split()
        names = (defined.group(1).split() if defined else [])
        unc = (uncst.group(1).split() if uncst else [])
        print(f"[时钟] 网表检测时钟 {len(nets)} 个: {' '.join(nets) or '-'}")
        if not opt.get("_has_sdc"):
            print("[时钟] 工程无 FILE_TC（无时序约束）—— 约束检查跳过；"
                  "可用 hqbuddy -autosdc 生成时钟约束")
        else:
            print(f"[时钟] SDC 已定义 {len(names)} 个; 漏约束 "
                  f"{len(unc)} 个{'  <-- 需补约束!' if unc else ' (OK)'}")
            if unc:
                print("[时钟] 漏约束清单:")
                for u in unc:
                    print(f"         - {u}")

    # fanout
    f = secs.get("FANOUT", "")
    for ln in f.splitlines():
        m = re.match(r"(Data|Control|Clock|Mixed|Const)\s+(\d+)\s+(\d+)\s+(\d+)", ln.strip())
        if m:
            typ, cnt, total, mx = m.group(1), int(m.group(2)), int(m.group(3)), int(m.group(4))
            print(f"[扇出] {typ:<8} top-max {mx:>5}  (前{cnt}条, 总sink {total})")
    if "SECTION-ERROR" in f:
        print("[扇出] nl.stat.fanout 报错，详见 fanout.rpt")

    # clock domains
    cd = secs.get("CLKDOM", "")
    doms = re.findall(r"Resources in (?:MULTIPLE )?clock domains? <([^>]*)>", cd)
    multi = cd.count("Resources in MULTIPLE clock domains")
    if doms:
        print(f"[时钟域] {len(doms)} 个域; 跨域(MULTIPLE)资源组 {multi} 处"
              f"{'  <-- CDC 排查线索, 详见 clkdom.rpt' if multi else ''}")
    elif "SECTION-ERROR" in cd:
        print("[时钟域] nl.clkdom.report 报错，详见 clkdom.rpt")

    # hierarchy
    h = secs.get("HIER", "")
    if h.strip():
        print(f"[层次] 报告已生成 ({len(h.splitlines())} 行)")
    else:
        print("[层次] nl.hier.report 无输出（本版本对该网表不产报告，已跳过）")

    # power
    p = secs.get("POWER", "")
    if "PWR001" in p:
        print("[功耗] 需布线后设计才能估算 —— 本次跳过（实现后看 GUI 功耗窗口，")
        print("       或对布线后数据库再跑分析）")
    elif p.strip():
        print(f"[功耗] 报告已生成 ({len(p.splitlines())} 行)")

    # loops
    lp = secs.get("LOOP", "")
    m = re.search(r"there is (\d+) combinational loop", lp)
    if m:
        n = int(m.group(1))
        print(f"[组合环] {n} 个{'  <-- 需处理! 详见 loop.rpt' if n else ' (OK)'}")
    elif lp.strip():
        print(f"[组合环] 报告已生成")

    print("-" * 64)
    print(f"明细报告: {os.path.abspath(out_dir)}")
    print("注意: 本次为综合后(未布局布线)数据；扇出/组合环结论在布局布线后可能变化。")


def run_analyze(args: list) -> None:
    """Entry for 'hqbuddy -analyze [<.hqprj>] [-n N] [-detail] [-toggle_rate X] [-o dir]'."""
    if not args or args[0] in ("-h", "--help"):
        _usage()
    opt = _parse_args(args)
    hqprj = opt["hqprj"]
    if not hqprj:
        import glob
        cands = sorted(glob.glob("*.hqprj"))
        if not cands:
            print("Error: 未指定 .hqprj 且当前目录没有工程文件")
            sys.exit(1)
        if len(cands) > 1:
            print("Error: 当前目录有多个 .hqprj，请显式指定一个:")
            for cand in cands:
                print(f"  {cand}")
            sys.exit(1)
        hqprj = cands[0]
    hqprj = os.path.abspath(hqprj)
    if not os.path.isfile(hqprj):
        print(f"Error: file not found: {hqprj}")
        sys.exit(1)

    prj = _read_project(hqprj)
    if not prj["top"] or prj["top"] == "NONE":
        print("Error: .hqprj 未设置 TOP_MODULE，无法综合。")
        sys.exit(1)
    if not prj["srcs"]:
        print("Error: .hqprj 无 FILE_SRC（没有源文件），无法综合。")
        sys.exit(1)
    missing = [s for s in prj["srcs"] if not os.path.isfile(s)]
    if missing:
        print(f"Error: {len(missing)} 个源文件不存在（工程引用路径无法解析）:")
        for s in missing:
            print(f"  {s}")
        sys.exit(1)
    opt["_has_sdc"] = bool(prj["sdc"])
    if prj["sdc"] and not os.path.isfile(prj["sdc"]):
        print(f"Warning: FILE_TC 不存在，时钟约束段将无数据: {prj['sdc']}")

    out_dir = os.path.abspath(opt["outdir"] or os.path.join(prj["work"], "analysis"))

    version = launcher.require_hqfpga_version()
    tcl = _build_tcl(prj, opt)

    print(f"Analyzing: {hqprj}")
    print(f"  top={prj['top']}  family={prj['family'] or 'SEAL'}  "
          f"srcs={len(prj['srcs'])}  sdc={'yes' if prj['sdc'] else 'no'}")
    print(f"  报告目录: {out_dir}")
    print("  (综合中，无 P&R —— 请稍候)")
    sys.stdout.flush()
    started = time.time()
    out = _run(version["hqfpga_path"], tcl, prj["work"])
    elapsed = time.time() - started

    # report-dir refresh: only ever delete THIS tool's own .rpt files —
    # never rmtree (a `-o` pointing at user content must not lose data;
    # unknown files in the directory are kept and reported)
    our_rpts = {f"{base}.rpt" for _, base in SECTIONS}
    if os.path.isdir(out_dir):
        stale = os.listdir(out_dir)
        for f in stale:
            if f in our_rpts:
                try:
                    os.remove(os.path.join(out_dir, f))
                except OSError as e:
                    print(f"Warning: could not remove stale report {f}: {e}")
        unknown = [f for f in stale if f not in our_rpts]
        if unknown:
            print(f"Note: {len(unknown)} 个非本工具文件保留在报告目录: "
                  f"{', '.join(sorted(unknown)[:5])}{' ...' if len(unknown) > 5 else ''}")
    os.makedirs(out_dir, exist_ok=True)

    secs = {}
    wrote = 0
    for mark, base in SECTIONS:
        seg = _section(out, mark)
        secs[mark] = seg
        path = os.path.join(out_dir, f"{base}.rpt")
        with open(path, "w", encoding="utf-8") as f:
            if not seg.strip():
                f.write(f"(no output — {base} report produced nothing this run)\n")
            else:
                f.write(seg.rstrip() + "\n")
        wrote += 1

    _digest(out_dir, secs, opt)
    if "SECTION-ERROR" in out and not any(s.strip() for s in secs.values()):
        print("Error: 所有分析段均失败，请把上述输出反馈给厂商/检查工具版本。")
        sys.exit(1)
    print(f"Done in {elapsed:.0f}s.")
