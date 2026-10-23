#!/usr/bin/env python3
"""导出 hqbuddy 离线分发压缩包（给无法访问 GitHub 的用户）。

Usage:
    python export.py                 # 打包现有 hqbuddy.exe（缺失或落后于源码时自动重建）
    python export.py -o <dir>        # 指定输出目录（默认仓库根目录）
    python export.py --build         # 强制先重建 hqbuddy.exe
    python export.py --no-build      # 只打包现有 exe，缺失/落后也不重建（直接报错）

产出 hqbuddy_v<版本>_win64.zip，解压后是一个 hqbuddy_v<版本>/ 目录：
    hqbuddy.exe         主程序（PyInstaller 单文件，双击/命令行直接用）
    hqbuddy/            Python 源码包（有 Python 3.10+ 时可 python -m hqbuddy 运行）
    templates/          工程模板（从源码运行时 -new_prj 等需要）
    README.md           使用说明
    LICENSE             许可证
    install_skill.py    hqfpga skill 安装脚本（可选，需 Python）
    skills/hqfpga/      AI Agent skill 文件（配合 install_skill.py）
"""

import glob
import os
import re
import shutil
import subprocess
import sys
import zipfile

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PKG_DIR = os.path.join(SCRIPT_DIR, "hqbuddy")
EXE = os.path.join(SCRIPT_DIR, "hqbuddy.exe")

BUNDLED = [
    ("README.md", "README.md"),
    ("LICENSE", "LICENSE"),
    ("install_skill.py", "install_skill.py"),
]


def get_version() -> str:
    m = re.search(r'__version__\s*=\s*"([^"]+)"',
                  open(os.path.join(PKG_DIR, "__init__.py"), encoding="utf-8").read())
    if not m:
        print("[FAIL] 无法从 hqbuddy/__init__.py 读取版本号")
        sys.exit(1)
    return m.group(1)


def exe_is_stale() -> bool:
    """hqbuddy.exe 比任一源码/模板旧则为 True。"""
    if not os.path.exists(EXE):
        return True
    exe_mt = os.path.getmtime(EXE)
    for pattern in ("hqbuddy/*.py", "templates/*", "templates/**/*"):
        for src in glob.glob(os.path.join(SCRIPT_DIR, pattern)):
            if os.path.isfile(src) and os.path.getmtime(src) > exe_mt:
                return True
    return False


def rebuild():
    print("重建 hqbuddy.exe（python build.py）...\n")
    r = subprocess.run([sys.executable, os.path.join(SCRIPT_DIR, "build.py")],
                       cwd=SCRIPT_DIR)
    if r.returncode != 0 or not os.path.exists(EXE):
        print("\n[FAIL] hqbuddy.exe 构建失败。")
        sys.exit(1)
    print()


def iter_tree(subdir: str):
    """遍历仓库下某个子目录，跳过 __pycache__ 与字节码文件。"""
    root = os.path.join(SCRIPT_DIR, subdir)
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d != "__pycache__"]
        for name in filenames:
            if name.endswith((".pyc", ".pyo")):
                continue
            full = os.path.join(dirpath, name)
            rel = os.path.relpath(full, SCRIPT_DIR)
            yield full, rel


def main():
    out_dir = SCRIPT_DIR
    force_build = no_build = False
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] in ("-o", "--out"):
            if i + 1 >= len(args):
                print("[FAIL] -o 需要一个输出目录参数")
                sys.exit(1)
            out_dir = args[i + 1]
            i += 2
        elif args[i] == "--build":
            force_build = True
            i += 1
        elif args[i] == "--no-build":
            no_build = True
            i += 1
        else:
            print(f"[FAIL] 未知参数: {args[i]}（支持 -o <dir> / --build / --no-build）")
            sys.exit(1)

    version = get_version()

    if force_build or (exe_is_stale() and not no_build):
        rebuild()
    elif not os.path.exists(EXE):
        print("[FAIL] 仓库内没有 hqbuddy.exe，且指定了 --no-build。")
        print("       去掉 --no-build 或先运行 python build.py。")
        sys.exit(1)
    else:
        print("使用现有 hqbuddy.exe（已是最新）。")

    zip_name = f"hqbuddy_v{version}_win64.zip"
    zip_path = os.path.join(out_dir, zip_name)
    top = f"hqbuddy_v{version}"
    os.makedirs(out_dir, exist_ok=True)

    print(f"\n生成 {zip_path} ...")
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        z.write(EXE, f"{top}/hqbuddy.exe")
        for src, arc in BUNDLED:
            full = os.path.join(SCRIPT_DIR, src)
            if os.path.isfile(full):
                z.write(full, f"{top}/{arc}")
        for subdir in ("hqbuddy", "templates", os.path.join("skills", "hqfpga")):
            for full, rel in iter_tree(subdir):
                z.write(full, f"{top}/{rel.replace(os.sep, '/')}")

    n_files = len(zipfile.ZipFile(zip_path).namelist())
    size_mb = os.path.getsize(zip_path) / 1024 / 1024
    print(f"[OK] 导出完成: {zip_path}")
    print(f"     {n_files} 个文件, {size_mb:.1f} MB")
    print(f"     内容: hqbuddy.exe / hqbuddy/ 源码 / templates/ / README.md / "
          f"LICENSE / install_skill.py / skills/hqfpga/")
    print("     用户解压后可直接运行 hqbuddy.exe；如需 AI skill，运行 "
          "python install_skill.py（需 Python）。")


if __name__ == "__main__":
    main()
