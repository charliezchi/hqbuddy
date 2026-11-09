# -*- coding: utf-8 -*-
"""Tiny_SoC (RISC-V, SL2S-22E/SL2-25E/SL2S-25E/SL2D-25E) 嵌入式软件支持.

hqbuddy -tinysoc <sub>: 固件 BIN 切分 / IP 重生成 / 网表软件仿真 / 配置速览.

实测定音知识(2026-11-09/10 沙箱, FT110826):
- 固件 4-bank: BIN0..3 是 $readmemb 文本(每行 8 个 0/1, MSB 在前), 行数=RAM_SIZE/4;
  BIN_k = 固件每个 32 位小端字的第 k 字节 (BIN0->bits[7:0] ... BIN3->bits[31:24])
- UART0 = 0x8100_0000: Data@0x0(写触发 TX), Status@0x4(writeAvailability[23:16]),
  Divider@0x8 [19:0], Config@0xC [2:0]=DataLength 且 实际数据位=字段值+1(7=8位),
  波特率 = io_sys_clk / ((div+1) * (DL+1))
- 加密 IP 网表 vopt 解不了(P1735), 软件仿真需经 hqfpga 重综合导出明文网表
- 裸机固件三坑: SP 必须先初始化; _start 必须链接在 0xF0000000(复位向量);
  连续 putc 需轮询 writeAvailability 否则丢字
"""

import glob
import os
import re
import shutil
import subprocess
import sys
import tempfile

from . import hqip_gen
from . import ipgen
from . import launcher
from .simlib import _check_vsim

RAM_SIZES = [4096, 8192, 16384, 32768, 65536, 73728, 81920, 98304,
             131072, 262144, 524288]

IP_NAME = "Tiny_SoC"

# 外设使能 flag -> .hqip 的 USER_PORT_SEL.<cfg>
PERIPHERAL_FLAGS = {
    "--uart0": "uart0", "--uart1": "uart1",
    "--spi0": "spi0", "--spi1": "spi1",
    "--i2c0": "i2c0", "--i2c1": "i2c1",
    "--timer0": "timer0", "--timer1": "timer1",
    "--gpio": "gpio", "--plic": "plic", "--clint": "clint",
    "--usr-axi0": "usr_axi0", "--usr-axi1": "usr_axi1",
    "--apb0": "apb0", "--apb1": "apb1", "--apb2": "apb2",
    "--apb3": "apb3", "--apb4": "apb4",
    "--ddr-axi": "ddr_axi",
}


def _usage() -> None:
    print("Usage: hqbuddy -tinysoc <sub> [options]   (Tiny_SoC RISC-V 软核支持)")
    print("  new --device <part> [--ram-size N] [--uart0|--gpio|--plic|...] [--hqip <path>]")
    print("        生成 Tiny_SoC .hqip(默认配置+使能覆盖)并运行 -ipgen 生成网表")
    print("  fw <fw.bin|fw.elf> [--hqip <path>] [--ram-size N]")
    print("        固件切 4 个 BIN lane(readmemb)写回 .hqip 并重生成 IP(固化准备)")
    print("  bin <fw.bin> -o <dir> --ram-size N")
    print("        仅切分 bin_regen 等价物, 不动 .hqip")
    print("  sim --tb <tb.v> [--hqip <path>] [--time 2ms] [--bitp ns] [--work dir] [--sdf]")
    print("        导出明文网表并用 ModelSim 跑网表仿真(TB 内置 UART 帧解码)")
    print("  list [<.hqprj>]")
    print("        列出工程关联的 Tiny_SoC .hqip 及其 RAM_SIZE/BIN/外设配置")
    print("  ocd")
    print("        探测 OpenOCD 并打印在线调试(软 JTAG)接入指引")
    print("")
    print("实测定音: BIN_k=固件字第k字节(readmemb 8bit/行); UART0=0x81000000;")
    print("Config[2:0]=DataLength(实际位=值+1); 波特率=clk/((div+1)*(DL+1))")
    sys.exit(1)


def _find_tinysoc_meta() -> str:
    version = launcher.require_hqfpga_version()
    pat = os.path.join(version["path"], "build", "ipcreator", "sup_files",
                       "ipdepot", IP_NAME, IP_NAME, "*.xml")
    hits = sorted(glob.glob(pat))
    if not hits:
        print(f"Error: Tiny_SoC meta XML not found in ipdepot: {pat}")
        print("       该 IP 仅随支持 SL2S-22E/SL2-25E 系列的安装版本提供。")
        sys.exit(1)
    return hits[0]


def _find_hqip(arg: str | None) -> str:
    if arg:
        if not os.path.isfile(arg):
            print(f"Error: file not found: {arg}")
            sys.exit(1)
        return os.path.abspath(arg)
    hits = sorted(glob.glob(os.path.join("ipcore_dir", IP_NAME, f"xsIP_{IP_NAME}.hqip"))
                  + glob.glob(f"xsIP_{IP_NAME}.hqip"))
    if not hits:
        print("Error: 未找到 Tiny_SoC .hqip(先跑 hqbuddy -tinysoc new, 或用 --hqip 指定)。")
        sys.exit(1)
    return os.path.abspath(hits[0])


def _hqip_value(hqip: str, key: str) -> str | None:
    with open(hqip, "r", encoding="utf-8", errors="replace") as f:
        for ln in f:
            if ln.startswith(key + "="):
                return ln.strip()[len(key) + 1:]
    return None


def _set_hqip_values(hqip: str, updates: dict) -> None:
    with open(hqip, "r", encoding="utf-8") as f:
        lines = f.readlines()
    for key, val in updates.items():
        hit = False
        for i, ln in enumerate(lines):
            if ln.startswith(key + "="):
                lines[i] = f"{key}={val}\n"
                hit = True
                break
        if not hit:
            print(f"Error: {key} not found in {hqip}")
            sys.exit(1)
        print(f"[OK] {key}={val}")
    with open(hqip, "w", encoding="utf-8", newline="") as f:
        f.writelines(lines)


def _parse_ram_size(raw: str | None) -> int:
    if raw is None:
        print("Error: --ram-size required(合法值: %s)" % " ".join(map(str, RAM_SIZES)))
        sys.exit(1)
    try:
        n = int(raw)
    except ValueError:
        print(f"Error: bad --ram-size: {raw}")
        sys.exit(1)
    if n not in RAM_SIZES:
        print(f"Error: --ram-size {n} 不在合法档位: {RAM_SIZES}")
        sys.exit(1)
    return n


def split_fw_bin(data: bytes, ram_size: int, out_dir: str) -> list:
    """固件 bin -> 4 个 $readmemb lane 文件(BIN_k = 每个字的第 k 字节).

    行数 = RAM_SIZE/4(每行一个字节, MSB 在前), 不足补 0x00.
    """
    n_words = ram_size // 4
    if len(data) > ram_size:
        print(f"Error: 固件 {len(data)}B 超过 OnChipRAM {ram_size}B, "
              f"加大 --ram-size 或精简程序。")
        sys.exit(1)
    data = data + b"\x00" * (ram_size - len(data))
    words = [data[4 * i:4 * i + 4] for i in range(n_words)]
    os.makedirs(out_dir, exist_ok=True)
    paths = []
    for k in range(4):
        p = os.path.join(out_dir, f"fw{k}.bin")
        with open(p, "w", newline="\n") as f:
            f.write("\n".join(format(w[k], "08b") for w in words) + "\n")
        paths.append(os.path.abspath(p).replace("\\", "/"))
        print(f"[OK] {p} ({n_words} lines)")
    return paths


def _find_objcopy() -> str | None:
    from . import config as cfg_mod
    cfg = cfg_mod.load_config()
    cand = []
    tc_dir = cfg.get("riscv_gcc")
    if tc_dir:
        cand.append(os.path.join(tc_dir, "riscv-none-embed-objcopy.exe"))
        cand.append(os.path.join(tc_dir, "bin", "riscv-none-embed-objcopy.exe"))
    home = os.environ.get("USERPROFILE", "")
    cand.append(os.path.join(home, ".hqbuddy", "tools", "xpack",
                             "xpack-riscv-none-embed-gcc-10.2.0-1.2", "bin",
                             "riscv-none-embed-objcopy.exe"))
    which = shutil.which("riscv-none-embed-objcopy")
    if which:
        return which
    for c in cand:
        if c and os.path.isfile(c):
            return c
    return None


def _elf_to_bin(elf_path: str) -> str:
    objcopy = _find_objcopy()
    if not objcopy:
        print("Error: 找不到 riscv-none-embed-objcopy。")
        print("       安装 xPack riscv-none-embed-gcc 后将其 bin 目录加入 PATH,")
        print("       或用 hqbuddy -cfg 写入 riscv_gcc 指向工具链目录。")
        sys.exit(1)
    out = os.path.splitext(elf_path)[0] + ".bin"
    proc = subprocess.run([objcopy, "-O", "binary", elf_path, out],
                          capture_output=True, text=True)
    if proc.returncode != 0:
        print(f"Error: objcopy failed:\n{proc.stderr}")
        sys.exit(1)
    print(f"[OK] ELF -> bin: {out} ({os.path.getsize(out):,} B)")
    return out


def _run_ipgen_quiet(hqip: str) -> None:
    rc = ipgen.run_ipgen(hqip)
    if rc != 0:
        print(f"Error: ipgen exited with code {rc}")
        sys.exit(1)


def _cmd_new(rest: list) -> None:
    device = None
    ram_size = None
    hqip_arg = None
    sets = []
    i = 0
    while i < len(rest):
        a = rest[i]
        if a == "--device" and i + 1 < len(rest):
            device = rest[i + 1]
            i += 2
        elif a == "--ram-size" and i + 1 < len(rest):
            ram_size = rest[i + 1]
            i += 2
        elif a == "--hqip" and i + 1 < len(rest):
            hqip_arg = rest[i + 1]
            i += 2
        elif a in PERIPHERAL_FLAGS:
            sets.append(f"USER_PORT_SEL.{PERIPHERAL_FLAGS[a]}=TRUE")
            i += 1
        elif a.startswith("--set") and i + 1 < len(rest):
            sets.append(rest[i + 1])
            i += 2
        elif a.startswith("-"):
            print(f"Error: unknown -tinysoc new option: {a}")
            _usage()
        else:
            print(f"Error: unexpected argument: {a}")
            _usage()
    if not device:
        print("Error: --device required(如 SL2S-25E-8U213C; 支持 SL2S-22E/SL2-25E/"
              "SL2S-25E/SL2D-25E 系列)。")
        sys.exit(1)
    if ram_size:
        sets.append(f"INPUT_PARAMS.RAM_SIZE={_parse_ram_size(ram_size)}")

    meta = _find_tinysoc_meta()
    if hqip_arg:
        out = os.path.abspath(hqip_arg)
        os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
        hqip_gen.gen_default_hqip(meta, out, device)
        print(f"[OK] Generated: {out} (device: {device})")
        if sets:
            hqip_gen.apply_hqip_sets(out, sets)
    else:
        hqip_gen.run_gen_hqip(["--ip", IP_NAME, "-device", device]
                              + sum([["--set", s] for s in sets], []))
        out = os.path.abspath(os.path.join("ipcore_dir", IP_NAME,
                                           f"xsIP_{IP_NAME}.hqip"))

    print("")
    print(f"Running ipgen (综合生成 Tiny_SoC 网表, 约几十秒)...")
    _run_ipgen_quiet(out)
    netlist = os.path.splitext(out)[0] + ".v"
    print(f"[OK] netlist: {netlist}")
    print("Next: hqbuddy -add <netlist> <proj.hqprj> 挂进工程;"
          " 固件就绪后 hqbuddy -tinysoc fw <fw.bin|fw.elf> 更新 OnChipRAM 初值。")


def _cmd_fw(rest: list) -> None:
    src = None
    hqip_arg = None
    ram_arg = None
    i = 0
    while i < len(rest):
        a = rest[i]
        if a == "--hqip" and i + 1 < len(rest):
            hqip_arg = rest[i + 1]
            i += 2
        elif a == "--ram-size" and i + 1 < len(rest):
            ram_arg = rest[i + 1]
            i += 2
        elif a.startswith("-"):
            print(f"Error: unknown -tinysoc fw option: {a}")
            _usage()
        elif src is None:
            src = a
            i += 1
        else:
            print(f"Error: unexpected argument: {a}")
            _usage()
    if not src:
        _usage()
    if not os.path.isfile(src):
        print(f"Error: file not found: {src}")
        sys.exit(1)

    hqip = _find_hqip(hqip_arg)

    ram_size = _parse_ram_size(ram_arg) if ram_arg else \
        _parse_ram_size(_hqip_value(hqip, "INPUT_PARAMS.RAM_SIZE"))

    if src.lower().endswith(".elf"):
        src = _elf_to_bin(src)

    print(f"Firmware: {src} ({os.path.getsize(src):,} B) -> OnChipRAM {ram_size}B")
    rom_dir = os.path.join(os.path.dirname(hqip), "rom")
    lanes = split_fw_bin(open(src, "rb").read(), ram_size, rom_dir)

    _set_hqip_values(hqip, {f"INPUT_PARAMS.BIN{k}_PATH": lanes[k] for k in range(4)})

    print("")
    print("Regenerating Tiny_SoC IP (固件烧进 OnChipRAM 初值)...")
    _run_ipgen_quiet(hqip)
    print("")
    print("Next: 固化 = hqbuddy -build <proj.hqprj>(IP 网表已在工程内时全链重跑);")
    print("      软件仿真 = hqbuddy -tinysoc sim --tb <tb.v>")


def _cmd_bin(rest: list) -> None:
    src = None
    out_dir = None
    ram_arg = None
    i = 0
    while i < len(rest):
        a = rest[i]
        if a == "-o" and i + 1 < len(rest):
            out_dir = rest[i + 1]
            i += 2
        elif a == "--ram-size" and i + 1 < len(rest):
            ram_arg = rest[i + 1]
            i += 2
        elif a.startswith("-"):
            print(f"Error: unknown -tinysoc bin option: {a}")
            _usage()
        elif src is None:
            src = a
            i += 1
        else:
            print(f"Error: unexpected argument: {a}")
            _usage()
    if not src or not out_dir:
        _usage()
    if not os.path.isfile(src):
        print(f"Error: file not found: {src}")
        sys.exit(1)
    ram_size = _parse_ram_size(ram_arg)
    split_fw_bin(open(src, "rb").read(), ram_size, out_dir)


def _dv_family(device: str) -> str:
    """dv.setup 家族名(与 hqfpga 内部一致: SL2*/SA5* -> SEALION, SL3/SL7/SL8 -> SHARK)."""
    up = device.upper()
    if up.startswith(("SL3", "SL7", "SL8")):
        return "SHARK"
    return "SEALION"


def _export_plain_netlist(hqip: str, work: str, want_sdf: bool) -> tuple:
    """hqfpga 重综合加密 IP 网表 -> 明文 netlist(+SDF), 供 vopt 可仿真的仿真用."""
    module = _hqip_value(hqip, "output_module") or f"xsIP_{IP_NAME}"
    device = _hqip_value(hqip, "device")
    if not device:
        print(f"Error: no device= in {hqip}")
        sys.exit(1)
    netlist_src = os.path.splitext(hqip)[0] + ".v"
    if not os.path.isfile(netlist_src):
        print(f"Error: IP netlist not found: {netlist_src}(先跑 -tinysoc new/fw)")
        sys.exit(1)

    v_out = os.path.join(work, "sim_plain.v").replace("\\", "/")
    tcl = (f"dv.setup {_dv_family(device)} {device}\n"
           f"design.analyze {{{netlist_src}}}\n"
           f"design.rtlsyn -top {module}\n"
           f"design.tdomap -no_ioins\n"
           f"nl.write {{{v_out}}}\n")
    if want_sdf:
        tcl += f"nl.write {{{os.path.join(work, 'sim_plain.sdf').replace(chr(92), '/')}}} -sdf\n"
    tcl += 'puts "@@TS-EXPORT-DONE@@"\n'

    tf = tempfile.NamedTemporaryFile("w", suffix=".tcl", delete=False,
                                     encoding="gbk")
    tf.write(tcl)
    tf.close()
    version = launcher.require_hqfpga_version()
    try:
        proc = subprocess.run(
            [version["hqfpga_path"], "-outdir", launcher.side_log_dir(),
             "-log", "hqfpga.log", "-cmd", tf.name],
            cwd=work, capture_output=True, timeout=900)
    except subprocess.TimeoutExpired:
        print("Error: 明文网表导出超时(900s)。")
        sys.exit(1)
    finally:
        try:
            os.unlink(tf.name)
        except OSError:
            pass
    out = (proc.stdout or b"").decode("gbk", errors="replace")
    if "@@TS-EXPORT-DONE@@" not in out or not os.path.isfile(v_out):
        print(f"Error: 明文网表导出失败。尾部:\n" +
              "\n".join(out.splitlines()[-6:]))
        sys.exit(1)
    sdf = os.path.join(work, "sim_plain.sdf")
    return v_out, (sdf if want_sdf and os.path.isfile(sdf) else None)


def _tb_references_dut(tb_path: str, module: str) -> bool:
    m = re.search(r"\b" + re.escape(module) + r"\s+(\w+)\s*\(",
                  open(tb_path, encoding="utf-8", errors="replace").read())
    return bool(m)


def _cmd_sim(rest: list) -> None:
    hqip_arg = None
    tb = None
    run_time = "2ms"
    bitp = None
    work = None
    want_sdf = False
    i = 0
    while i < len(rest):
        a = rest[i]
        if a == "--hqip" and i + 1 < len(rest):
            hqip_arg = rest[i + 1]
            i += 2
        elif a == "--tb" and i + 1 < len(rest):
            tb = rest[i + 1]
            i += 2
        elif a == "--time" and i + 1 < len(rest):
            run_time = rest[i + 1]
            i += 2
        elif a == "--bitp" and i + 1 < len(rest):
            bitp = rest[i + 1]
            i += 2
        elif a == "--work" and i + 1 < len(rest):
            work = rest[i + 1]
            i += 2
        elif a == "--sdf":
            want_sdf = True
            i += 1
        elif a.startswith("-"):
            print(f"Error: unknown -tinysoc sim option: {a}")
            _usage()
        else:
            print(f"Error: unexpected argument: {a}")
            _usage()
    if not tb:
        print("Error: --tb required(TB 例化 Tiny_SoC 网表 + xsGSR/xsPWR, 模板见 skill)。")
        sys.exit(1)
    if not os.path.isfile(tb):
        print(f"Error: file not found: {tb}")
        sys.exit(1)

    hqip = _find_hqip(hqip_arg)
    module = _hqip_value(hqip, "output_module") or f"xsIP_{IP_NAME}"

    vsim_path = _check_vsim()
    if not vsim_path:
        print("Error: vsim not found in PATH(先装 ModelSim/QuestaSim; "
              "库编译用 hqbuddy -simlib)。")
        sys.exit(1)

    if not work:
        work = os.path.join(os.path.dirname(os.path.abspath(hqip)), "sim")
    work = os.path.abspath(work)
    if os.path.isdir(work):
        shutil.rmtree(work)
    os.makedirs(work, exist_ok=True)
    print(f"Sim work dir: {work}")

    print("Exporting plain netlist (vopt 无法解密加密 IP, 经 hqfpga 重综合导出)...")
    v, sdf = _export_plain_netlist(hqip, work, want_sdf)
    print(f"[OK] plain netlist: {v} ({os.path.getsize(v):,} B)")
    if sdf:
        print(f"[OK] SDF: {sdf} ({os.path.getsize(sdf):,} B)")

    tb_abs = os.path.abspath(tb)
    if not _tb_references_dut(tb_abs, module):
        print(f"Warning: TB 中未找到 {module} 例化——TB 需例化网表顶层并命名"
              f"实例 dut, 外加 xsGSR/xsPWR。")

    sdfl = ""
    if sdf:
        sdfl = f"-sdftyp /tb_tinysoc/dut={sdf.replace(os.sep, '/')} "
    gbitp = f"-gTB_BITP={bitp} " if bitp else ""
    do_lines = [
        "onerror {quit -f}",
        "vlib work",
        f"vlog +define+SIM -work work {{{v}}}",
        f"vlog +define+SIM -work work {{{tb_abs.replace(os.sep, '/')}}}",
        (f"vsim -t 1ns -L XiST_SEAL {sdfl}{gbitp}-voptargs=+acc "
         f"work.tb_tinysoc -do \"run {run_time}; quit -f\""),
    ]
    do_path = os.path.join(work, "run_tinysoc_sim.do")
    with open(do_path, "w", encoding="gbk", newline="\n") as f:
        f.write("\n".join(do_lines) + "\n")
    print(f"[OK] do file: {do_path}")

    cmd = [vsim_path, "-c", "-do", do_path]
    log_path = os.path.join(work, "tinysoc_sim.log")
    print(f"Running: {' '.join(cmd)}")
    with open(log_path, "w", encoding="utf-8", errors="replace") as logf:
        proc = subprocess.Popen(cmd, cwd=work, stdout=logf, stderr=subprocess.STDOUT)
        try:
            proc.wait(timeout=1800)
        except subprocess.TimeoutExpired:
            proc.kill()
            print("Error: vsim 超时(1800s)。")
            sys.exit(1)

    text = open(log_path, encoding="utf-8", errors="replace").read()
    errs = [ln for ln in text.splitlines() if "** Error" in ln or "Fatal" in ln]
    decoded = re.findall(r"UART RX decoded: 0x([0-9a-fA-F]{2})", text)
    chars = "".join(chr(int(h, 16)) if 32 <= int(h, 16) < 127 else f"<{h}>"
                    for h in decoded)
    print(f"[OK] sim log: {log_path} (rc={proc.returncode})")
    if errs:
        print(f"Warning: {len(errs)} error lines in log(详见日志)。")
    if chars:
        print(f"[OK] UART decoded: {chars!r}")
    else:
        print("[i] 未解出 UART 输出——检查固件波特率与 TB_BITP(缺省 2240ns="
              "50MHz+div13+8bit; 其它配置用 --bitp 指定)。")


def _cmd_list(rest: list) -> None:
    from . import ipmgr
    proj = None
    for a in rest:
        if a.endswith(".hqprj"):
            proj = a
    if proj:
        if not os.path.isfile(proj):
            print(f"Error: file not found: {proj}")
            sys.exit(1)
        hqips = ipmgr.list_ip_files(proj)
    else:
        hqips = [os.path.abspath(p) for p in
                 glob.glob(os.path.join("ipcore_dir", "**", "*.hqip"), recursive=True)]
    tiny = [h for h in hqips if IP_NAME.lower() in os.path.basename(h).lower()]
    if not tiny:
        print("No Tiny_SoC .hqip found.")
        return
    for h in tiny:
        print(f"{h}")
        for key in ("INPUT_PARAMS.RAM_SIZE", "INPUT_PARAMS.BIN0_PATH",
                    "INPUT_PARAMS.BIN1_PATH", "INPUT_PARAMS.BIN2_PATH",
                    "INPUT_PARAMS.BIN3_PATH", "device"):
            val = _hqip_value(h, key)
            if val is not None:
                print(f"  {key}={val}")
        pers = [flag for flag, cfg in PERIPHERAL_FLAGS.items()
                if (_hqip_value(h, f"USER_PORT_SEL.{cfg}") or "").upper() == "TRUE"]
        if pers:
            print(f"  peripherals: {' '.join(pers)}")


def _cmd_ocd(rest: list) -> None:
    cand = []
    home = os.environ.get("USERPROFILE", "")
    for pat in (
        os.path.join(home, ".hqbuddy", "tools", "xpack", "xpack-openocd-*",
                     "bin", "openocd.exe"),
        os.path.join(home, "AppData", "Local", "Programs", "openocd", "bin",
                     "openocd.exe"),
    ):
        cand.extend(glob.glob(pat))
    which = shutil.which("openocd")
    if which:
        cand.append(which)
    if cand:
        print(f"[OK] OpenOCD: {cand[0]}")
    else:
        print("[i] 未找到 OpenOCD。")
        print("    建议安装 xPack OpenOCD(xpack-openocd), 解压到 "
              "%USERPROFILE%\\.hqbuddy\\tools\\xpack\\ 或加入 PATH。")
    print("")
    print("Tiny_SoC 在线调试(软 JTAG, UG00034 §5.5):")
    print("  openocd -f <openocd>/scripts/interface/cmsis-dap.cfg -f debug_softTap.cfg")
    print("  GDB: riscv-none-embed-gdb fw.elf")
    print("    target extended-remote :3333")
    print("    set remotetimeout 60 / set arch riscv:rv32 / set mem inaccessible-by-default off")
    print("")
    print("Warning: debug_softTap.cfg 为厂商附件专属文件(本机暂缺), 候选配置待")
    print("         实板校准; 在此之前请用 BIN 固化 + 网表仿真链路开发。")


def cmd_tinysoc(args: list) -> None:
    """Entry for 'hqbuddy -tinysoc <sub> ...'."""
    if not args:
        _usage()
    sub, rest = args[0], args[1:]
    if sub == "new":
        _cmd_new(rest)
    elif sub == "fw":
        _cmd_fw(rest)
    elif sub == "bin":
        _cmd_bin(rest)
    elif sub == "sim":
        _cmd_sim(rest)
    elif sub == "list":
        _cmd_list(rest)
    elif sub == "ocd":
        _cmd_ocd(rest)
    else:
        print(f"Error: unknown -tinysoc subcommand: {sub}")
        _usage()
