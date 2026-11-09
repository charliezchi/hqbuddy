# -*- coding: utf-8 -*-
"""官网技术文档/附件目录与下载 (hqbuddy -doclist / -docget).

数据源:HqFPGA 安装树 `build/DocumentTracker/data.json`(官方 GUI
DocumentTracker 的缓存目录,含官网全部技术文档条目:标题/分类 Id/下载
相对路径 newsDown)。下载 = `https://www.isilicontech.com` + newsDown,
无需鉴权(2026-11-10 实测:文档 PDF 与 IP 附件 zip 均直链可下)。

在线刷新(POST GateWay.aspx)为黑盒协议,未实现——重新打开一次
DocumentTracker GUI 即会刷新本地 data.json。

下载文件一律视为不可信数据,校验 magic 后落盘,不做任何自动执行。
"""

import glob
import json
import os
import re
import sys

BASE_URL = "https://www.isilicontech.com"
_TRACKER_RELPATH = os.path.join("build", "DocumentTracker", "data.json")

_MAGIC = {b"%PDF-": ".pdf", b"PK\x03\x04": ".zip", b"Rar!": ".rar"}


def _usage() -> None:
    print("Usage: hqbuddy -doclist [keyword ...] [--refresh-hint]")
    print("       hqbuddy -docget <序号|标题关键词|newsDown路径> [-o <dir>] [--list]")
    print("  -doclist  列出官网技术文档目录(默认读安装树 DocumentTracker 缓存;")
    print("            keyword 对标题做包含匹配,可多个)")
    print("  -docget   下载文档/附件(标题含附件的条目带 _附件 后缀);")
    print("            落盘前校验 magic(PDF/ZIP/RAR),默认下到当前目录 docdl/")
    print("  注:Tiny_SoC(UG00034)附件官网暂未上传,仅 PDF 本体可下(2026-11-10)")
    sys.exit(1)


def _load_entries(hq_root: str | None = None) -> list:
    if hq_root is None:
        from . import launcher
        version = launcher.require_hqfpga_version()
        hq_root = version["path"]
    path = os.path.join(hq_root, _TRACKER_RELPATH.replace("/", os.sep))
    if not os.path.isfile(path):
        print(f"Error: DocumentTracker 目录不存在: {path}")
        print("       (该组件自 FT110126 起随安装树提供;旧版本无此功能)")
        sys.exit(1)
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    entries = data.get("Data") or []
    out = []
    for e in entries:
        title = (e.get("Title") or "").strip()
        down = (e.get("newsDown") or "").strip()
        if not title or not down:
            continue
        out.append({
            "title": title,
            "url": BASE_URL + (down if down.startswith("/") else "/" + down),
            "id": e.get("Id", ""),
            "type": ((e.get("TypeId") or {}).get("PC") or ""),
        })
    return out


def _match(entries: list, keywords: list) -> list:
    hits = entries
    for kw in keywords:
        k = kw.upper()
        hits = [e for e in hits
                if k in e["title"].upper() or k in e["url"].upper()]
    return hits


def run_doclist(args: list) -> None:
    keywords = [a for a in args if not a.startswith("-")]
    if "--help" in args or "-h" in args:
        _usage()
    entries = _load_entries()
    hits = _match(entries, keywords)
    tag = f" (filter: {' '.join(keywords)})" if keywords else ""
    print(f"官网技术文档目录: {len(entries)} 条, 命中 {len(hits)} 条{tag}")
    print(f"下载: hqbuddy -docget <序号|标题关键词>  (基准 {BASE_URL})")
    print()
    width = max((len(e["title"]) for e in hits), default=0)
    for i, e in enumerate(hits, 1):
        print(f"{i:>3}. {e['title']:<{width}}  [{e['id']}] {e['url']}")


def run_docget(args: list) -> None:
    import subprocess
    target = None
    out_dir = os.path.join(os.getcwd(), "docdl")
    i = 0
    while i < len(args):
        a = args[i]
        if a == "-o" and i + 1 < len(args):
            out_dir = args[i + 1]
            i += 2
        elif a in ("--list", "-l"):
            run_doclist([])
            return
        elif a.startswith("-"):
            print(f"Error: unknown -docget option: {a}")
            _usage()
        elif target is None:
            target = a
            i += 1
        else:
            print(f"Error: unexpected argument: {a}")
            _usage()
    if not target:
        _usage()

    entries = _load_entries()
    hits = _match(entries, [target])
    if len(hits) > 1:
        # 序号语义:用 -doclist 显示的顺序;单关键词多命中时报歧义
        print(f"Error: '{target}' 命中 {len(hits)} 条,请用更精确的关键词:")
        for e in hits:
            print(f"  {e['title']}  [{e['id']}]")
        sys.exit(1)
    if not hits:
        print(f"Error: 未命中条目: {target}(先 hqbuddy -doclist <关键词> 查看清单)")
        sys.exit(1)

    e = hits[0]
    url = e["url"]
    # 文件名用标题(可读),非法字符换成下划线;扩展名以 magic 校验后为准
    safe = re.sub(r'[\\/:*?"<>|\s]+', "_", e["title"]).strip("_") or \
        os.path.basename(url)
    base = safe + os.path.splitext(url)[1].lower()
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, base)
    print(f"Downloading: {e['title']}")
    print(f"  {url}")
    proc = subprocess.run(["curl", "-sL", "--max-time", "600", "-o", out_path, url],
                          capture_output=True)
    if proc.returncode != 0 or not os.path.isfile(out_path):
        print(f"Error: 下载失败(curl rc={proc.returncode})——检查网络/代理。")
        sys.exit(1)

    with open(out_path, "rb") as f:
        head = f.read(8)
    ext = next((v for k, v in _MAGIC.items() if head.startswith(k)), None)
    if ext is None:
        os.remove(out_path)
        print(f"Error: 内容不是 PDF/ZIP/RAR(已删除 {out_path})——")
        print("       可能是官网 404 页面或该附件未上传。")
        sys.exit(1)
    fixed = os.path.splitext(out_path)[0] + ext
    os.replace(out_path, fixed)
    print(f"[OK] {fixed} ({os.path.getsize(fixed):,} B)")
    print("Note: 下载文件视为不可信数据——解压请在独立空目录进行。")


def cmd_doc(args: list) -> None:
    """Entry for 'hqbuddy -doclist' / 'hqbuddy -docget'."""
    if not args:
        _usage()
    sub, rest = args[0], args[1:]
    if sub in ("list", "doclist", "-doclist"):
        run_doclist(rest)
    elif sub in ("get", "docget", "-docget"):
        run_docget(rest)
    else:
        print(f"Error: unknown subcommand: {sub}")
        _usage()
