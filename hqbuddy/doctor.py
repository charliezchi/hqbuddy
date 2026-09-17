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

from . import device as device_mod
from .ipmgr import list_ip_files


def _hqprj_fields(hqprj_path: str) -> tuple[dict, list, list, list]:
    fields: dict = {}
    file_src: list = []
    file_tc: list = []
    file_pc: list = []
    for line in open(hqprj_path, encoding="utf-8", errors="replace"):
        line = line.rstrip("\r\n")
        if "=" not in line:
            continue
        key, val = line.split("=", 1)
        if key == "FILE_SRC":
            file_src.append(val)
        elif key == "FILE_TC":
            file_tc.append(val)
        elif key == "FILE_PC":
            file_pc.append(val)
        elif key not in fields:
            fields[key] = val
    return fields, file_src, file_tc, file_pc


def _resolve(raw: str, work_dir: str) -> str:
    if raw == "NONE":
        return ""
    p = raw.replace("$WORK_DIR$", os.path.join(work_dir, ""))
    return os.path.normpath(p)


def run_doctor(args: list) -> None:
    """Entry for 'hqbuddy -doctor [<.hqprj>]'."""
    hqprj_path = os.path.abspath(args[0] if args else _detect_hqprj())
    if not os.path.isfile(hqprj_path):
        print(f"Error: file not found: {hqprj_path}")
        sys.exit(1)
    work_dir = os.path.dirname(hqprj_path)
    fields, file_src, file_tc, file_pc = _hqprj_fields(hqprj_path)

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
    for raw in file_src:
        if raw == "NONE":
            continue
        p = _resolve(raw, work_dir)
        resolved_src.append(p)
        seen.setdefault(os.path.normcase(p), []).append(raw)
        if not os.path.isfile(p):
            fails.append(f"FILE_SRC 文件不存在: {p}")
    dups = {k: v for k, v in seen.items() if len(v) > 1}
    for k, v in dups.items():
        fails.append(f"FILE_SRC 重复登记 {len(v)} 次: {v[0]}")
    if file_src and not dups:
        oks.append(f"FILE_SRC x{len(file_src)} 全部存在、无重复")
    for f in file_src + file_tc + file_pc:
        base = os.path.basename(f)
        if "_sim.v" in base or "tb_" in base:
            warns.append(f"源文件疑似 testbench: {base}（综合会引发重复声明）")

    # -- 3. module declarations (R6: duplicate/ANSI class) -------------------
    modules: dict = {}
    for p in resolved_src:
        if not p.endswith(".v") or not os.path.isfile(p):
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
        for raw in lst:
            p = _resolve(raw, work_dir)
            if p and not os.path.isfile(p):
                fails.append(f"{kind} 文件不存在: {p}")
    if not file_pc or file_pc == ["NONE"]:
        warns.append("无管脚约束（FILE_PC=NONE）——bitgen 会报 BIT-11")
    n_src = len([f for f in file_src if f != "NONE"])
    n_cst = len(file_tc) + len(file_pc)
    n_time = sum(1 for ln in open(hqprj_path, encoding="utf-8", errors="replace")
                 if ln.startswith("FILE_TIME="))
    n_timecst = sum(1 for ln in open(hqprj_path, encoding="utf-8", errors="replace")
                    if ln.startswith("FILE_TIME_CST="))
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
        hqins_depth = None
        for ln in open(hqins, encoding="utf-8", errors="replace"):
            if ln.startswith("0_LA:") and "MEMORY" not in ln:
                pass
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
        if depth_txt:
            hqins_depth = int(depth_txt)
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
    hits = glob.glob("*.hqprj")
    if not hits:
        print("Error: no .hqprj in current directory; pass a project path.")
        sys.exit(1)
    return hits[0]
