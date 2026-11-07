# -*- coding: utf-8 -*-
"""Resident hqfpga session broker (hqbuddy -serv).

The vendor eval server (hqfpga.exe -guisrv) accepts exactly ONE TCP
connection per lifetime and exits when it closes (FT110126 verified) — so a
per-command connect is impossible.  hqbuddy therefore runs a detached broker
daemon that holds the single hqfpga connection and multiplexes client
commands over a second localhost control port:

  hqbuddy -serv start          spawn the detached daemon (state in %TEMP%/hqbuddy/serv.json)
  hqbuddy -serv -e "<tcl>"     run one command through the resident session
  hqbuddy -serv status         daemon/hqfpga pid, port, uptime
  hqbuddy -serv stop           stop daemon + hqfpga child

Control protocol (daemon): one line = one TCL command; response is the hqfpga
payload terminated by @@SERV_OK / @@SERV_ERR.
"""
import json
import os
import re
import socket
import subprocess
import sys
import time

from . import launcher

_STATE = os.path.join(os.environ.get("TEMP", os.getcwd()), "hqbuddy", "serv.json")


def _state_path() -> str:
    os.makedirs(os.path.dirname(_STATE), exist_ok=True)
    return _STATE


def _load_state() -> dict | None:
    try:
        return json.load(open(_state_path(), encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return None


def _save_state(st: dict) -> None:
    with open(_state_path(), "w", encoding="utf-8") as f:
        json.dump(st, f, indent=1)


def _alive(pid: int) -> bool:
    try:
        out = subprocess.run(["tasklist", "/FI", f"PID eq {pid}"],
                             capture_output=True, text=True).stdout
        return str(pid) in out
    except Exception:
        return False


def _wait_hqfpga_port(boot_log: str, proc, timeout: float = 15) -> int:
    t0 = time.time()
    while time.time() - t0 < timeout:
        time.sleep(0.2)
        m = re.search(r"Server Port\s+(\d+)",
                      open(boot_log, encoding="utf-8",
                           errors="replace").read())
        if m:
            return int(m.group(1))
    raise SystemExit(f"Error: 未在 {timeout:.0f}s 内等到 Server Port。启动输出：\n" +
                     open(boot_log, encoding="utf-8",
                          errors="replace").read()[-500:])


def _daemon_main() -> None:
    """Detached broker: hold the single hqfpga connection, serve clients."""
    logs_dir = launcher.side_log_dir()
    boot_log = os.path.join(logs_dir, "guisrv_boot.log")
    version = launcher.require_hqfpga_version()

    def _start_hq() -> tuple:
        """(re)start hqfpga -guisrv and open the single connection."""
        boot_fp = open(boot_log, "w", encoding="utf-8", errors="replace")
        hq = subprocess.Popen(
            [version["hqfpga_path"], "-guisrv", "1", "-outdir", logs_dir,
             "-log", "guisrv.log"],
            cwd=logs_dir, stdout=boot_fp, stderr=subprocess.STDOUT)
        hq_port = _wait_hqfpga_port(boot_log, hq)
        boot_fp.close()
        sock = socket.create_connection(("127.0.0.1", hq_port), timeout=10)
        sock.settimeout(None)
        prev = _load_state() or {}
        _save_state({"daemon_pid": os.getpid(), "hqfpga_pid": hq.pid,
                     "port": hq_port, "ctrl_port": prev.get("ctrl_port"),
                     "started": prev.get("started", time.time())})
        return hq, sock

    hq, hq_sock = _start_hq()

    ctrl = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    ctrl.bind(("127.0.0.1", 0))
    ctrl.listen(4)
    ctrl_port = ctrl.getsockname()[1]
    st = _load_state() or {}
    st["ctrl_port"] = ctrl_port
    _save_state(st)
    print(f"daemon ready: pid={os.getpid()} hqfpga={hq.pid} "
          f"port={st['port']} ctrl={ctrl_port}", flush=True)

    def forward(command: str) -> tuple[str, bool]:
        hq_sock.sendall((command + "\n").encode())
        data = b""
        while b"@@Ucmd_Done" not in data and b"@@Ucmd_Error" not in data:
            chunk = hq_sock.recv(65536)
            if not chunk:
                raise ConnectionError("hqfpga connection closed")
            data += chunk
        text = data.decode("gbk", errors="replace")
        return text.strip("\r\n"), "@@Ucmd_Done" in text

    def forward_selfheal(command: str) -> tuple[str, bool]:
        nonlocal hq, hq_sock
        try:
            return forward(command)
        except (ConnectionError, OSError):
            # a crashing command (e.g. eco.route on an empty design) kills the
            # hqfpga link — rebuild the session but do NOT retry the same
            # command: deterministic crashers would loop forever
            try:
                hq.kill()
            except OSError:
                pass
            hq, hq_sock = _start_hq()
            return (f"[session rebuilt] 命令未重试——它杀死了上一个会话"
                    f"（常见于对无设计会话跑 eco.route 等），请修正后重发。", False)


    while True:
        conn, _addr = ctrl.accept()
        try:
            conn.settimeout(1800)
            fconn = conn.makefile("r", encoding="utf-8", errors="replace")
            for line in fconn:
                cmd = line.strip()
                if not cmd:
                    continue
                if cmd == "exit":
                    try:
                        hq.kill()
                    except OSError:
                        pass
                    conn.sendall(b"bye\n@@SERV_OK\n")
                    conn.close()
                    os._exit(0)
                try:
                    payload, ok = forward_selfheal(cmd)
                    conn.sendall((payload + "\n" +
                                  ("@@SERV_OK\n" if ok else "@@SERV_ERR\n"))
                                 .encode("utf-8", errors="replace"))
                except (ConnectionError, OSError) as e:
                    conn.sendall(f"hqfpga link lost: {e}\n@@SERV_ERR\n"
                                 .encode("utf-8", errors="replace"))
        except OSError:
            pass  # client dropped mid-stream; keep serving
        finally:
            try:
                conn.close()
            except OSError:
                pass


def _spawn_daemon() -> None:
    logs_dir = launcher.side_log_dir()
    daemon_log = open(os.path.join(logs_dir, "serv_daemon.log"), "ab")
    subprocess.Popen(
        [sys.executable, "-m", "hqbuddy", "-serv", "--daemon"],
        stdout=daemon_log, stderr=subprocess.STDOUT,
        creationflags=subprocess.DETACHED_PROCESS | subprocess.CREATE_NEW_PROCESS_GROUP,
        close_fds=True)


def _wait_state(timeout: float = 20) -> dict:
    t0 = time.time()
    while time.time() - t0 < timeout:
        st = _load_state()
        if st:
            try:
                s = socket.create_connection(("127.0.0.1", st["ctrl_port"]),
                                             timeout=2)
                s.close()
                return st
            except OSError:
                pass
        time.sleep(0.3)
    raise SystemExit("Error: daemon 未在 20s 内就绪（见 %TEMP%\\hqbuddy\\hq_logs\\serv_daemon.log）。")


def cmd_start(args: list) -> None:
    st = _load_state()
    if st and _alive(st["daemon_pid"]):
        print(f"Resident session already running: daemon={st['daemon_pid']} "
              f"hqfpga={st['hqfpga_pid']} ctrl={st['ctrl_port']}")
        return
    if os.path.isfile(_state_path()):
        os.remove(_state_path())
    _spawn_daemon()
    st = _wait_state()
    print(f"[OK] Resident session started: daemon={st['daemon_pid']} "
          f"hqfpga={st['hqfpga_pid']}")
    print('Next: hqbuddy -serv -e "<tcl>"（状态跨命令持久）；hqbuddy -serv stop 关闭。')


def _require_alive() -> dict:
    st = _load_state()
    if not st or not _alive(st["daemon_pid"]):
        print("Error: 无常驻会话（或已退出）。先运行 hqbuddy -serv start。")
        sys.exit(1)
    return st


def _ctrl_exchange(ctrl_port: int, command: str, timeout: float = 1800) -> tuple[str, bool]:
    s = socket.create_connection(("127.0.0.1", ctrl_port), timeout=10)
    s.settimeout(timeout)
    try:
        s.sendall((command + "\n").encode("utf-8"))
        data = b""
        while b"@@SERV_OK" not in data and b"@@SERV_ERR" not in data:
            chunk = s.recv(65536)
            if not chunk:
                raise ConnectionError("daemon closed the connection")
            data += chunk
    finally:
        s.close()
    text = data.decode("utf-8", errors="replace")
    ok = "@@SERV_OK" in text
    return text.replace("@@SERV_OK", "").replace("@@SERV_ERR", "").strip("\r\n"), ok


def cmd_exec(args: list) -> None:
    st = _require_alive()
    if args and args[0] in ("-e", "-f"):
        args = args[1:]
    if args and args[0] == "-f":  # legacy placement: -serv -f handled below
        args = args[1:]
    if args and args[0] == "-f":
        # batch: source the file inside the resident session (one round trip)
        if len(args) < 1 or not os.path.isfile(args[0]):
            print("Usage: hqbuddy -serv -f <file.tcl>")
            sys.exit(1)
        f_tcl = os.path.abspath(args[0]).replace("\\", "/")
        text = f"source {{{f_tcl}}}"
    else:
        text = " ".join(args).strip()
        if not text:
            print('Usage: hqbuddy -serv -e "<tcl>"  |  -serv -f <file.tcl>')
            sys.exit(1)
    out, ok = _ctrl_exchange(st["ctrl_port"], text)
    print(out)
    if not ok:
        sys.exit(1)


def cmd_status() -> None:
    st = _load_state()
    if not st:
        print("No resident session.")
        return
    up = time.time() - st.get("started", time.time())
    print(f"daemon={st['daemon_pid']} ({'alive' if _alive(st['daemon_pid']) else 'DEAD'})  "
          f"hqfpga={st['hqfpga_pid']}  ctrl={st['ctrl_port']}  uptime={up/60:.0f}min")


def cmd_stop(args: list | None = None) -> None:
    st = _load_state()
    if not st:
        print("No resident session.")
        return
    if _alive(st["daemon_pid"]):
        try:
            _ctrl_exchange(st["ctrl_port"], "exit", timeout=15)
        except OSError:
            pass
        time.sleep(0.5)
    for pid in (st.get("daemon_pid"), st.get("hqfpga_pid")):
        if pid and _alive(pid):
            subprocess.run(["taskkill", "/PID", str(pid), "/F"],
                           capture_output=True)
    if os.path.isfile(_state_path()):
        os.remove(_state_path())
    print("[OK] Resident session stopped.")


def run_serv(args: list) -> None:
    if args and args[0] == "--daemon":
        _daemon_main()
        return
    if not args or args[0] == "start":
        cmd_start(args[1:] if args else [])
        return
    if args[0] in ("-e", "-f"):
        cmd_exec(args)
        return
    if args[0] == "status":
        cmd_status()
        return
    if args[0] == "stop":
        cmd_stop()
        return
    print("Usage: hqbuddy -serv start | -e \"<tcl>\" | status | stop")
    sys.exit(1)
