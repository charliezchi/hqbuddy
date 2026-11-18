"""Workspace build lock, machine-global JTAG session lock, transaction logs.

Two lock scopes (P0-A7):
- build lock: one per workspace (hqins_run/.build.lock) — serializes
  instrument/implementation runs so two hqbuddy processes cannot interleave
  a rebuild with a capture;
- JTAG lock: one per cable installation (next to cable.exe's shared svf.log,
  falling back to %TEMP%) — covers every SVF play from arm through the final
  TDO read, so a concurrent GUI/hqbuddy user cannot interleave JTAG
  transactions and corrupt the shared svf.log.

Stale locks (holder pid no longer alive) are reported and reclaimed.  Every
JTAG transaction gets a session directory with the SVFs played, cable output,
svf.log copy and TDO values for reproduction.
"""

import ctypes
import glob
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time


def _pid_alive(pid: int) -> bool:
    try:
        kernel32 = ctypes.windll.kernel32
        PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
        h = kernel32.OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, pid)
        if not h:
            return False
        kernel32.CloseHandle(h)
        return True
    except Exception:
        return True  # cannot tell: be conservative, never steal


class Lock:
    def __init__(self, path: str, op: str):
        self.path = path
        self.op = op
        self.acquired = False

    def __enter__(self):
        os.makedirs(os.path.dirname(self.path), exist_ok=True)
        payload = json.dumps({"pid": os.getpid(), "op": self.op,
                              "time": time.time()}).encode()
        deadline = time.time() + 0  # single attempt; stale handled below
        while True:
            try:
                fd = os.open(self.path, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
                os.write(fd, payload)
                os.close(fd)
                self.acquired = True
                return self
            except FileExistsError:
                pass
            try:
                holder = json.load(open(self.path, "r", encoding="utf-8"))
            except (OSError, json.JSONDecodeError):
                holder = {}
            pid = holder.get("pid")
            age = time.time() - holder.get("time", 0)
            if pid and _pid_alive(pid):
                print(f"Error: {self.op} 锁被占用: {self.path}")
                print(f"       持有者 pid={pid}（{age:.0f}s 前, op={holder.get('op')}）仍存活——"
                      "等它结束或手动删除锁文件。")
                sys.exit(1)
            # dead holder or corrupt lock: reclaim
            print(f"Warning: 回收失效的 {self.op} 锁（pid={pid} 已不存在）: {self.path}")
            try:
                os.unlink(self.path)
            except OSError:
                pass
            if time.time() > deadline + 3:
                print(f"Error: {self.op} 锁无法回收: {self.path}")
                sys.exit(1)
            deadline = time.time()
            time.sleep(0.2)

    def __exit__(self, *exc):
        if self.acquired:
            try:
                os.unlink(self.path)
            except OSError:
                pass
        return False


def build_lock(proj: dict) -> Lock:
    return Lock(os.path.join(proj["hqins_dir"], ".build.lock"), "build")


def jtag_lock(version: dict) -> Lock:
    cable_dir = os.path.dirname(version.get("cable_path") or "")
    if cable_dir and os.access(cable_dir, os.W_OK):
        path = os.path.join(cable_dir, ".hqbuddy_jtag.lock")
    else:
        d = os.path.join(tempfile.gettempdir(), "hqbuddy")
        path = os.path.join(d, "jtag.lock")
    return Lock(path, "jtag")


def session_dir(proj: dict, op: str) -> str:
    """Create (or reuse) the transaction log directory for one operation."""
    base = os.path.join(proj["hqins_dir"], "hq_import", "sessions")
    ts = time.strftime("%Y%m%d_%H%M%S")
    path = os.path.join(base, f"{ts}_{op}")
    n = 1
    while os.path.isdir(path):
        n += 1
        path = os.path.join(base, f"{ts}_{op}_{n}")
    os.makedirs(path)
    return path


def _log(session: str | None, name: str, text: str) -> None:
    if not session:
        return
    try:
        with open(os.path.join(session, name), "a", encoding="utf-8",
                  errors="replace", newline="") as f:
            f.write(text.rstrip("\r\n") + "\n")
    except OSError:
        pass


def play_svf(cable_exe: str, svf_path: str, out_tdo: str = "366",
             timeout: int = 120, session: str | None = None,
             label: str = "play") -> list:
    """Play an SVF under the JTAG lock; return Received:TDO values.

    Every play is logged: cable stdout and the shared svf.log are copied into
    the session dir (when provided) so a failed transaction can be replayed
    and inspected.  A svf.log that was not refreshed by THIS play aborts the
    capture — the TDO values would be stale garbage from another process."""
    started = time.time()
    with jtag_lock({"cable_path": cable_exe}):
        log_path = os.path.join(os.path.dirname(cable_exe), "svf.log")
        _log(session, "transactions.log",
             f"=== {label} {time.strftime('%H:%M:%S')} svf={svf_path}")
        try:
            proc = subprocess.run(
                [cable_exe, "--svf", svf_path.replace(os.sep, "/"),
                 "--outTDO", out_tdo, "--debug"],
                capture_output=True, text=True, errors="replace", timeout=timeout)
        except subprocess.TimeoutExpired:
            _log(session, "transactions.log", f"TIMEOUT after {timeout}s")
            print(f"Error: cable.exe 播放 SVF 超时（{timeout}s）——JTAG 连接或板卡状态异常。")
            print(f"       会话日志: {session or '(无会话目录)'}")
            sys.exit(1)
        out = (proc.stdout or "") + (proc.stderr or "")
        _log(session, "transactions.log", f"exit={proc.returncode}")
        _log(session, "transactions.log", out)
        _log(session, "cable_output.txt", out)
        if proc.returncode != 0:
            print(f"Error: cable.exe 播放 SVF 失败（code {proc.returncode}）。")
            for ln in out.splitlines()[-15:]:
                print("  " + ln)
            sys.exit(1)
        try:
            log_mtime = os.path.getmtime(log_path)
        except OSError:
            log_mtime = 0
        if log_mtime < started - 1:
            _log(session, "transactions.log", "SVF LOG STALE")
            print(f"Error: {log_path} 未随本次播放更新——")
            print("       cable 安装目录只读，或有另一个 hqbuddy/GUI 正在并发使用 cable。")
            print("       TDO 读数不可信，中止（排查占用后重试）。")
            sys.exit(1)
        try:
            log_txt = open(log_path, "r", encoding="utf-8", errors="replace").read()
        except OSError:
            log_txt = ""
        _log(session, "svf.log", log_txt)
        values = []
        for line in log_txt.splitlines():
            line = line.strip()
            if line.startswith("Received:TDO(") and line.endswith(")"):
                values.append(line[len("Received:TDO("):-1])
        _log(session, "transactions.log", "TDO: " + " ".join(values))
        # keep a copy of the exact SVF that produced this TDO
        if session:
            try:
                dst = os.path.join(session, os.path.basename(svf_path))
                if os.path.abspath(svf_path) != os.path.abspath(dst):
                    shutil.copy2(svf_path, dst)
            except OSError:
                pass
        return values


def write_report(session: str | None, name: str, report: dict) -> None:
    """Write a JSON verification report into the session directory."""
    if not session:
        return
    try:
        with open(os.path.join(session, name), "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
    except OSError:
        pass
