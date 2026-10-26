# -*- coding: utf-8 -*-
"""Project health checker: hqbuddy -doctor [<.hqprj>]

Aggregates the failure classes observed across blind-eval rounds (R6 ANSI/dup
modules, R15 five-defect takeover, R25 mixed signals, R29 path carry-over,
R32/R43 depth mismatch) into one read-only diagnostic.  Exit 1 on any FAIL.
"""
import glob
import os
import re
import sys
import tempfile

from . import device as device_mod
from .hqprj_parser import parse_hqprj
from .ipmgr import list_ip_files


def run_doctor(args: list) -> None:
    """Entry for 'hqbuddy -doctor [<.hqprj>]'."""
    hqprj_path = os.path.abspath(args[0] if args else _detect_hqprj())
    if not os.path.isfile(hqprj_path):
        print(f"Error: file not found: {hqprj_path}")
        sys.exit(1)
    work_dir = os.path.dirname(hqprj_path)
    info = parse_hqprj(hqprj_path)
    fields = info["fields"]
    file_src = info["sources"]
    file_tc = info["tc"]
    file_pc = info["pc"]

    fails: list = []
    warns: list = []
    oks: list = []

    # -- 1. project identity -------------------------------------------------
    name = fields.get("PROJ_NAME", "")
    top = fields.get("TOP_MODULE", "")
    die = fields.get("DIE", "")
    if not name:
        fails.append("PROJ_NAME 为空")
    if not top:
        fails.append("TOP_MODULE 为空——用 hqbuddy -set_top <模块名> 设置")
    else:
        oks.append(f"TOP_MODULE = {top}")

    # -- 2. source files -----------------------------------------------------
    resolved_src = []
    seen = {}
    missing_src = 0
    for p in file_src:
        resolved_src.append(p)
        seen.setdefault(os.path.normcase(p), []).append(p)
        if not os.path.isfile(p):
            fails.append(f"FILE_SRC 文件不存在: {p}")
            missing_src += 1
    dups = {k: v for k, v in seen.items() if len(v) > 1}
    for k, v in dups.items():
        fails.append(f"FILE_SRC 重复登记 {len(v)} 次: {v[0]}")
    if file_src and not dups and not missing_src:
        oks.append(f"FILE_SRC x{len(file_src)} 全部存在、无重复")
    for f in file_src + file_tc + file_pc:
        base = os.path.basename(f)
        if "_sim.v" in base or "tb_" in base:
            warns.append(f"源文件疑似 testbench: {base}（综合会引发重复声明）")

    # -- 3. module declarations (R6: duplicate/ANSI class) -------------------
    modules: dict = {}
    for p in resolved_src:
        if not p.endswith((".v", ".sv")) or not os.path.isfile(p):
            continue
        try:
            txt = open(p, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        for m in re.finditer(r"^\s*module\s+([A-Za-z_][A-Za-z0-9_$]*)", txt, re.M):
            modules.setdefault(m.group(1), []).append(os.path.basename(p))
    for mod, files in sorted(modules.items()):
        if len(files) > 1:
            fails.append(f"模块 {mod} 在多个文件中重复声明: {', '.join(files)}")
    if top and top not in modules:
        fails.append(f"TOP_MODULE {top} 在任何源文件中都找不到 module 声明")
    elif top:
        oks.append(f"顶层 {top} 声明可找到（共 {len(modules)} 个模块）")

    # -- 4. constraints & time entries (R15 defect class) --------------------
    for kind, lst in (("FILE_TC", file_tc), ("FILE_PC", file_pc)):
        for p in lst:
            if not os.path.isfile(p):
                fails.append(f"{kind} 文件不存在: {p}")
    if not file_pc:
        warns.append("无管脚约束（FILE_PC=NONE）——bitgen 会报 BIT-11")
    n_src = len(file_src)
    n_cst = len(file_tc) + len(file_pc)
    n_time = len(info["times"])
    n_timecst = len(info["times_cst"])
    if n_time != n_src:
        fails.append(f"FILE_TIME 条目数({n_time}) != FILE_SRC 数({n_src})"
                     f"——用 hqbuddy -refresh_time 修复")
    if n_timecst != n_cst:
        fails.append(f"FILE_TIME_CST 条目数({n_timecst}) != FILE_TC+PC 数({n_cst})"
                     f"——用 hqbuddy -refresh_time 修复")
    if n_time == n_src and n_timecst == n_cst and n_src:
        oks.append(f"时间戳条目一致 (FILE_TIME x{n_time}, FILE_TIME_CST x{n_timecst})")

    # -- 5. device legality --------------------------------------------------
    part = fields.get("DEVICE", "")
    try:
        valid = device_mod._get_valid_devices()
        if not die and not part:
            warns.append("DIE/DEVICE 均为空")
        else:
            full = f"{die}-{part}" if (die and part) else (die or part)
            if full in valid or any(v.startswith(full) for v in valid):
                oks.append(f"器件 {full} 合法")
            elif die and any(v.split("-")[0] == die.split("-")[0] for v in valid):
                oks.append(f"器件族匹配（DIE={die}，完整型号建议核对）")
            else:
                warns.append(f"器件 {full} 未在 dv_list 合法表中")
    except SystemExit:
        warns.append("HqFPGA 版本未配置，跳过器件合法性检查（hqbuddy -cfg）")

    # -- 5b. UPC pin pre-check (ball legality + clock-on-P-side) --------------
    # PHY-CHK-030 / CDEV003 otherwise only surface mid-build; phycst.loc.check
    # needs only dv.setup (no design), so we can validate before any build.
    if file_pc:
        pkg = fields.get("PACKAGES", "")
        spd = fields.get("SPEEDS", "")
        cond = fields.get("CONDITION", "")
        family = fields.get("FAMILY", "SEAL")
        part_full = f"{die}-{spd}{pkg}{cond}" if (die and pkg and spd and cond) else None
        pins = {}
        for p in file_pc:
            if not os.path.isfile(p):
                continue
            for ln in open(p, encoding="utf-8", errors="replace"):
                m = re.match(r'\s*phycst\.pin\.set\s+\{([^}]+)\}\s+(\S+)', ln)
                if m:
                    pins[m.group(1).strip()] = m.group(2)
        if not pins:
            oks.append("UPC 无 phycst.pin.set 引脚条目——跳过引脚预检")
        elif not part_full:
            warns.append("UPC 引脚预检跳过：.hqprj 缺 PACKAGES/SPEEDS/CONDITION，"
                         "无法确定完整型号")
        else:
            try:
                from . import launcher
                version = launcher.require_hqfpga_version()
                import subprocess as _sp
                balls = sorted(set(pins.values()))
                tcl = (f"dv.setup {family} {part_full}\n"
                       f"foreach b {{{' '.join(balls)}}} {{ "
                       f"puts \"LOCCHK $b [phycst.loc.check $b]\" }}\nexit\n")
                fd, tmp = tempfile.mkstemp(suffix='.tcl', prefix='hqbuddy_upcchk_')
                try:
                    with os.fdopen(fd, 'w', encoding='utf-8') as f:
                        f.write(tcl)
                    r = _sp.run([version['hqfpga_path'], '-cmd', tmp],
                                capture_output=True, timeout=120)
                finally:
                    try:
                        os.remove(tmp)
                    except OSError:
                        pass
                out = ((r.stdout or b'') + (r.stderr or b'')).decode('utf-8', errors='replace')
                legal = {m2.group(1) for m2 in
                         re.finditer(r'^LOCCHK (\S+) 1\b', out, re.M)}
                bad = [b for b in balls if b not in legal]
                if not legal and not bad:
                    warns.append(f"引脚预检无结果（dv.setup {part_full} 失败?），跳过")
                elif bad:
                    bad_pins = sorted(p for p, b in pins.items() if b in bad)
                    fails.append(f"UPC 引脚球号非法（{part_full}）: {', '.join(bad)}"
                                 f"（涉及: {', '.join(bad_pins)}）"
                                 f"——用 phycst.loc.check 核对封装球号")
                else:
                    oks.append(f"UPC 引脚球号全部合法 ({len(balls)} 个，{part_full})")
                # clock-on-P-side: clock ports (SDC create_clock get_ports) must
                # sit on P-side balls, else PHY-CHK-030 at build time
                clk_nets = set()
                for s in file_tc:
                    if not os.path.isfile(s):
                        continue
                    for ln in open(s, encoding="utf-8", errors="replace"):
                        m3 = re.search(r'get_ports\s+\{?([A-Za-z_][\w\[\]:]*)', ln)
                        if m3 and re.match(r'\s*create_clock\b', ln):
                            clk_nets.add(m3.group(1))
                misplaced = sorted(n for n, b in pins.items()
                                   if n in clk_nets and legal and b in legal
                                   and not b.upper().startswith('P'))
                if misplaced:
                    fails.append(f"时钟脚未放在 P 侧球（build 会报 PHY-CHK-030）: "
                                 f"{', '.join(f'{n}({pins[n]})' for n in misplaced)}")
                elif clk_nets & set(pins):
                    oks.append("时钟脚均在 P 侧球")
            except SystemExit:
                warns.append("HqFPGA 版本未配置，跳过引脚预检（hqbuddy -cfg）")

    # -- 6. IP consistency ---------------------------------------------------
    try:
        for h in list_ip_files(hqprj_path):
            warns.append(f"存在 .hqip: {h}（如 IP 已废弃请移除）")
    except Exception:
        pass

    # -- 7. insight project state (R25/R32/R43 guards) ------------------------
    hqins = os.path.join(work_dir, "hqins_run", "hq_import.hqins")
    if os.path.isfile(hqins):
        oks.append("HqInsight 工程存在")
        ddf = os.path.join(work_dir, "hqins_run", "hq_import",
                           f"{top}_insight.ddf")
        depth_txt = None
        in_sec = False
        for ln in open(hqins, encoding="utf-8", errors="replace"):
            st = ln.strip()
            if st.startswith("["):
                in_sec = (st == "[MEMORY DEPTH INFO]")
                continue
            if in_sec and ":" in st:
                depth_txt = st.split(":", 1)[1].strip()
                break
        hqins_depth = int(depth_txt) if depth_txt else None
        if os.path.isfile(ddf):
            oks.append(f"ddf 存在（流程权威配置）")
            m = re.search(r"<depth>(\d+)</depth>",
                          open(ddf, encoding="utf-8", errors="replace").read())
            if m and hqins_depth and int(m.group(1)) != hqins_depth:
                warns.append(f".hqins 深度({hqins_depth}) != ddf 深度({m.group(1)})"
                             f"——capture 会拒绝抓取；用 -insight -depth {m.group(1)} 对齐")
        else:
            warns.append(f"ddf 不存在: {ddf}（流程需要它，缺失会崩溃）")
        # signal-set stamp (R25)
        stamp = os.path.join(os.path.dirname(ddf), ".bit_signals")
        if os.path.isfile(stamp) and hqins_depth:
            pass  # deep comparison lives in -capture; keep doctor light
    elif any(f.endswith(".v") for f in resolved_src):
        warns.append("尚无 HqInsight 工程（hqins_run 不存在）——需要在线调试时先 "
                     "-insight -init")

    # -- report ---------------------------------------------------------------
    print(f"Doctor: {hqprj_path}")
    print(f"  PROJ_NAME={name or '?'}  TOP={top or '?'}  DIE={die or '?'}  "
          f"FILE_SRC x{n_src}")
    print()
    for lvl, msgs in (("FAIL", fails), ("WARN", warns)):
        for msg in msgs:
            print(f"[{lvl}] {msg}")
    for msg in oks:
        print(f"[ ok ] {msg}")
    print()
    print(f"结果: {len(fails)} FAIL, {len(warns)} WARN, {len(oks)} ok")
    if fails:
        sys.exit(1)
    sys.exit(0)


def _detect_hqprj() -> str:
    import glob
    hits = sorted(glob.glob("*.hqprj"))
    if not hits:
        print("Error: no .hqprj in current directory; pass a project path.")
        sys.exit(1)
    if len(hits) > 1:
        print(f"Note: multiple .hqprj files in cwd; using {hits[0]} "
              f"(others: {', '.join(hits[1:])})")
    return hits[0]
