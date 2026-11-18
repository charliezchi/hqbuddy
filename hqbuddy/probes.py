"""Shared probe model (P0-A2): endpoint mapping between the registered probe
selection (.hqins), the RTL elaboration database (static-elab dump), and the
exported instrumented netlist (signal.inf).

The model records, for every probe: instance endpoint path, signal, bitslice,
direction (sample/trigger), sampling domain and hardware order — plus the
hardware net name the probe maps to.  Ambiguity is exposed structurally: a
module instantiated more than once yields an ambiguous endpoint (per-instance
selection arrives with the P2/D cross-hierarchy work; this model makes the
limitation explicit instead of hiding it behind sorted short identities).
"""

import json
import os
import re
import sys

# escaped identifier: leading backslash — treat the whole name as opaque
_ESC_RE = re.compile(r"^\\.*\\$")
_SLICE_RE = re.compile(r"^(.+)\[(\d+)(?::(\d+))?\]$")


def parse_probe_ref(name: str) -> dict:
    """Structurally parse 'name', 'name[N]' or 'name[M:N]'.

    Escaped identifiers (\\odd.name[0]\\) are returned opaque: the bracket is
    part of the identifier, never a slice."""
    if _ESC_RE.match(name):
        return {"base": name, "slice": None, "escaped": True}
    m = _SLICE_RE.match(name)
    if not m:
        return {"base": name, "slice": None, "escaped": False}
    msb = int(m.group(2))
    lsb = int(m.group(3)) if m.group(3) is not None else msb
    return {"base": m.group(1), "slice": (msb, lsb), "escaped": False}


def _instance_paths(modules: list, top: str) -> dict:
    """module name -> [instance paths] (structural; array instances keep
    their [N] index inside the path segment)."""
    top_mod = next((m for m in modules
                    if m["module"]["name"].split("[")[0] == top), None)
    paths: dict = {}

    def walk(mod: dict, prefix: str, seen: set):
        for inst in mod["module"].get("inst_mod", []):
            path = f"{prefix}/{inst['inst_name']}" if prefix else inst["inst_name"]
            child = next((m for m in modules
                          if m["module"]["name"] == inst["mod_name"]), None)
            if child is None or id(child) in seen:
                continue
            seen.add(id(child))
            paths.setdefault(child["module"]["name"], []).append(path)
            walk(child, path, seen)

    if top_mod:
        walk(top_mod, "", {id(top_mod)})
    return paths


def build_probe_map(proj: dict, build_id: str | None = None) -> dict:
    """Build the probe endpoint map from .hqins selection + elaboration dump.

    Fails with concrete endpoints when a registered signal no longer exists,
    its slice no longer fits, or the sampling clock vanished (P0-A2: renamed/
    deleted/width-changed selections must be reported, never silently kept)."""
    from . import insight

    info = insight._load_signal_info(proj)
    if info is None:
        print("Error: .hqins 无 [SIGNAL JSON INFO]——先 -insight -init。")
        sys.exit(1)
    sigs = insight._collect_signals(info)
    _, la_info = insight._la_info_path(proj)
    modules = insight._load_dump_json(proj)

    paths = _instance_paths(modules, proj["top"])
    catalog: dict = {}
    for m in modules:
        mod_name = m["module"]["name"]
        for s in m.get("normal_signals", []):
            catalog.setdefault((mod_name, s["name"]), s)

    la = la_info["la_list"][0] if la_info.get("la_list") else {}
    clk_entry = (info.get("module_sample_list") or [{}])[0]
    clk_name = clk_entry.get("clk_signal_name", "")

    entries = []
    order_nets = []
    for role, key in (("sample", "s_list"), ("trigger", "t_list"),
                      ("sample+trigger", "st_list")):
        for e in la.get(key, []):
            order_nets.append((e["ip_signal_name"], role, e))

    if not sigs:
        print("Error: 没有任何探针登记——先 -insight -add。")
        sys.exit(1)

    for net, role, e in order_nets:
        sig = next((s for s in sigs if s["name"] == e["raw_signal_name"]
                    and s["module"] == e.get("module_name")), None)
        if sig is None:
            print(f"Error: 探针 {e['raw_signal_name']} 在信号选择列表中缺失（.hqins 不一致）。")
            sys.exit(1)
        key = (sig["module"], sig["name"])
        cat = catalog.get(key)
        insts = paths.get(sig["module"], [])
        if cat is None:
            print(f"Error: 已登记信号在当前设计中不存在: {sig['name']}（模块 {sig['module']}）"
                  f"——RTL 改名或删除后需 -del 旧名、重新 -add。")
            sys.exit(1)
        raw_hi, raw_lo = cat.get("range_msb", 0), cat.get("range_lsb", 0)
        hi, lo = e["msb"], e["lsb"]
        if hi > raw_hi or lo < raw_lo:
            print(f"Error: 探针位片超界: {sig['name']}[{hi}:{lo}]，"
                  f"当前设计位宽 {sig['name']}[{raw_hi}:{raw_lo}]（模块 {sig['module']}）"
                  f"——位宽变化后需重新 -del/-add。")
            sys.exit(1)
        entries.append({
            "net": net,
            "role": role,
            "raw": sig["name"],
            "module": sig["module"],
            "endpoint_signal": sig["name"],
            "slice": [hi, lo],
            "width": hi - lo + 1,
            "sample_type": sig["sample_type"],
            "clk": clk_name,
            "instances": insts,
            "ambiguous": len(insts) > 1,
            "show": e.get("show_hier_name", sig["name"]),
        })

    # sampling clock existence: must resolve by name somewhere in the design
    if clk_name:
        found = any(s["name"] == clk_name for m in modules
                    for s in m.get("normal_signals", []))
        if not found:
            print(f"Error: 采样时钟 {clk_name} 在当前设计中不存在——"
                  f"时钟改名后需清空探针重新登记。")
            sys.exit(1)

    amb = [e for e in entries if e["ambiguous"]]
    if amb:
        for e in amb:
            print(f"Warning: 探针 {e['raw']} 所在模块 {e['module']} 有 "
                  f"{len(e['instances'])} 个实例（{'/'.join(e['instances'])}）——"
                  "当前插桩按模块粒度，无法按实例区分（跨层次按实例选择将在 P2 交付）。")

    return {
        "build_id": build_id,
        "top": proj["top"],
        "clk": {"signal": clk_name,
                "instances": paths.get(_clk_module(info, modules), [])},
        "probes": entries,
        "data_in_order": [e["net"] for e in entries if e["role"] != "trigger"],
        "trig_in_order": [e["net"] for e in entries if e["role"] != "sample"],
    }


def _clk_module(info: dict, modules: list) -> str | None:
    entry = (info.get("module_sample_list") or [{}])[0]
    return entry.get("clk_module_name")


def write_probe_map(proj: dict, probe_map: dict) -> str:
    path = os.path.join(proj["hqins_dir"], "hq_import", "probe_map.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(probe_map, f, indent=2, ensure_ascii=False)
    return path
