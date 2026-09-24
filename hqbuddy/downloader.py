"""GUI downloader: recursively scan cwd for .bin files and download via cable.exe."""

import json
import os
import queue
import re
import subprocess
import sys
import threading
import time
import tkinter as tk
from tkinter import messagebox, simpledialog, ttk
from tkinter.scrolledtext import ScrolledText

NOTES_FILE = '.hqbuddy_dl_notes.json'


def _no_window_flags():
    """CREATE_NO_WINDOW on Windows: keep cable.exe from popping a console."""
    return subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0


def spawn_gui_detached():
    """
    Launch the downloader GUI in a detached child process so the calling
    terminal is not blocked. The child re-enters hqbuddy via the internal
    -dl_gui command, which runs the GUI in-process.
    """
    if getattr(sys, 'frozen', False):
        cmd = [sys.executable, '-dl_gui']
    else:
        cmd = [sys.executable, '-m', 'hqbuddy', '-dl_gui']
    flags = 0
    if os.name == 'nt':
        flags = subprocess.DETACHED_PROCESS | subprocess.CREATE_NEW_PROCESS_GROUP
    subprocess.Popen(cmd, creationflags=flags, close_fds=True)


def _fmt_size(n):
    if n >= 1024 * 1024:
        return f"{n / 1024 / 1024:.1f} MB"
    if n >= 1024:
        return f"{n / 1024:.1f} KB"
    return f"{n} B"


class DownloaderGUI(tk.Tk):
    def __init__(self, cable_path):
        super().__init__()
        self.cable_path = cable_path
        self.root_dir = os.getcwd()
        self.notes_path = os.path.join(self.root_dir, NOTES_FILE)
        self.notes = self._load_notes()
        self.model = None
        self.downloading = False
        self.log_queue = queue.Queue()

        self.title(f"hqbuddy 下载器 - {self.root_dir}")
        self.geometry("900x560")

        top = ttk.Frame(self)
        top.pack(fill=tk.X, padx=8, pady=6)
        ttk.Button(top, text="重新扫描", command=self.rescan).pack(side=tk.LEFT)
        ttk.Button(top, text="下载选中", command=self.download_selected).pack(side=tk.LEFT, padx=6)
        ttk.Button(top, text="清空日志", command=self.clear_log).pack(side=tk.LEFT)
        ttk.Button(top, text="重置状态", command=self.reset_status).pack(side=tk.LEFT, padx=6)
        ttk.Label(top, text="双击行下载该 bin；双击备注列编辑备注").pack(side=tk.LEFT, padx=12)

        cols = ("path", "size", "mtime", "status", "note")
        self.tree = ttk.Treeview(self, columns=cols, show="tree headings")
        self.tree.heading("#0", text="目录 / 文件")
        self.tree.heading("path", text="相对路径")
        self.tree.heading("size", text="大小")
        self.tree.heading("mtime", text="修改时间")
        self.tree.heading("status", text="状态")
        self.tree.heading("note", text="备注")
        self.tree.column("#0", width=240, anchor=tk.W)
        self.tree.column("path", width=320, anchor=tk.W)
        self.tree.column("size", width=80, anchor=tk.E)
        self.tree.column("mtime", width=140, anchor=tk.CENTER)
        self.tree.column("status", width=70, anchor=tk.CENTER)
        self.tree.column("note", width=200, anchor=tk.W)
        self.tree.tag_configure("ok", foreground="green")
        self.tree.tag_configure("fail", foreground="red")
        self.tree.tag_configure("busy", foreground="orange")
        self.tree.pack(fill=tk.BOTH, expand=True, padx=8)
        self.tree.bind("<Double-1>", self._on_double_click)

        self.log = ScrolledText(self, height=12, state=tk.DISABLED)
        self.log.pack(fill=tk.BOTH, padx=8, pady=6)

        self.rescan()
        self.after(100, self._poll_log)

    # ---------- bin scan & notes ----------

    def _load_notes(self):
        try:
            with open(self.notes_path, encoding="utf-8") as f:
                data = json.load(f)
            return data if isinstance(data, dict) else {}
        except (OSError, ValueError):
            return {}

    def _save_notes(self):
        try:
            with open(self.notes_path, "w", encoding="utf-8") as f:
                json.dump(self.notes, f, ensure_ascii=False, indent=2)
        except OSError as e:
            self._log(f"[WARN] 备注保存失败: {e}")

    def rescan(self):
        self.tree.delete(*self.tree.get_children())
        groups = {}  # rel dir -> [full paths]
        for base, _dirs, files in os.walk(self.root_dir):
            for f in files:
                if f.lower().endswith('.bin'):
                    rel_dir = os.path.relpath(base, self.root_dir).replace(os.sep, '/')
                    groups.setdefault(rel_dir, []).append(os.path.join(base, f))
        n_bins = 0
        for rel_dir in sorted(groups, key=str.lower):
            files = sorted(groups[rel_dir], key=lambda p: os.path.basename(p).lower())
            n_bins += len(files)
            dir_iid = f"dir:{rel_dir}"
            self.tree.insert("", tk.END, iid=dir_iid, open=True,
                             text=f"{rel_dir} ({len(files)})",
                             values=("", "", "", "", ""))
            for full in files:
                rel = os.path.relpath(full, self.root_dir).replace(os.sep, '/')
                st = os.stat(full)
                self.tree.insert(
                    dir_iid, tk.END, iid=rel, text=os.path.basename(full),
                    values=(rel, _fmt_size(st.st_size),
                            time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(st.st_mtime)),
                            "", self.notes.get(rel, "")))
        self._log(f"[i] 扫描到 {n_bins} 个 bin 文件，分布在 {len(groups)} 个目录"
                  f"（根目录: {self.root_dir}）")

    # ---------- interaction ----------

    def _on_double_click(self, event):
        iid = self.tree.identify_row(event.y)
        if not iid:
            return
        if iid.startswith('dir:'):
            # Folder node: toggle expand/collapse only, never download.
            # "break" suppresses the class binding so it toggles exactly once
            self.tree.item(iid, open=not self.tree.item(iid, "open"))
            return "break"
        col = self.tree.identify_column(event.x)
        if col == '#5':  # note column
            old = self.notes.get(iid, "")
            new = simpledialog.askstring("备注", iid, initialvalue=old, parent=self)
            if new is not None:
                new = new.strip()
                if new:
                    self.notes[iid] = new
                else:
                    self.notes.pop(iid, None)
                self._save_notes()
                self.tree.set(iid, "note", new)
        else:
            self.start_download(iid)

    def download_selected(self):
        sel = self.tree.selection()
        if not sel:
            messagebox.showinfo("提示", "请先在列表中选中一个 bin", parent=self)
            return
        if sel[0].startswith('dir:'):
            messagebox.showinfo("提示", "选中的是文件夹节点，请选择一个 bin 文件",
                                parent=self)
            return
        self.start_download(sel[0])

    # ---------- download ----------

    def start_download(self, rel):
        if self.downloading:
            messagebox.showinfo("提示", "正在下载中，请等待当前下载完成", parent=self)
            return
        self.downloading = True
        self.tree.set(rel, "status", "下载中")
        self.tree.item(rel, tags=("busy",))
        t = threading.Thread(target=self._download_worker, args=(rel,), daemon=True)
        t.start()

    def _download_worker(self, rel):
        try:
            # Detect per download: the board may have been swapped mid-session
            self._log("[i] 探测板上型号 ...")
            r = subprocess.run([self.cable_path, '--detect_model'],
                               capture_output=True, text=True, errors='replace',
                               timeout=60, creationflags=_no_window_flags())
            m = re.search(r'Device Model\s*:\s*(\S+)', r.stdout or '')
            if not m:
                self._log("[FAIL] 未能探测到板上型号，下载中止。cable 输出：")
                self._log((r.stdout or '').strip() or '(无输出)')
                self._finish(rel, False)
                return
            self.model = m.group(1)
            self._log(f"[OK] 板上型号: {self.model}")

            bin_abs = os.path.join(self.root_dir, rel)
            cmd = [self.cable_path, '--sealion', bin_abs, '--model', self.model, '--Burst']
            self._log(f"[*] 下载 {rel} ...")
            proc = subprocess.Popen(cmd, stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT, text=True,
                                    errors='replace',
                                    creationflags=_no_window_flags())
            output = []
            for line in proc.stdout:
                output.append(line)
                self._log(line.rstrip())
            proc.wait()
            # cable.exe prints errors like "Error : The file ID is unmatched"
            # but still exits 0 — scan the output, don't trust the exit code
            has_error = any(re.match(r'\s*(error|fail)', ln, re.I) for ln in output)
            ok = proc.returncode == 0 and not has_error
            self._log(f"[{'OK' if ok else 'FAIL'}] {rel} 下载{'成功' if ok else '失败'}"
                      f" (exit {proc.returncode})")
            self._finish(rel, ok)
        except Exception as e:
            self._log(f"[FAIL] {rel}: {e}")
            self._finish(rel, False)

    def _finish(self, rel, ok):
        def apply():
            # Row may be gone if the user rescanned mid-download
            if self.tree.exists(rel):
                self.tree.set(rel, "status", "成功" if ok else "失败")
                self.tree.item(rel, tags=("ok" if ok else "fail",))
            self.downloading = False
        self.after(0, apply)

    # ---------- log ----------

    def clear_log(self):
        self.log.configure(state=tk.NORMAL)
        self.log.delete("1.0", tk.END)
        self.log.configure(state=tk.DISABLED)

    def reset_status(self):
        def walk(parent):
            for iid in self.tree.get_children(parent):
                if iid.startswith('dir:'):
                    walk(iid)
                else:
                    self.tree.set(iid, "status", "")
                    self.tree.item(iid, tags=())
        walk("")

    def _log(self, msg):
        self.log_queue.put(msg)

    def _poll_log(self):
        try:
            while True:
                msg = self.log_queue.get_nowait()
                self.log.configure(state=tk.NORMAL)
                self.log.insert(tk.END, msg + "\n")
                self.log.see(tk.END)
                self.log.configure(state=tk.DISABLED)
        except queue.Empty:
            pass
        self.after(100, self._poll_log)


def run_gui(cable_path):
    app = DownloaderGUI(cable_path)
    app.mainloop()
