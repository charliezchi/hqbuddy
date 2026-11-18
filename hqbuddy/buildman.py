"""Build manifest for the instrumented implementation flow.

A single-run build manifest fingerprints EVERY input the instrumented build
depends on: .hqprj build-relevant fields (volatile GUI bookkeeping excluded),
enabled source files in order with content hashes, include-dir contents,
generated-IP (.hqip) dependencies, device identity, tool identity, the probe
selection, storage parameters and the .ddf content.  `-insight -run` compares
the current inputs against the manifest of the last successful build and
re-instruments when anything changed, so stale instrumentation can no longer
be implemented silently (P0-A1).

The manifest also records the accepted outputs (bin path + sha256, per-stage
status, timing verdict) so `-insight -program` and `-insight -capture` can
verify they are operating on exactly the accepted build.
"""

import hashlib
import json
import os

from .hqprj_parser import parse_hqprj

MANIFEST_NAME = ".build_manifest.json"

# .hqprj lines excluded from the project fingerprint: volatile bookkeeping
# the GUI rewrites without any build-relevant meaning (mtimes, flow state).
_VOLATILE_KEYS = {"FILE_TIME", "FILE_TIME_CST", "STEP_CURR", "STEP_STATUS"}

# directories never scanned for IP deps (build artifacts, not design inputs)
_IP_SCAN_SKIP_DIRS = {"hqins_run", "hq_run", "seed_sweep", "seed_sweep_ins"}


def _sha256(path: str) -> str | None:
    try:
        h = hashlib.sha256()
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(1 << 20), b""):
                h.update(chunk)
        return h.hexdigest()
    except OSError:
        return None


def _fentry(path: str) -> dict:
    return {"path": path.replace(os.sep, "/"),
            "size": os.path.getsize(path),
            "sha256": _sha256(path)}


def _hqprj_fingerprint(hqprj: str) -> str:
    """Hash of build-relevant .hqprj content (volatile lines dropped)."""
    lines = []
    with open(hqprj, "r", encoding="utf-8", errors="replace") as f:
        for ln in f:
            key = ln.split("=", 1)[0].strip() if "=" in ln else ""
            if key in _VOLATILE_KEYS:
                continue
            lines.append(ln.rstrip("\r\n"))
    return hashlib.sha256("\n".join(lines).encode("utf-8")).hexdigest()


def _dir_files(d: str) -> list:
    out = []
    for base, _dirs, files in os.walk(d):
        for f in files:
            out.append(os.path.join(base, f))
    return sorted(out)


def compute_inputs(proj: dict, version: dict, probes: list, storage: dict) -> dict:
    """Fingerprint every build input.

    probes: ordered [{name, module, msb, lsb, sample_type, clk}] from the
    .hqins selection (caller collects via insight helpers).
    storage: {depth, windows, offset, level} from .hqins sections.
    """
    prj = parse_hqprj(proj["hqprj"])

    sources = [_fentry(p) for p in prj["sources"] if os.path.isfile(p)]
    missing = [p for p in prj["sources"] if not os.path.isfile(p)]

    includes = []
    if prj["include_dir"] and os.path.isdir(prj["include_dir"]):
        includes = [_fentry(p) for p in _dir_files(prj["include_dir"])]

    # generated-IP dependencies: every .hqip under the project tree except
    # build/flow output directories
    ip_deps = []
    for base, dirs, files in os.walk(proj["work_dir"]):
        dirs[:] = [d for d in dirs if d not in _IP_SCAN_SKIP_DIRS]
        for f in files:
            if f.endswith(".hqip"):
                ip_deps.append(_fentry(os.path.join(base, f)))
    ip_deps.sort(key=lambda e: e["path"])

    hqfpga_exe = version.get("hqfpga_path", "")
    tool = {"name": version.get("name"),
            "semver": version.get("semver"),
            "build": version.get("build"),
            "exe_mtime": os.path.getmtime(hqfpga_exe) if os.path.isfile(hqfpga_exe) else None}

    # timing/pin constraint files: they steer implementation and the timing
    # verdict (not the instrumented netlist) — fingerprinted so a tightened
    # SDC cannot leave a stale timing verdict in the manifest
    constraints = [_fentry(f) for f in (prj["tc"] + prj["pc"]) if os.path.isfile(f)]

    ddf_sha = _sha256(proj["ddf"]) if os.path.isfile(proj["ddf"]) else None

    return {
        "project": _hqprj_fingerprint(proj["hqprj"]),
        "sources": sources,
        "missing_sources": missing,
        "includes": includes,
        "ip_deps": ip_deps,
        "constraints": constraints,
        "device": {"family": prj["family"], "die": prj["die"],
                   "package": prj["fields"].get("PACKAGES", ""),
                   "speed": prj["fields"].get("SPEEDS", ""),
                   "condition": prj["fields"].get("CONDITION", "")},
        "tool": tool,
        "probes": probes,
        "storage": storage,
        "ddf": ddf_sha,
    }


def manifest_path(proj: dict) -> str:
    return os.path.join(proj["hqins_dir"], "hq_import", MANIFEST_NAME)


def load(proj: dict) -> dict | None:
    path = manifest_path(proj)
    if not os.path.isfile(path):
        return None
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError):
        return None


def save(proj: dict, manifest: dict) -> str:
    path = manifest_path(proj)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    return path


def new_build_id() -> str:
    import time
    return time.strftime("%Y%m%d_%H%M%S")


def inputs_match(old: dict | None, new: dict) -> tuple:
    """Compare current inputs against a manifest.  Returns (fresh, diffs)
    where diffs is a list of human-readable change descriptions."""
    if old is None or "inputs" not in old:
        return False, ["无历史构建清单"]
    old = old["inputs"]

    diffs: list = []

    def entry_map(entries):
        return {e["path"]: e for e in entries}

    # sources: order matters (file list order affects elaboration)
    if old.get("project") != new["project"]:
        diffs.append("工程配置 (.hqprj 字段)")

    os_, ns_ = old.get("sources", []), new["sources"]
    if [e["path"] for e in os_] != [e["path"] for e in ns_]:
        oldp, newp = {e["path"] for e in os_}, {e["path"] for e in ns_}
        removed, added = sorted(oldp - newp), sorted(newp - oldp)
        if removed:
            diffs.append("移除源文件: " + ", ".join(os.path.basename(p) for p in removed))
        if added:
            diffs.append("新增源文件: " + ", ".join(os.path.basename(p) for p in added))
    else:
        changed = [b["path"] for a, b in zip(os_, ns_) if a["sha256"] != b["sha256"]]
        if changed:
            diffs.append("修改源文件: " + ", ".join(os.path.basename(p) for p in changed))

    if sorted(old.get("missing_sources", [])) != sorted(new["missing_sources"]):
        diffs.append("缺失源文件集合变化")

    a, b = entry_map(old.get("includes", [])), entry_map(new["includes"])
    paths_a, paths_b = set(a), set(b)
    if paths_a != paths_b:
        diffs.append("include 目录集合变化: "
                     f"+{sorted(paths_b - paths_a) or '-'} / -{sorted(paths_a - paths_b) or '-'}")
    else:
        chg = [p for p in paths_a if a[p]["sha256"] != b[p]["sha256"]]
        if chg:
            diffs.append("include 内容变化: " + ", ".join(os.path.basename(p) for p in chg))

    a, b = entry_map(old.get("ip_deps", [])), entry_map(new["ip_deps"])
    if set(a) != set(b):
        diffs.append("IP 依赖变化 (.hqip)")
    else:
        chg = [p for p in a if a[p]["sha256"] != b[p]["sha256"]]
        if chg:
            diffs.append("IP 内容变化: " + ", ".join(os.path.basename(p) for p in chg))

    a, b = entry_map(old.get("constraints", [])), entry_map(new["constraints"])
    if set(a) != set(b):
        diffs.append("约束文件集合变化 (SDC/UPC)")
    else:
        chg = [p for p in a if a[p]["sha256"] != b[p]["sha256"]]
        if chg:
            diffs.append("约束文件内容变化: " + ", ".join(os.path.basename(p) for p in chg))

    if old.get("device") != new["device"]:
        diffs.append("器件 (family/die/package/speed)")
    if old.get("tool") != new["tool"]:
        diffs.append("工具版本")
    if old.get("probes") != new["probes"]:
        diffs.append("探针选择")
    if old.get("storage") != new["storage"]:
        diffs.append("采样参数 (depth/windows/offset/level)")
    if old.get("ddf") != new["ddf"]:
        diffs.append(".ddf 内容")

    return (not diffs), diffs
