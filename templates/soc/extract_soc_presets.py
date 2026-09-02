#!/usr/bin/env python3
"""Extract SoC presets from the official XiST demo suites into templates/soc/.

One-time (re-runnable) asset pipeline:
  - templates/soc/presets/<core>/<example>/   FPGA project + MCU user/MDK (Lib stripped)
  - templates/soc/lib/<core>/Lib              deduplicated CMSIS StdPeriph library

Heavyweight examples (lwip/mqtt/FreeRTOS/bootloader/DDR/CAN/eclipse) are skipped:
they stay usable via manual copy from the demo dirs.

Usage:
    python templates/soc/extract_soc_presets.py [--cm3-root DIR] [--star-root DIR]
"""

import argparse
import json
import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = HERE

DEFAULT_ROOTS = {
    "cm3": r"C:\Users\XiST\Desktop\XIST_CM3_Demo_2026_0805",
    "star": r"C:\Users\XiST\Desktop\XIST_STAR_Demo_2026_0805",
}

# Skip examples that are huge or non-MDK (documented in soc.md reference instead)
SKIP_EXAMPLES = {
    "ex20_ddr_as_ram", "ex21_bootloader", "ex22_lwip", "ex22_can",
    "ex23_FreeRTOS", "ex24_FreeRTOS", "ex24_eclipse", "ex25_mqtt",
    "ex26_AHB2DDRC_Cahce",
}

SKIP_DIR_NAMES = {"hq_run", "Objects", "Listings", "Lib"}
SKIP_FILE_SUFFIXES = (".bak", ".uvguix", ".bin")
SKIP_FILE_NAMES = {"hqprjUI.json", "JLinkLog.txt", ".hqip.bak"}


def _skip_file(name: str) -> bool:
    if name in SKIP_FILE_NAMES:
        return True
    if name.endswith(SKIP_FILE_SUFFIXES):
        return True
    # *.uvguix.<user>
    if ".uvguix." in name:
        return True
    return False


def copy_tree_filtered(src: str, dst: str) -> int:
    """Copy src -> dst skipping build outputs and GUI state. Returns file count."""
    n = 0
    for dp, dns, fns in os.walk(src):
        dns[:] = [d for d in dns if d not in SKIP_DIR_NAMES]
        rel = os.path.relpath(dp, src)
        out_dp = os.path.join(dst, rel) if rel != "." else dst
        os.makedirs(out_dp, exist_ok=True)
        for f in fns:
            if _skip_file(f):
                continue
            shutil.copyfile(os.path.join(dp, f), os.path.join(out_dp, f))
            n += 1
    return n


def hqprj_device(path: str) -> str:
    """Compose the hqbuddy device part (DIE-SPEED-PACKAGE-CONDITION) from .hqprj."""
    kv = {}
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            if "=" in line:
                k, v = line.strip().split("=", 1)
                kv[k] = v
    return f"{kv.get('DIE','')}-{kv.get('SPEEDS','')}{kv.get('PACKAGES','')}-{kv.get('CONDITION','')}"


def mdk_bin_name(preset_dir: str) -> str:
    """Pull the AfterMake bin output name from the preset's .uvprojx."""
    import re
    mdk = os.path.join(preset_dir, "MCU_Prj", "MDK")
    if not os.path.isdir(mdk):
        return ""
    for f in os.listdir(mdk):
        if f.endswith(".uvprojx"):
            with open(os.path.join(mdk, f), "r", encoding="utf-8", errors="replace") as fh:
                m = re.search(r"fromelf\.exe[^<]*--bin\s+-o\s+(\S+?\.bin)", fh.read())
            if m:
                return os.path.basename(m.group(1))
    return ""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cm3-root", default=DEFAULT_ROOTS["cm3"])
    ap.add_argument("--star-root", default=DEFAULT_ROOTS["star"])
    args = ap.parse_args()

    cores = {"cm3": args.cm3_root, "star": args.star_root}
    for core, root in cores.items():
        if not os.path.isdir(root):
            print(f"[WARN] demo root not found, skipping {core}: {root}")
            continue

        # 1. deduplicated CMSIS library (byte-identical across examples, take ex1)
        lib_src = os.path.join(root, "ex1_led_systick", "MCU_Prj", "Lib")
        lib_dst = os.path.join(OUT, "lib", core, "Lib")
        if os.path.isdir(lib_src):
            if os.path.isdir(lib_dst):
                shutil.rmtree(lib_dst)
            n = copy_tree_filtered(lib_src, lib_dst)
            print(f"[{core}] Lib: {n} files -> {os.path.relpath(lib_dst, OUT)}")

        # 2. presets
        presets = {}
        for ex in sorted(os.listdir(root)):
            ex_dir = os.path.join(root, ex)
            if ex in SKIP_EXAMPLES or not ex.startswith("ex") or not os.path.isdir(ex_dir):
                continue
            fpga = os.path.join(ex_dir, "FPGA_Prj", "hq_prj")
            if not os.path.isdir(fpga):
                continue
            preset_dir = os.path.join(OUT, "presets", core, ex)
            if os.path.isdir(preset_dir):
                shutil.rmtree(preset_dir)
            os.makedirs(preset_dir)

            nf = copy_tree_filtered(fpga, os.path.join(preset_dir, "FPGA_Prj", "hq_prj"))
            # MCU_Prj dirs (single-project examples): everything except Lib
            nm = 0
            for d in sorted(os.listdir(ex_dir)):
                if d.startswith("MCU_Prj"):
                    nm += copy_tree_filtered(
                        os.path.join(ex_dir, d),
                        os.path.join(preset_dir, d))
            hqprj = os.path.join(preset_dir, "FPGA_Prj", "hq_prj", "hq_prj.hqprj")
            presets[ex] = {
                "core": core,
                "preset": ex,
                "device": hqprj_device(hqprj) if os.path.isfile(hqprj) else "",
                "bin": mdk_bin_name(preset_dir),
            }
            print(f"[{core}] {ex}: {nf} fpga + {nm} mcu files")

        with open(os.path.join(OUT, "presets", f"{core}.manifest.json"), "w", encoding="utf-8") as f:
            json.dump(presets, f, indent=2, ensure_ascii=False)

    print("\nDone.")


if __name__ == "__main__":
    sys.exit(main())
