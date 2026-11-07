# -*- coding: utf-8 -*-
"""hqbuddy -serv: single-invocation resident hqfpga session.

Spawns hqfpga.exe -guisrv (eval server), opens its ONE TCP connection, and
runs commands from the SAME process — either interactively (REPL) or as a
batch script.  Verified reliable on FT110126: one connection lives for many
commands with persistent state and healthy error recovery.

Known limit (FT110126): the eval server accepts exactly one connection per
lifetime and the link cannot be shared across processes — so there is no
cross-invocation daemon.  Non-ASCII over the TCP channel hangs the server;
batch files (read by hqfpga in ANSI) are the way to pass Chinese content.
"""
import os
import re
import socket
import subprocess
import sys
import time

from . import launcher


def _spawn_session(cwd: str | None = None) -> tuple:
    """Start hqfpga -guisrv, open the single connection.  Returns
    (proc, sock, port).  The caller must keep proc/sock alive for the whole
    session and kill/close at the end."""
    version = launcher.require_hqfpga_version()
    logs_dir = launcher.side_log_dir()
    hq = subprocess.Popen(
        [version["hqfpga_path"], "-guisrv", "1", "-outdir", logs_dir,
         "-log", "guisrv.log"],
        cwd=cwd or logs_dir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

    port = None

    def reader():
        nonlocal port
        for raw in hq.stdout:
            line = raw.decode("gbk", errors="replace")
            if port is None:
                m = re.search(r"Server Port\s+(\d+)", line)
                if m:
                    port = int(m.group(1))
            # drain everything else (a full stdout pipe stalls the engine)

    import threading
    th = threading.Thread(target=reader, daemon=True)
    th.start()
    t0 = time.time()
    while port is None and time.time() - t0 < 15:
        time.sleep(0.1)
    if port is None:
        hq.kill()
        print("Error: 未在 15s 内等到 Server Port（hqfpga 启动失败?）。")
        sys.exit(1)
    sock = socket.create_connection(("127.0.0.1", port), timeout=10)
    sock.settimeout(None)
    return hq, sock, port


def _exchange(sock, command: str, timeout: float = 600) -> tuple[str, bool]:
    """One command over the session; returns (output, ok).  ASCII only —
    non-ASCII hangs the server (FT110126); use batch files for Chinese."""
    sock.settimeout(timeout)
    sock.sendall(command.encode("ascii", errors="replace") + b"\n")
    data = b""
    while b"@@Ucmd_Done" not in data and b"@@Ucmd_Error" not in data:
        chunk = sock.recv(65536)
        if not chunk:
            raise ConnectionError("eval server closed the connection")
        data += chunk
    text = data.decode("gbk", errors="replace").strip("\r\n")
    return text, "@@Ucmd_Done" in text



def run_batch(args: list) -> None:
    """hqbuddy -serv -f <file.tcl> [-cwd <dir>]: run a TCL script in one
    resident session (source, so multi-line constructs are fine)."""
    if not args or not os.path.isfile(args[0]):
        print("Usage: hqbuddy -serv -f <file.tcl> [-cwd <dir>]")
        sys.exit(1)
    f_tcl = os.path.abspath(args[0]).replace("\\", "/")
    cwd = None
    if len(args) >= 3 and args[1] == "-cwd":
        cwd = os.path.abspath(args[2])
    hq, sock, port = _spawn_session(cwd)
    print(f"[session] pid={hq.pid} port={port}")
    try:
        out, ok = _exchange(sock, f"source {{{f_tcl}}}", timeout=3600)
        print(out)
    finally:
        try:
            sock.close()
        except OSError:
            pass
        hq.kill()
    if not ok:
        sys.exit(1)


def run_repl(args: list) -> None:
    """hqbuddy -serv: interactive session (stdin loop, Ctrl-C/D to exit)."""
    hq, sock, port = _spawn_session(None)
    print(f"[session] pid={hq.pid} port={port} — TCL 逐行执行，exit/Ctrl-C 退出")
    buf = ""
    try:
        while True:
            try:
                line = input("serv> ").strip()
            except EOFError:
                break
            if not line:
                continue
            if line in ("exit", "quit"):
                break
            buf += line + "\n"
            # forward complete commands (brace/quote balance is TCL's job;
            # a line that errors mid-construction reports via @@Ucmd_Error)
            try:
                out, ok = _exchange(sock, buf)
            except ConnectionError as e:
                print(f"Error: {e}")
                break
            print(out)
            buf = ""
    except KeyboardInterrupt:
        pass
    finally:
        try:
            sock.close()
        except OSError:
            pass
        hq.kill()


def run_serv(args: list) -> None:
    if args and args[0] == "-f":
        run_batch(args[1:])
        return
    if not args:
        run_repl([])
        return
    print("Usage: hqbuddy -serv [交互 REPL]  |  hqbuddy -serv -f <file.tcl> [-cwd <dir>]")
    print("       单次调用常驻会话（eval server 单连接生命周期，跨进程常驻不可行——FT110126 实测）。")
    sys.exit(1)
