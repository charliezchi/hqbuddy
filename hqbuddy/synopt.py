# -*- coding: utf-8 -*-
"""Per-project synthesis option overrides: hqbuddy -synopt.

Options live in a sidecar <proj>.synopt.json next to the .hqprj.  When
generating run_hqprj.tcl, flow.run_flow injects override rtl.set /
lo.slo.set lines after the hqprj2tcl defaults so later lines win.
"""
import json
import os
import sys

# option key -> ("rtl"|"slo"|"fsm"|"postsyn", ...)
#   rtl/slo  : "onoff" boolean switches (rtl.set / lo.slo.set -key on|off)
#   fsm      : FSM re-encoding choice -> fsm.set -encoding <v> (pre-synthesis)
#   postsyn  : area effort choice -> postsyn.areaopt.set -effort <v> +
#              postsyn.areaopt (injected right after design.rtlsyn)
RTL_KEYS = ("infer_ram", "infer_rom", "infer_srl", "fsm_opt", "expr_opt",
            "mux_opt", "dsp_map", "share_opt", "macro_rebuild")
SLO_KEYS = ("sweep", "clk_conv", "data_opt", "merge", "cut_merge")
FSM_KEYS = ("fsm_encoding",)
AREA_KEYS = ("postsyn_areaopt",)
CDC_KEYS = ("cdc_sync",)
FSM_ENCODINGS = ("auto", "onehot", "binary", "gray", "johnson")
AREA_EFFORTS = ("tiny", "low", "std", "high", "extra", "extreme", "none", "auto")


def sidecar_path(hqprj_path: str) -> str:
    work = os.path.dirname(os.path.abspath(hqprj_path))
    return os.path.join(work, os.path.basename(hqprj_path) + ".synopt.json")


def load_overrides(hqprj_path: str) -> dict:
    p = sidecar_path(hqprj_path)
    if os.path.isfile(p):
        try:
            return json.load(open(p, encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            print(f"Warning: 无法解析 {p}，忽略综合选项覆盖")
    return {}


def inject_synopt(tcl_lines: list, hqprj_path: str) -> list:
    """Insert override lines into a freshly generated flow TCL.

    Pre-synthesis keys (rtl.set / lo.slo.set / fsm.set) go after the last
    default set line so later lines win; the post-synthesis area-optimization
    pair goes right after design.rtlsyn (fallback anchors: design.flatten,
    then just before design.pack)."""
    ov = load_overrides(hqprj_path)
    if not ov:
        return tcl_lines
    pre: list = []
    post: list = []
    post_cdc: list = []  # cdc lines always go AFTER the areaopt pair: areaopt
    # must not be allowed to merge away a freshly inserted sync chain
    for key in sorted(ov):
        fam = _KEYMAP.get(key, "rtl")
        v = ov[key]
        if fam == "rtl":
            pre.append(f"rtl.set -{key} {v}")
        elif fam == "slo":
            pre.append(f"lo.slo.set -{key} {v}")
        elif fam == "fsm":
            pre.append(f"fsm.set -encoding {v}")
        elif fam == "postsyn":
            post.append(f"postsyn.areaopt.set -effort {v}")
            post.append("postsyn.areaopt")
        elif fam == "cdc":
            # CDC sync-chain insertion (post-synthesis netlist surgery, before
            # design.tdomap so the new FFs get mapped normally)
            if v == "on":
                post_cdc.append("lo.cdc_sync_reg.insert")
            elif v.isdigit() and int(v) >= 1:
                post_cdc.append(f"lo.cdc_sync_reg.insert -regcnt {v}")
    if pre:
        last_set = -1
        for i, ln in enumerate(tcl_lines):
            st = ln.strip()
            if st.startswith(("rtl.set", "lo.slo.set", "fsm.set")):
                last_set = i
        if last_set >= 0:
            tcl_lines[last_set + 1:last_set + 1] = pre
        else:
            # no default sets: insert before synthesis entry if present, else append
            idx = next((i for i, ln in enumerate(tcl_lines)
                        if ln.strip().startswith("design.analyze")), None)
            pos = idx if idx is not None else len(tcl_lines)
            tcl_lines[pos:pos] = pre
    if post or post_cdc:
        post = post + post_cdc
        anchor = next((i for i, ln in enumerate(tcl_lines)
                       if ln.strip().startswith("design.rtlsyn")), None)
        if anchor is None:
            anchor = next((i for i, ln in enumerate(tcl_lines)
                           if ln.strip().startswith("design.flatten")), None)
        if anchor is not None:
            tcl_lines[anchor + 1:anchor + 1] = post
        else:
            pack = next((i for i, ln in enumerate(tcl_lines)
                         if ln.strip().startswith(("design.pack", "impl.pack"))),
                        None)
            pos = pack if pack is not None else len(tcl_lines)
            tcl_lines[pos:pos] = post
    print(f"[i] 已注入综合选项覆盖: {', '.join(sorted(ov))}")
    return tcl_lines


_KEYMAP = {k: "rtl" for k in RTL_KEYS}
_KEYMAP.update({k: "slo" for k in SLO_KEYS})
_KEYMAP.update({k: "fsm" for k in FSM_KEYS})
_KEYMAP.update({k: "postsyn" for k in AREA_KEYS})
_KEYMAP.update({k: "cdc" for k in CDC_KEYS})


def _value_help(key: str) -> str:
    fam = _KEYMAP[key]
    if fam in ("rtl", "slo"):
        return "on|off"
    if fam == "fsm":
        return "|".join(FSM_ENCODINGS)
    if fam == "cdc":
        return "on|off|<N>"
    return "|".join(AREA_EFFORTS)


def _keys_help() -> str:
    return (f"{', '.join(RTL_KEYS)} (rtl.set); {', '.join(SLO_KEYS)} (lo.slo.set); "
            f"fsm_encoding={ '|'.join(FSM_ENCODINGS) } (fsm.set); "
            f"postsyn_areaopt={ '|'.join(AREA_EFFORTS) } (postsyn.areaopt); "
            f"cdc_sync=on|off|<N> (lo.cdc_sync_reg.insert, N=级数缺省2)")


def run_synopt(args: list) -> None:
    """Entry for 'hqbuddy -synopt [<src.hqprj>] [-show | -set k=v ... | -clear]'."""
    if not args:
        print("Usage: hqbuddy -synopt [<src.hqprj>] [-show | -set k=<value> ... | -clear]")
        print("       (.hqprj 可省略：当前目录唯一工程自动探测)")
        print(f"       keys: {_keys_help()}")
        sys.exit(1)
    hqprj_arg = None
    mode = "-show"
    sets: dict = {}
    clear = False
    i = 0
    while i < len(args):
        a = args[i]
        if a in ("-show", "-clear"):
            mode = a
            i += 1
        elif a == "-set":
            mode = "-set"
            i += 1
            while i < len(args) and "=" in args[i] and not args[i].startswith("-"):
                k, _, v = args[i].partition("=")
                if not k or not v:
                    print(f"Error: -set 需要 key=<value> 形式: {args[i]}")
                    sys.exit(1)
                sets[k] = v
                i += 1
        elif a.startswith("-"):
            print(f"Error: unknown -synopt option: {a}")
            sys.exit(1)
        elif hqprj_arg is None:
            hqprj_arg = a
            i += 1
        else:
            print(f"Error: unexpected argument: {a}")
            sys.exit(1)
    if mode == "-set" and not sets:
        print("Error: -set 需要至少一个 key=<value> 参数")
        sys.exit(1)
    if hqprj_arg is None:
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
        hqprj_arg = cands[0]
    hqprj_path = os.path.abspath(hqprj_arg)
    if not os.path.isfile(hqprj_path):
        print(f"Error: file not found: {hqprj_path}")
        sys.exit(1)

    p = sidecar_path(hqprj_path)
    cur = {}
    if os.path.isfile(p):
        try:
            cur = json.load(open(p, encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            cur = {}

    if clear:
        if os.path.isfile(p):
            os.remove(p)
            print("[OK] 综合选项覆盖已清除（恢复 hqprj2tcl 默认值）")
        else:
            print("[OK] 无覆盖配置")
        return

    if mode == "-set":
        for k, v in sets.items():
            if k not in _KEYMAP:
                print(f"Error: 未知综合选项: {k}（可选：{', '.join(sorted(_KEYMAP))}）")
                sys.exit(1)
            allowed = _value_help(k)
            if k == "cdc_sync":
                if v != "on" and v != "off" and not (v.isdigit() and int(v) >= 1):
                    print(f"Error: {k} 的值只能是 {allowed}，得到: {v}")
                    sys.exit(1)
                if v.isdigit() and int(v) >= 3:
                    print("Warning: cdc_sync>=3 级的同步链在用户 RTL 会被推断为 SRL16 "
                          "(open_issues V9: LA tap 读恒 0)；本功能插入的链在综合后网表上、"
                          "不受影响。规避手段：-set infer_srl=off。")
            if k == "cdc_sync" and v != "off":
                print("Warning: FT110126 实测 lo.cdc_sync_reg.insert 在批处理会话"
                      "（-cmd 脚本）静默无效果（6 种参数变体验证，疑似仅厂商 GUI "
                      "流程可用）——本键当前版本不会真正插链，勿依赖；改用 RTL 手写"
                      "同步链。")
            elif v not in allowed.split("|"):
                print(f"Error: {k} 的值只能是 {allowed}，得到: {v}")
                sys.exit(1)
        cur.update(sets)
        with open(p, "w", encoding="utf-8") as f:
            json.dump(cur, f, ensure_ascii=False, indent=2, sort_keys=True)
        print(f"[OK] 综合选项覆盖已保存: {p}")

    print("当前覆盖（未列出的项 = hqprj2tcl 默认值）:")
    if cur:
        for k in sorted(cur):
            print(f"  {k} = {cur[k]}")
    else:
        print("  （无）")
