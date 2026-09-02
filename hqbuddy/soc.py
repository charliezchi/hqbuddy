"""SoC (FPGA + MCU soft-core) workflow: scaffold, build, merge, download.

Presets are extracted from the official XiST SoC demo suites into
templates/soc/ (see templates/soc/extract_soc_presets.py):
  - presets/<core>/<example>/   FPGA project + MCU user code (Lib stripped)
  - lib/<core>/Lib              deduplicated CMSIS StdPeriph library
"""

import glob
import json
import os
import re
import shutil
import subprocess
import sys
import time

from . import config, launcher


def _soc_root() -> str:
    """Locate the bundled templates/soc directory."""
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    return os.path.join(base, "templates", "soc")


def refresh_hqprj_times(hqprj_abs: str) -> tuple[int, int]:
    """Rebuild FILE_TIME/FILE_TIME_CST entries to match FILE_SRC/FILE_TC/FILE_PC.

    The hqfpga GUI requires one FILE_TIME per FILE_SRC and one FILE_TIME_CST
    per constraint file; returns (src_count, cst_count).
    """
    with open(hqprj_abs, "r", encoding="utf-8") as f:
        lines = f.readlines()

    now = str(int(time.time()))
    out = []
    src_count = 0
    cst_count = 0
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("FILE_TIME_CST=") or stripped.startswith("FILE_TIME="):
            continue
        out.append(line)
        if stripped.startswith("FILE_SRC="):
            src_count += 1
            out.append(f"FILE_TIME={now}\n")
        elif stripped.startswith("FILE_TC=") and stripped != "FILE_TC=NONE":
            cst_count += 1
        elif stripped.startswith("FILE_PC=") and stripped != "FILE_PC=NONE":
            cst_count += 1
    for _ in range(cst_count):
        out.append(f"FILE_TIME_CST={now}\n")

    with open(hqprj_abs, "w", encoding="utf-8") as f:
        f.writelines(out)
    return src_count, cst_count


def _load_manifest(core: str) -> dict:
    path = os.path.join(_soc_root(), "presets", f"{core}.manifest.json")
    if not os.path.isfile(path):
        return {}
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


CORE_MODEL = {"cm3": "SA30K", "star": "SA50K"}


def cmd_list_soc(args):
    """List available SoC project presets."""
    for core in ("cm3", "star"):
        manifest = _load_manifest(core)
        if not manifest:
            print(f"{core}: (no presets found; run templates/soc/extract_soc_presets.py)")
            continue
        print(f"{core} ({CORE_MODEL[core]}):")
        for name, info in manifest.items():
            print(f"  {name:24s} device={info.get('device', '?'):26s} bin={info.get('bin', '?')}")


def cmd_new_soc(args):
    """Scaffold a full SoC project (FPGA + MCU) from a demo preset."""
    usage = "Usage: hqbuddy -new_soc <name> [-core cm3|star] [-preset <example>] [-dir <parent>]"
    if not args or args[0].startswith('-'):
        print(usage)
        sys.exit(1)
    name = args[0]
    if name.startswith('-'):
        print("Error: project name cannot start with '-'")
        sys.exit(1)

    core = "cm3"
    preset = "ex1_led_systick"
    parent = "."
    i = 1
    while i < len(args):
        if args[i] == '-core' and i + 1 < len(args):
            core = args[i + 1].lower()
            i += 2
        elif args[i] == '-preset' and i + 1 < len(args):
            preset = args[i + 1]
            i += 2
        elif args[i] == '-dir' and i + 1 < len(args):
            parent = args[i + 1]
            i += 2
        else:
            i += 1
    if core not in ("cm3", "star"):
        print(f"Error: unknown core '{core}' (choose cm3 or star)")
        sys.exit(1)

    preset_dir = os.path.join(_soc_root(), "presets", core, preset)
    if not os.path.isdir(preset_dir):
        print(f"Error: preset not found: {preset} (core: {core})")
        print("Available presets:")
        cmd_list_soc([])
        sys.exit(1)

    target = os.path.join(parent, name)
    if os.path.exists(target):
        try:
            confirm = input(f"Overwrite {target}? (y/N): ").strip().lower()
            if confirm != 'y':
                print("Cancelled.")
                return
        except (EOFError, KeyboardInterrupt):
            print("")
            print("Cancelled.")
            return
    os.makedirs(target, exist_ok=True)

    manifest = _load_manifest(core).get(preset, {})
    mcu_bin = manifest.get("bin", "")

    # 1. copy preset tree (FPGA_Prj + MCU_Prj without Lib)
    for item in sorted(os.listdir(preset_dir)):
        src = os.path.join(preset_dir, item)
        dst = os.path.join(target, item)
        if os.path.isdir(src):
            if os.path.exists(dst):
                shutil.rmtree(dst)
            shutil.copytree(src, dst)
        else:
            shutil.copyfile(src, dst)

    # 2. restore the deduplicated CMSIS library
    lib_src = os.path.join(_soc_root(), "lib", core, "Lib")
    shutil.copytree(lib_src, os.path.join(target, "MCU_Prj", "Lib"), dirs_exist_ok=True)

    # 3. rename + rewrite the .hqprj
    hqprj = os.path.join(target, "FPGA_Prj", "hq_prj", "hq_prj.hqprj")
    new_hqprj = os.path.join(target, "FPGA_Prj", "hq_prj", f"{name}.hqprj")
    if os.path.isfile(hqprj):
        with open(hqprj, "r", encoding="utf-8") as f:
            content = f.read()
        content = content.replace("PROJ_NAME=hq_prj", f"PROJ_NAME={name}")
        with open(hqprj, "w", encoding="utf-8") as f:
            f.write(content)
        os.replace(hqprj, new_hqprj)

    # 4. make timestamp entries consistent (GUI opens requirement)
    refresh_hqprj_times(new_hqprj)

    # 5. replace the demo merge bat (hardcoded tool paths) with a hqbuddy one.
    #    The Keil project runs this automatically after every build; pass -dl
    #    to also download, e.g.: mergeBinFileAndProgram.bat -dl
    #    Note: -build writes the FPGA bin next to the .hqprj (not hq_run).
    model = CORE_MODEL[core]
    bat = os.path.join(target, "MCU_Prj", "MDK", "mergeBinFileAndProgram.bat")
    bat_content = f"""@echo off
rem Generated by hqbuddy -new_soc; resolves tools via hqbuddy, no hardcoded paths.
rem Run with -dl to download the merged image to the board after merging.
rem FPGA bin: hqbuddy -build writes {name}.bin next to the .hqprj.
cd /d "%~dp0..\\.."
hqbuddy -merge_bin "FPGA_Prj\\hq_prj\\{name}.bin" "MCU_Prj\\MDK\\{mcu_bin}" -o "FPGA_Prj\\hq_prj\\{name}_merged.bin" -model {model} %~1
"""
    with open(bat, "w", encoding="utf-8") as f:
        f.write(bat_content)

    print(f"Project created: {target} (core: {core}, preset: {preset})")
    print("")
    print("Next steps (run inside FPGA_Prj/hq_prj for FPGA commands):")
    print(f"  cd {os.path.join(name, 'FPGA_Prj', 'hq_prj')}")
    print(f"  hqbuddy -build                    # full FPGA flow -> {name}.bin")
    print(f"  hqbuddy -mcu_build                # Keil headless build (auto-merges bins)")
    print(f"  hqbuddy -dl -f ..\\..\\FPGA_Prj\\hq_prj\\{name}_merged.bin")
    print("  (merge only, no download: MCU_Prj\\MDK\\mergeBinFileAndProgram.bat)")


def cmd_merge_bin(args):
    """Merge an FPGA bin and an MCU bin into one download image (cable.exe)."""
    usage = ("Usage: hqbuddy -merge_bin <fpga.bin> <mcu.bin> [-o <merged.bin>] "
             "[-model SA30K|SA50K] [-remap 000] [-dl]")
    pos = []
    out_path = None
    model = "SA30K"
    remap = "000"
    download = False
    i = 0
    while i < len(args):
        a = args[i]
        if a == '-o' and i + 1 < len(args):
            out_path = args[i + 1]
            i += 2
        elif a == '-model' and i + 1 < len(args):
            model = args[i + 1]
            i += 2
        elif a == '-remap' and i + 1 < len(args):
            remap = args[i + 1]
            i += 2
        elif a == '-dl':
            download = True
            i += 1
        else:
            pos.append(a)
            i += 1
    if len(pos) < 2:
        print(usage)
        sys.exit(1)
    fpga_bin, mcu_bin = pos[0], pos[1]
    for p in (fpga_bin, mcu_bin):
        if not os.path.isfile(p):
            print(f"Error: file not found: {p}")
            sys.exit(1)

    version = launcher.resolve_hqfpga_version()
    if not version:
        print("Error: no HqFPGA versions found.")
        sys.exit(1)
    cable = version.get('cable_path')
    if not cable or not os.path.isfile(cable):
        print("Error: cable.exe not found in this HqFpga installation.")
        sys.exit(1)

    fpga_abs = os.path.abspath(fpga_bin)
    mcu_abs = os.path.abspath(mcu_bin)

    cmd = [cable, '--merge', fpga_abs, '--cm3file', mcu_abs, '--remap', remap]
    print(f"Merge: {os.path.basename(fpga_abs)} + {os.path.basename(mcu_abs)}")
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                          text=True, errors='replace')
    print(proc.stdout)
    if proc.returncode != 0:
        print(f"Error: cable.exe merge failed (exit {proc.returncode})")
        sys.exit(1)

    m = re.search(r"output bin file:\s*(.+)", proc.stdout or "")
    if not m:
        print("Error: merge output file not reported by cable.exe")
        sys.exit(1)
    merged = m.group(1).strip()

    if out_path:
        out_abs = os.path.abspath(out_path)
        if os.path.abspath(merged) != out_abs:
            os.replace(merged, out_abs)
            merged = out_abs
    print(f"Merged image: {merged}")

    if download:
        print(f"Downloading with model {model} ...")
        dcmd = [cable, '--sealion', merged, '--model', model, '--Burst']
        proc = subprocess.run(dcmd)
        if proc.returncode != 0:
            print(f"Error: download failed (exit {proc.returncode})")
            sys.exit(1)


def _find_uv4() -> str | None:
    """Locate Keil uVision UV4.exe: config key 'keil_uv4', then common paths."""
    p = config.load_config().get("keil_uv4")
    if p and os.path.isfile(p):
        return p
    drive_candidates = []
    for drive in "CDEFGH":
        drive_candidates += [
            fr"{drive}:\Keil_v5\UV4\UV4.exe",
            fr"{drive}:\Keil\UV4\UV4.exe",
        ]
    drive_candidates += glob.glob(r"*\Keil*\UV4\UV4.exe")
    for c in drive_candidates:
        if os.path.isfile(c):
            return c
    return None


def cmd_mcu_build(args):
    """Build MCU_Prj firmware with Keil uVision in command-line mode."""
    projxs = []
    i = 0
    while i < len(args):
        if args[i] == '-p' and i + 1 < len(args):
            projxs.append(args[i + 1])
            i += 2
        else:
            projxs.append(args[i])
            i += 1
    if not projxs:
        projxs = sorted(glob.glob(os.path.join("MCU_Prj*", "MDK", "*.uvprojx")))
    if not projxs:
        print("Error: no .uvprojx given and none found under MCU_Prj*/MDK/.")
        print("Usage: hqbuddy -mcu_build [-p <file.uvprojx>]")
        sys.exit(1)

    uv4 = _find_uv4()
    if not uv4:
        print("Error: Keil UV4.exe not found.")
        print("Fix: add \"keil_uv4\": \"C:\\\\Keil_v5\\\\UV4\\\\UV4.exe\" to the hqbuddy config")
        print("     (hqbuddy -cfg), or install Keil MDK to C:\\Keil_v5.")
        sys.exit(1)

    failed = 0
    for proj in projxs:
        proj_abs = os.path.abspath(proj)
        if not os.path.isfile(proj_abs):
            print(f"Error: file not found: {proj}")
            failed += 1
            continue
        mdk_dir = os.path.dirname(proj_abs)
        log_path = os.path.join(mdk_dir, "build_log.txt")
        print(f"Building: {os.path.basename(proj)} (UV4: {uv4})")
        # UV4 -b: batch build; -j0: no GUI; -o: build log
        proc = subprocess.run([uv4, '-b', proj_abs, '-j0', '-o', log_path])
        if os.path.isfile(log_path):
            with open(log_path, "r", encoding="utf-8", errors="replace") as f:
                print(f.read())
        if proc.returncode >= 2:
            print(f"[FAIL] {os.path.basename(proj)} (UV4 exit {proc.returncode})")
            failed += 1
        else:
            bins = sorted(
                (os.path.join(mdk_dir, f) for f in os.listdir(mdk_dir)
                 if f.lower().endswith('.bin')),
                key=os.path.getmtime, reverse=True)
            for b in bins[:1]:
                print(f"[BIN] {b}")
    if failed:
        sys.exit(1)
