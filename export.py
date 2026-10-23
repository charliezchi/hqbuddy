#!/usr/bin/env python3
"""导出 hqbuddy 离线分发源码包（给无法访问 GitHub 的用户）。

Usage:
    python export.py                 # 打包到仓库根目录
    python export.py -o <dir>        # 指定输出目录

产出 hqbuddy_v<版本>_src.zip，解压后是一个 hqbuddy_v<版本>/ 目录：
    build.py            一键构建脚本（收件人运行 python build.py 自行出 exe）
    hqbuddy/            Python 源码包（需 Python 3.10+）
    templates/          工程模板（-new_prj / -new_soc 等所需，已内嵌进 exe）
    skills/hqfpga/      AI Agent skill 文件
    install_skill.py    skill 安装脚本
    README.md           使用说明
    LICENSE             许可证

注意：包内不含 hqbuddy.exe——收件人在解压目录运行 `python build.py`
（会自动安装 PyInstaller 并构建 hqbuddy.exe、注册到 PATH）。
"""

import os
import re
import shutil
import sys
import zipfile

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PKG_DIR = os.path.join(SCRIPT_DIR, "hqbuddy")

BUNDLED = [
    ("build.py", "build.py"),
    ("README.md", "README.md"),
    ("LICENSE", "LICENSE"),
    ("install_skill.py", "install_skill.py"),
]

TREES = ["hqbuddy", "templates", os.path.join("skills", "hqfpga")]


def get_version() -> str:
    m = re.search(r'__version__\s*=\s*"([^"]+)"',
                  open(os.path.join(PKG_DIR, "__init__.py"), encoding="utf-8").read())
    if not m:
        print("[FAIL] 无法从 hqbuddy/__init__.py 读取版本号")
        sys.exit(1)
    return m.group(1)


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
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] in ("-o", "--out"):
            if i + 1 >= len(args):
                print("[FAIL] -o 需要一个输出目录参数")
                sys.exit(1)
            out_dir = args[i + 1]
            i += 2
        else:
            print(f"[FAIL] 未知参数: {args[i]}（支持 -o <dir>）")
            sys.exit(1)

    version = get_version()
    zip_name = f"hqbuddy_v{version}_src.zip"
    zip_path = os.path.join(out_dir, zip_name)
    top = f"hqbuddy_v{version}"
    os.makedirs(out_dir, exist_ok=True)

    print(f"生成 {zip_path} ...")
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        for src, arc in BUNDLED:
            full = os.path.join(SCRIPT_DIR, src)
            if not os.path.isfile(full):
                print(f"[FAIL] 缺少文件: {full}")
                sys.exit(1)
            z.write(full, f"{top}/{arc}")
        for subdir in TREES:
            for full, rel in iter_tree(subdir):
                z.write(full, f"{top}/{rel.replace(os.sep, '/')}")

    n_files = len(zipfile.ZipFile(zip_path).namelist())
    size_mb = os.path.getsize(zip_path) / 1024 / 1024
    print(f"[OK] 导出完成: {zip_path}")
    print(f"     {n_files} 个文件, {size_mb:.1f} MB")
    print(f"     内容: build.py / hqbuddy/ 源码 / templates/ / README.md / "
          f"LICENSE / install_skill.py / skills/hqfpga/")
    print("     收件人解压后在目录内运行 python build.py 自行构建 "
          "hqbuddy.exe（需 Python 3.10+，PyInstaller 会自动安装）。")


if __name__ == "__main__":
    main()
