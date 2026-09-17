# -*- coding: utf-8 -*-
"""Per-project synthesis option overrides: hqbuddy -synopt.

Options live in a sidecar <proj>.synopt.json next to the .hqprj.  When
generating run_hqprj.tcl, flow.run_flow injects override rtl.set /
lo.slo.set lines after the hqprj2tcl defaults so later lines win.
"""
import json
import os
import sys

# option key -> ("rtl"|"slo", kind)   kind: "onoff" boolean switches
RTL_KEYS = ("infer_ram", "infer_rom", "infer_srl", "fsm_opt", "expr_opt",
            "mux_opt", "dsp_map", "share_opt", "macro_rebuild")
SLO_KEYS = ("sweep", "clk_conv", "data_opt", "merge", "cut_merge")


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
    """Insert override rtl.set/lo.slo.set lines after the last default set line."""
    ov = load_overrides(hqprj_path)
    if not ov:
        return tcl_lines
    inject: list = []
    last_set = -1
    for i, ln in enumerate(tcl_lines):
        st = ln.strip()
        if st.startswith("rtl.set") or st.startswith("lo.slo.set"):
            last_set = i
    for key in sorted(ov):
        fam = _KEYMAP.get(key, "rtl")
        cmd = "rtl.set" if fam == "rtl" else "lo.slo.set"
        inject.append(f"{cmd} -{key} {ov[key]}")
    if last_set >= 0:
        tcl_lines[last_set + 1:last_set + 1] = inject
    else:
        # no default sets: insert before synthesis entry if present, else append
        idx = next((i for i, ln in enumerate(tcl_lines)
                    if ln.strip().startswith("design.analyze")), None)
        pos = idx if idx is not None else len(tcl_lines)
        tcl_lines[pos:pos] = inject
    print(f"[i] 已注入综合选项覆盖: {', '.join(sorted(ov))}")
    return tcl_lines


_KEYMAP = {k: "rtl" for k in RTL_KEYS}
_KEYMAP.update({k: "slo" for k in SLO_KEYS})


def run_synopt(args: list) -> None:
    """Entry for 'hqbuddy -synopt <src.hqprj> [-show | -set k=v ... | -clear]'."""
    if not args:
        print("Usage: hqbuddy -synopt <src.hqprj> [-show | -set k=on|off ... | -clear]")
        print(f"       keys: {', '.join(RTL_KEYS)} (rtl.set); "
              f"{', '.join(SLO_KEYS)} (lo.slo.set)")
        sys.exit(1)
    hqprj_path = os.path.abspath(args[0])
    if not os.path.isfile(hqprj_path):
        print(f"Error: file not found: {hqprj_path}")
        sys.exit(1)
    mode = "-show"
    sets: dict = {}
    clear = False
    i = 1
    while i < len(args):
        a = args[i]
        if a in ("-show", "-set", "-clear"):
            mode = a
            i += 1
            if mode == "-set":
                while i < len(args):
                    k, _, v = args[i].partition("=")
                    if not k or not v:
                        print(f"Error: -set 需要 key=on|off 形式: {args[i]}")
                        sys.exit(1)
                    sets[k] = v
                    i += 1
            break
        print(f"Error: unknown -synopt option: {a}")
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
            if v not in ("on", "off"):
                print(f"Error: {k} 的值只能是 on|off，得到: {v}")
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
