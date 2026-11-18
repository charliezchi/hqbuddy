"""Staged instrumented implementation flow (P0-A3/A4).

Instead of the official `run_hqprj2hqins_flow` wrapper (which clears the impl
directory up front, spawns the downloader GUI, and can exit 0 on failures),
this module:

1. generates a PRIVATE derived project (hqins_impl.hqprj) inside a fresh
   per-run build directory — the main .hqprj is never modified;
2. converts it to a standard flow TCL via the official `hqprj2tcl`
   (verified equivalent: same command set, no downloader);
3. rewrites the TCL into per-stage blocks wrapped in `catch` with machine
   markers (`@STAGE <name> begin|ok|FAIL: ...`), so a TCL-level error can
   never masquerade as success;
4. accepts artifacts stage by stage (synthesis/pack/place/route/bitgen) and
   only publishes into hqins_impl/ after ALL stages pass;
5. on failure keeps the previous hqins_impl/ untouched and preserves the
   failed build directory plus its logs for reproduction.
"""

import glob
import os
import re
import shutil
import subprocess
import sys
import time

from .hqprj_parser import parse_hqprj
from .utils import wait_process

# stage name -> (opening command prefixes, closing artifact requirements).
# Report/dump commands (nl.report/xpn.write/ta.*) attach to the most recent
# opening stage; other commands attach there too.  Preamble commands (set,
# dv.setup, option settings) run unwrapped before the first stage.
STAGE_OPEN = {
    "design.analyze": "synth",
    "design.rtlsyn": "synth",
    "design.tdomap": "synth",
    "design.flatten": "synth",
    "impl.guide.unset": "synth",
    "design.pack": "pack",
    "impl.pack": "pack",
    "design.place": "place",
    "impl.place": "place",
    "design.route": "route",
    "impl.route": "route",
    "design.bitgen": "bitgen",
    "impl.bitgen": "bitgen",
}
PREAMBLE_PREFIXES = ("set ", "dv.setup", "ta.set", "rtl.set", "lo.set",
                     "lo.slo.set")

STAGE_ORDER = ("synth", "pack", "place", "route", "bitgen")


def _tcl_path(path: str) -> str:
    return os.path.abspath(path).replace(os.sep, "/")


def _split_commands(text: str) -> list:
    """Split a flow TCL into top-level commands (brace-depth aware).

    Returns a list of command strings (possibly multi-line, comments and
    blank lines dropped)."""
    cmds = []
    buf: list = []
    depth = 0
    for raw in text.splitlines():
        line = raw.rstrip("\n")
        s = line.strip()
        if not buf:
            if not s or s.startswith("#"):
                continue
        buf.append(line)
        depth += line.count("{") - line.count("}")
        cont = line.endswith("\\")
        if depth <= 0 and not cont:
            cmds.append("\n".join(buf))
            buf = []
    if buf:  # unbalanced tail: keep it, the stage wrapper will surface the error
        cmds.append("\n".join(buf))
    return cmds


def _first_word(cmd: str) -> str:
    return cmd.strip().split(None, 1)[0] if cmd.strip() else ""


def build_stage_tcl(flow_tcl: str, out_path: str, bin_target_abs: str | None,
                    route_dump: str | None = None,
                    post_route_check: bool = False) -> tuple:
    """Rewrite an hqprj2tcl flow TCL into a staged TCL with per-stage catch
    wrappers and @STAGE markers.  bin_target_abs: rewrite the design.bitgen
    file target to this absolute path (keeps -compress/-bin style flags).
    route_dump: append `design.save <path>` to the route stage (the official
    insight flow saves the post-route design for `-xpn -ins`).
    post_route_check: append insight.check has_vla/has_vio probes emitting
    @CHECK markers (captured by run_stage_build for the VLA manifest).

    Returns (out_path, {stage: [expected artifact basenames]})."""
    with open(flow_tcl, "r", encoding="gbk", errors="replace") as f:
        cmds = _split_commands(f.read())

    preamble: list = []
    stages: dict = {}
    order: list = []
    current = None

    for cmd in cmds:
        w = _first_word(cmd)
        if w in STAGE_OPEN:
            current = STAGE_OPEN[w]
            if current not in stages:
                stages[current] = []
                order.append(current)
            # bitgen target rewrite
            if w in ("design.bitgen", "impl.bitgen") and bin_target_abs:
                toks = cmd.strip().split()
                if len(toks) >= 2 and not toks[1].startswith("-"):
                    toks[1] = "{" + bin_target_abs + "}"
                    cmd = " ".join(toks)
            stages[current].append(cmd)
        elif current is None:
            preamble.append(cmd)
        else:
            stages[current].append(cmd)

    missing = [s for s in STAGE_ORDER if s not in stages]
    if missing:
        print(f"Error: 生成的流程 TCL 缺少阶段命令: {', '.join(missing)}（hqprj2tcl 输出格式变化？）")
        sys.exit(1)

    if route_dump and "route" in stages:
        stages["route"].append(f"design.save {route_dump}")
    if post_route_check and "route" in stages:
        stages["route"].append('set hb_vla [insight.check has_vla]')
        stages["route"].append('puts "@CHECK has_vla=$hb_vla"')
        stages["route"].append('set hb_vio [insight.check has_vio]')
        stages["route"].append('puts "@CHECK has_vio=$hb_vio"')

    expected = {}
    out = ["#[hqbuddy staged flow] generated from " + os.path.basename(flow_tcl),
           "set _hb_err \"\"", ""]
    out += preamble
    out.append("")
    for stage in order:
        out.append(f"puts \"@STAGE {stage} begin\"")
        out.append("if {[catch {")
        out.append(stages[stage][0] if len(stages[stage]) == 1
                   else "\n".join(stages[stage]))
        out.append("} _hb_err]} {")
        out.append(f"    puts \"@STAGE {stage} FAIL: $_hb_err\"")
        out.append("    exit 2")
        out.append("}")
        out.append(f"puts \"@STAGE {stage} ok\"")
        out.append("")
        expected[stage] = []

    # artifact requirements per stage, derived from the commands themselves;
    # TCL variables set in the preamble (set TOP_MODULE counter_top) are
    # expanded so `${TOP_MODULE}.xpn` matches the real artifact name
    tclvars: dict = {}
    for cmd in preamble:
        m = re.match(r"^set\s+(\w+)\s+(.+)$", cmd.strip())
        if m:
            tclvars[m.group(1)] = m.group(2).strip().strip("{}").strip()

    def _expand(name: str) -> str:
        for k, v in tclvars.items():
            name = name.replace("${" + k + "}", v).replace("$" + k, v)
        return name

    for stage, scmds in stages.items():
        exp = expected[stage]
        for cmd in scmds:
            w = _first_word(cmd)
            toks = cmd.strip().split()
            if w == "design.bitgen" and bin_target_abs:
                exp.append(os.path.basename(bin_target_abs))
            elif w == "xpn.write" and len(toks) >= 2:
                exp.append(os.path.basename(_expand(toks[1].strip("{}"))))
            elif w == "design.save" and len(toks) >= 2:
                exp.append(_expand(toks[1].strip("{}")))
    # synthesis outputs: the rtl dump and resource report
    if "synth" in expected:
        expected["synth"] = []  # verified via markers; names vary by top

    with open(out_path, "w", encoding="gbk", newline="") as f:
        f.write("\n".join(out) + "\n")
    return out_path, expected


def write_derived_project(proj: dict, build_dir: str,
                          main_mode: bool = False) -> str:
    """Generate the build project (hqins_impl.hqprj / build.hqprj) inside
    build_dir.

    insight mode (default): FILE_SRC is swapped to the two instrumented
    netlists.  main mode (VLA combined build): FILE_SRC stays untouched —
    the user's own RTL with the combined IP.  In BOTH modes FILE_TC/FILE_PC
    and RTL_9 are absolutized (the build dir is not the project dir, so
    $WORK_DIR$-relative paths would resolve wrong) and BGEN_1/BGEN_2 are
    forced on so a .bin is always produced.  The user's original .hqprj is
    never written (P0 acceptance)."""
    if main_mode:
        src_lines = open(proj["hqprj"], "r", encoding="utf-8",
                         errors="replace").read().splitlines()
    else:
        netlist = os.path.join(proj["hqins_dir"], "hq_import", "hq_import_with_bscan.v")
        insight_ip = os.path.join(proj["hqins_dir"], "hq_import", "insight_ip.v")
        for f in (netlist, insight_ip):
            if not os.path.isfile(f):
                print(f"Error: 插桩产物缺失: {f}——先 -insight -refresh 重建。")
                sys.exit(1)
        src_lines = []
        for ln in open(proj["hqprj"], "r", encoding="utf-8",
                       errors="replace").read().splitlines():
            stripped = ln.strip()
            if stripped.startswith(("FILE_SRC", "FILE_SRC_DISABLED", "FILE_TIME",
                                    "FILE_TIME_CST")):
                continue
            src_lines.append(ln)
        src_lines.append(f"FILE_SRC={_tcl_path(netlist)}")
        src_lines.append(f"FILE_SRC={_tcl_path(insight_ip)}")
        src_lines.append(f"FILE_TIME={int(os.path.getmtime(netlist))}")
        src_lines.append(f"FILE_TIME={int(os.path.getmtime(insight_ip))}")

    prj = parse_hqprj(proj["hqprj"])
    out_lines = []
    for ln in src_lines:
        stripped = ln.strip()
        if stripped.startswith("BGEN_1=false"):
            out_lines.append("BGEN_1=true")
            continue
        if stripped.startswith("BGEN_2=false"):
            out_lines.append("BGEN_2=true")
            continue
        if stripped.startswith("FILE_TC=") or stripped.startswith("FILE_PC="):
            key, _, val = stripped.partition("=")
            if val.strip() == "NONE":
                out_lines.append(ln)
            else:
                # resolve against the MAIN project dir, write absolute
                resolved = val
                if resolved.startswith("$WORK_DIR$"):
                    resolved = resolved[len("$WORK_DIR$"):]
                if not os.path.isabs(resolved):
                    resolved = os.path.join(proj["work_dir"], resolved)
                out_lines.append(f"{key}={_tcl_path(resolved)}")
            continue
        if stripped.startswith(("FILE_SRC=", "FILE_SRC_DISABLED=")) \
                and not stripped.endswith("=NONE"):
            # $WORK_DIR$/relative sources resolve against the BUILD project's
            # directory, not the main project dir — absolutize
            key, _, val = stripped.partition("=")
            resolved = val.strip()
            if resolved.startswith("$WORK_DIR$"):
                resolved = resolved[len("$WORK_DIR$"):]
            if not os.path.isabs(resolved):
                resolved = os.path.join(proj["work_dir"], resolved)
            out_lines.append(f"{key}={_tcl_path(resolved)}")
            continue
        if stripped.startswith("RTL_9=") and prj["include_dir"]:
            out_lines.append(f"RTL_9={_tcl_path(prj['include_dir'])}")
            continue
        out_lines.append(ln)
    if main_mode:
        for f in prj["tc"] + prj["pc"]:
            if os.path.isfile(f):
                out_lines.append(f"FILE_TIME_CST={int(os.path.getmtime(f))}")
    else:
        for f in prj["tc"] + prj["pc"]:
            out_lines.append(f"FILE_TIME_CST={int(os.path.getmtime(f))}" if os.path.isfile(f)
                             else "FILE_TIME_CST=0")

    path = os.path.join(build_dir, "hqins_impl.hqprj" if not main_mode
                        else "build.hqprj")
    with open(path, "w", encoding="utf-8", newline="") as f:
        f.write("\n".join(out_lines) + "\n")
    return path


def run_stage_build(proj: dict, hqfpga_exe: str, build_id: str,
                    require_bin: bool = True, main_mode: bool = False,
                    post_route_check: bool = False) -> dict:
    """Run the full staged build in a private directory.  Returns the outputs
    dict for the manifest.  Exits nonzero on any stage failure, preserving the
    previous artifacts and leaving a failed_build_<id>/ reproduction dir.

    insight mode (default): builds the derived project and publishes into
    hqins_impl/ (route-stage design.save kept for -xpn -ins).
    main_mode: builds the MAIN project (combined VLA IP) and publishes into
    its OUT_DIR; post_route_check appends insight.check has_vla/has_vio to
    the route stage and records the verdicts in outputs['vla_check']."""
    if main_mode:
        import_dir = os.path.abspath(proj["work_dir"])
        impl_dir = parse_hqprj(proj["hqprj"])["out_dir_abs"]
        failed_root = import_dir
    else:
        import_dir = os.path.join(proj["hqins_dir"], "hq_import")
        impl_dir = os.path.join(import_dir, "hqins_impl")
        failed_root = import_dir
    build_dir = os.path.join(import_dir, f".build_{build_id}")
    if os.path.isdir(build_dir):
        shutil.rmtree(build_dir)
    os.makedirs(build_dir)
    # the route-stage design.save writes here; the official flow pre-creates it
    os.makedirs(os.path.join(build_dir, "hq_temp"), exist_ok=True)

    def _fail(msg, tail=None):
        # preserve reproduction data; never publish
        failed = os.path.join(failed_root, f"failed_build_{build_id}")
        if os.path.isdir(failed):
            shutil.rmtree(failed)
        try:
            with open(os.path.join(build_dir, "failure.txt"), "w",
                      encoding="utf-8", errors="replace", newline="") as f:
                f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')}  build {build_id}\n")
                f.write(msg + "\n")
                if tail:
                    f.write("\n--- tool output tail ---\n")
                    f.write("\n".join(tail[-40:]) + "\n")
            os.rename(build_dir, failed)
        except OSError:
            failed = build_dir
        print(f"Error: {msg}")
        print(f"       失败现场已保留: {failed}")
        if tail:
            for ln in tail[-15:]:
                print("  " + ln)
        print("[FAIL] staged build")
        sys.exit(1)

    der_prj = write_derived_project(proj, build_dir, main_mode=main_mode)

    # 1. official hqprj2tcl -> standard flow TCL (cwd=build_dir, output relative)
    gen_tcl = os.path.join(build_dir, "_gen.tcl")
    with open(gen_tcl, "w", encoding="gbk") as f:
        f.write(f"hqprj2tcl {{{_tcl_path(der_prj)}}} run_hqins.tcl\nexit\n")
    proc = subprocess.run([hqfpga_exe, "-cmd", gen_tcl], cwd=build_dir,
                          capture_output=True, text=True, errors="replace",
                          timeout=300)
    flow_tcl = os.path.join(build_dir, "run_hqins.tcl")
    if proc.returncode != 0 or not os.path.isfile(flow_tcl):
        _fail("hqprj2tcl 未能生成流程 TCL",
              (proc.stdout or "").splitlines() + (proc.stderr or "").splitlines())

    # 2. staged TCL (bin target inside build dir)
    prj_stem = os.path.splitext(os.path.basename(proj["hqprj"]))[0]
    bin_target = os.path.join(build_dir, f"{prj_stem}.bin")
    stage_tcl, expected = build_stage_tcl(
        flow_tcl, os.path.join(build_dir, "build_stage.tcl"), bin_target,
        route_dump=None if main_mode else "hq_temp/_step_run_route.dump",
        post_route_check=post_route_check)
    started = time.time()
    print(f"Staged build {build_id} in {os.path.basename(build_dir)} ...")

    proc = subprocess.Popen([hqfpga_exe, "-cmd", stage_tcl], cwd=build_dir,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            text=True, errors="replace")
    seen: dict = {}
    log_lines: list = []
    for ln in proc.stdout:
        ln = ln.rstrip("\r\n")
        log_lines.append(ln)
        m = re.match(r"@STAGE (\w+) (begin|ok|FAIL:.*)", ln)
        if m:
            seen.setdefault(m.group(1), []).append(m.group(2))
            print(f"  [{m.group(1)}] {m.group(2)}")
        elif ln.strip():
            print("  " + ln)
    proc.wait()
    with open(os.path.join(build_dir, "build.log"), "w", encoding="utf-8",
              errors="replace", newline="") as f:
        f.write("\n".join(log_lines) + "\n")

    # insight.check verdicts (post_route_check mode)
    vla_check: dict = {}
    for ln in log_lines:
        m = re.search(r"@CHECK has_(vla|vio)=(\S+)", ln)
        if m:
            vla_check[m.group(1)] = m.group(2)

    if proc.returncode != 0:
        stage = _failed_stage(seen)
        _fail(f"实现流程在 {stage or '未知'} 阶段失败（exit {proc.returncode}）", log_lines)

    # 3. staged artifact acceptance
    stages_ok = [s for s in STAGE_ORDER
                 if "ok" in seen.get(s, []) and "FAIL" not in " ".join(seen.get(s, []))]
    if set(stages_ok) != set(STAGE_ORDER):
        _fail(f"阶段标记不完整：完成 {stages_ok or '无'}（期望 {list(STAGE_ORDER)}）", log_lines)

    artifacts = {}
    for stage in STAGE_ORDER:
        missing = [a for a in expected.get(stage, [])
                   if not _fresh(os.path.join(build_dir, a), started)]
        if missing and not (stage == "bitgen" and not require_bin):
            _fail(f"阶段 {stage} 产物缺失: {', '.join(missing)}", log_lines)
        for a in expected.get(stage, []):
            p = os.path.join(build_dir, a)
            if os.path.isfile(p):
                artifacts[a] = p

    bin_path = bin_target if os.path.isfile(bin_target) else None
    if require_bin and not bin_path:
        _fail(f"bitgen 阶段通过但未找到预期位流: {bin_target}", log_lines)

    # bitstream identity check: a zero-exit run that left a stale/garbage bin
    # behind must not be published as a success.  The header design/device
    # must match this project (fake bin => rejected here).
    if bin_path:
        from .downloader import read_bitstream_header
        die = parse_hqprj(proj["hqprj"])["die"]
        try:
            hdr = read_bitstream_header(bin_path)
        except Exception:
            hdr = None
        if not hdr or not hdr.get("design"):
            _fail(f"位流头无法解析（{bin_path}）——疑似损坏或伪造产物，拒绝发布", log_lines)
        # the header records the TOP MODULE (not the project file name)
        if hdr["design"] != proj["top"]:
            _fail(f"位流头 design={hdr['design']} != 工程顶层 {proj['top']}——"
                  "旧产物混入，拒绝发布", log_lines)
        if hdr.get("device") and die and die not in hdr["device"] \
                and hdr["device"] not in die:
            _fail(f"位流头 device={hdr['device']} 与工程器件 {die} 不符——拒绝发布",
                  log_lines)

    # 4. timing + resource verdict (parsed in the build dir, stored in manifest)
    timing = _collect_timing(build_dir, proj["top"])
    _print_timing(timing)

    # 5. publish: swap into hqins_impl/ (keep one previous generation).
    # All hashes/paths are computed BEFORE the rename: bin_path points into
    # build_dir which ceases to exist afterwards.
    bin_sha = _sha(bin_path) if bin_path else None
    prev = os.path.join(import_dir, ".build_prev")
    if os.path.isdir(prev):
        shutil.rmtree(prev)
    if os.path.isdir(impl_dir):
        try:
            os.rename(impl_dir, prev)
        except OSError as e:
            _fail(f"无法归档旧实现目录 hqins_impl: {e}", log_lines)
    try:
        os.rename(build_dir, impl_dir)
    except OSError as e:
        if os.path.isdir(prev) and not os.path.isdir(impl_dir):
            os.rename(prev, impl_dir)  # roll back
        _fail(f"无法发布实现目录: {e}", log_lines)

    impl_bin = os.path.join(impl_dir, os.path.basename(bin_path)) \
        if bin_path else None
    return {"build_id": build_id,
            "bin": impl_bin.replace(os.sep, "/") if impl_bin else None,
            "bin_sha256": bin_sha,
            "dir": impl_dir.replace(os.sep, "/"),
            "stages": {s: "ok" for s in STAGE_ORDER},
            "timing": timing,
            "vla_check": vla_check,
            "elapsed_s": round(time.time() - started, 1),
            "derived_prj": os.path.join(
                impl_dir,
                "build.hqprj" if main_mode else "hqins_impl.hqprj").replace(os.sep, "/")}


def _failed_stage(seen: dict) -> str | None:
    for stage, marks in seen.items():
        if any(m.startswith("FAIL") for m in marks):
            return stage
    return None


def _fresh(path: str, since: float) -> bool:
    return os.path.isfile(path) and os.path.getmtime(path) >= since


def _sha(path: str) -> str | None:
    import hashlib
    try:
        h = hashlib.sha256()
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(1 << 20), b""):
                h.update(chunk)
        return h.hexdigest()
    except OSError:
        return None


def _collect_timing(work: str, top: str | None) -> dict:
    from .report import _parse_fmax, _parse_util, _parse_wns
    timing: dict = {"sdc_loaded": True, "src": None}
    w = _parse_wns(work, top)
    if w:
        timing["wns_setup_ps"] = w["wns_setup_ps"]
        timing["wns_hold_ps"] = w["wns_hold_ps"]
        timing["setup_met"] = w["setup_met"]
        timing["hold_met"] = w["hold_met"]
        timing["paths"] = w["paths"]
        timing["src"] = w["src"]
    fm = _parse_fmax(work)
    if fm:
        timing["fmax"] = fm[0].get("fmax")
    util = _parse_util(work)
    if util:
        timing["util"] = util.get("rows")
    return timing


def _print_timing(timing: dict) -> None:
    setup = timing.get("wns_setup_ps")
    hold = timing.get("wns_hold_ps")
    if setup is None and hold is None:
        print("[WARN] 时序状态未知（未解析到 slack 报告）——实现成功但未验证时序。")
        return
    violated = not (timing.get("setup_met", True) and timing.get("hold_met", True))
    tag = "VIOLATED" if violated else "MET"
    print(f"Timing [{tag}]: setup WNS {setup} ps, hold WNS {hold} ps "
          f"({timing.get('paths', '?')} paths, {timing.get('src') or '?'})")
    if timing.get("fmax"):
        print(f"        Fmax: {timing['fmax']}")
    rows = timing.get("util") or {}
    for name, (used, total, pct) in rows.items():
        if name in ("LUT", "EBR18", "JTAG", "SLICEL", "FFLAT") or pct >= 70:
            print(f"        {name}: {used}/{total} ({pct}%)")
