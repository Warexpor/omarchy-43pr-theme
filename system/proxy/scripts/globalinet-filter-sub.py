#!/usr/bin/env python3
"""Filter globalinet subscription profiles after a sub update.

- RU servers stay in the list; never probed, never used by this script.
- Non-RU servers get a real VLESS probe via a private setgid-xray socks
  (does NOT change v2rayN system proxy / active outbound / iptables).
- Non-RU failures are deleted from guiNDB.db (reappear on next sub update
  until filtered again).
- The currently selected profile is never deleted.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import json
import os
import re
import socket
import sqlite3
import subprocess
import sys
import tempfile
import threading
import time
from pathlib import Path

HOME = Path(os.path.expanduser("~"))
DEFAULT_DB = HOME / ".local/share/v2rayN/guiConfigs/guiNDB.db"
DEFAULT_GUI = HOME / ".local/share/v2rayN/guiConfigs/guiNConfig.json"
DEFAULT_XRAY = HOME / ".local/share/v2rayN/bin/xray/xray"
DEFAULT_STATE = HOME / ".local/share/proxy-all/globalinet-filter"
DEFAULT_SUB_REMARKS = "globalinet"
PROBE_URL = "https://cloudflare.com/cdn-cgi/trace"
RU_MESSAGE = "RU: kept (never probed)"
OK_MESSAGE = "ok (vless probe)"
FAIL_MESSAGE = "dead (vless probe)"

_print_lock = threading.Lock()


def log(msg: str) -> None:
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}"
    with _print_lock:
        print(line, flush=True)


def is_ru(remarks: str | None, address: str | None) -> bool:
    rem = remarks or ""
    addr = (address or "").lower()
    if "🇷🇺" in rem:
        return True
    if re.search(r"Моск|Russia|Росс", rem, re.I):
        return True
    if re.search(r"(^|[^A-Za-z])RU([^A-Za-z]|$)", rem):
        return True
    if addr.endswith(".ru") or ".ru." in addr:
        return True
    # This subscription labels 4hyperx as RU; keep host guard as backup.
    if "4hyperx" in addr or "4hyperx" in rem.lower():
        return True
    for needle in ("sberbank", "vtb.", "roskomnadzor", "rutube", "wildberries"):
        if needle in addr or needle in rem.lower():
            return True
    return False


def connect_db(db_path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(str(db_path), timeout=60)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA busy_timeout=60000")
    return conn


def profile_fingerprint(conn: sqlite3.Connection, subid: str) -> str:
    rows = conn.execute(
        "SELECT IndexId FROM ProfileItem WHERE Subid=? ORDER BY IndexId",
        (subid,),
    ).fetchall()
    return ",".join(r["IndexId"] for r in rows)


def resolve_subid(conn: sqlite3.Connection, remarks: str, subid: str | None) -> str:
    if subid:
        row = conn.execute("SELECT Id FROM SubItem WHERE Id=?", (subid,)).fetchone()
        if not row:
            raise SystemExit(f"SubItem id not found: {subid}")
        return subid
    row = conn.execute(
        "SELECT Id FROM SubItem WHERE Remarks=? COLLATE NOCASE", (remarks,)
    ).fetchone()
    if not row:
        raise SystemExit(f"SubItem remarks not found: {remarks}")
    return row["Id"]


def active_index_id(gui_path: Path) -> str | None:
    if not gui_path.is_file():
        return None
    try:
        data = json.loads(gui_path.read_text())
    except (OSError, json.JSONDecodeError):
        return None
    idx = data.get("IndexId")
    return str(idx) if idx is not None and idx != "" else None


def load_profiles(conn: sqlite3.Connection, subid: str) -> list[dict]:
    cols = [r[1] for r in conn.execute("PRAGMA table_info(ProfileItem)")]
    out = []
    for row in conn.execute("SELECT * FROM ProfileItem WHERE Subid=?", (subid,)):
        out.append(dict(zip(cols, row)))
    return out


def build_outbound(d: dict) -> dict:
    te = json.loads(d.get("TransportExtra") or "{}")
    pe = json.loads(d.get("ProtoExtra") or "{}")
    uid = d.get("Password") or d.get("Id")
    if not uid:
        raise ValueError("missing uuid")
    addr = d["Address"]
    port = int(d["Port"])
    net = d.get("Network") or "tcp"
    sec = d.get("StreamSecurity") or "none"
    sni = d.get("Sni") or addr
    fp = d.get("Fingerprint") or "chrome"
    flow = d.get("Flow") or pe.get("Flow") or ""
    user = {
        "id": uid,
        "encryption": pe.get("VlessEncryption") or "none",
        "email": "t@t.tt",
    }
    if flow:
        user["flow"] = flow
    outbound = {
        "tag": "proxy",
        "protocol": "vless",
        "settings": {"vnext": [{"address": addr, "port": port, "users": [user]}]},
        "streamSettings": {"network": net, "security": sec},
        "mux": {"enabled": False, "concurrency": -1},
    }
    ss = outbound["streamSettings"]
    if sec == "tls":
        tls = {"serverName": sni, "fingerprint": fp}
        if d.get("Alpn"):
            tls["alpn"] = [x.strip() for x in d["Alpn"].split(",") if x.strip()]
        ss["tlsSettings"] = tls
    elif sec == "reality":
        ss["realitySettings"] = {
            "serverName": sni,
            "fingerprint": fp,
            "publicKey": d.get("PublicKey") or "",
            "shortId": d.get("ShortId") or "",
            "spiderX": d.get("SpiderX") or "",
        }
    if net == "ws":
        ws = {"path": d.get("Path") or te.get("Path") or "/"}
        host = d.get("RequestHost") or te.get("Host")
        if host:
            ws["headers"] = {"Host": host}
        ss["wsSettings"] = ws
    elif net == "grpc":
        ss["grpcSettings"] = {
            "serviceName": te.get("GrpcServiceName") or d.get("Path") or "",
            "authority": te.get("GrpcAuthority") or d.get("RequestHost") or sni,
            "multiMode": te.get("GrpcMode") == "multi",
        }
    elif net == "xhttp":
        xh = {
            "path": d.get("Path") or te.get("Path") or "/",
            "host": d.get("RequestHost") or te.get("Host") or "",
        }
        mode = te.get("Mode") or te.get("XhttpMode")
        if mode:
            xh["mode"] = mode
        ss["xhttpSettings"] = xh
    return outbound


def free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("127.0.0.1", 0))
        return int(s.getsockname()[1])


def probe_one(
    d: dict,
    xray: Path,
    work_dir: Path,
    timeout: float,
) -> tuple[str, bool, int, str]:
    """Return (IndexId, ok, latency_ms, detail)."""
    idx = d["IndexId"]
    remarks = (d.get("Remarks") or "")[:70]
    port = free_port()
    cfg_path = work_dir / f"cfg-{idx}.json"
    err_path = work_dir / f"err-{idx}.log"
    out_path = work_dir / f"out-{idx}.log"
    try:
        outbound = build_outbound(d)
    except Exception as e:
        return idx, False, -1, f"bad profile: {e}"

    cfg = {
        "log": {"loglevel": "error", "error": str(err_path)},
        "inbounds": [
            {
                "tag": "socks",
                "port": port,
                "listen": "127.0.0.1",
                "protocol": "mixed",
                "settings": {"auth": "noauth", "udp": False},
            }
        ],
        "outbounds": [
            outbound,
            {"tag": "direct", "protocol": "freedom"},
            {"tag": "block", "protocol": "blackhole"},
        ],
        "routing": {
            "domainStrategy": "AsIs",
            "rules": [{"type": "field", "port": "0-65535", "outboundTag": "proxy"}],
        },
    }
    cfg_path.write_text(json.dumps(cfg))
    proc = subprocess.Popen(
        [str(xray), "run", "-c", str(cfg_path)],
        stdout=open(out_path, "w"),
        stderr=subprocess.STDOUT,
        start_new_session=True,
    )
    t0 = time.time()
    try:
        for _ in range(40):
            if proc.poll() is not None:
                tail = out_path.read_text(errors="ignore")[-240:].replace("\n", " ")
                return idx, False, -1, f"xray exit: {tail}"
            try:
                s = socket.create_connection(("127.0.0.1", port), timeout=0.2)
                s.close()
                break
            except OSError:
                time.sleep(0.1)
        else:
            return idx, False, -1, "xray listen timeout"

        p = subprocess.run(
            [
                "curl",
                "-sS",
                "-m",
                str(max(1, int(timeout))),
                "--proxy",
                f"socks5h://127.0.0.1:{port}",
                PROBE_URL,
            ],
            capture_output=True,
            text=True,
        )
        ms = int((time.time() - t0) * 1000)
        if p.returncode == 0 and "ip=" in p.stdout:
            ip_m = re.search(r"ip=(\S+)", p.stdout)
            loc_m = re.search(r"loc=(\S+)", p.stdout)
            detail = f"egress {ip_m.group(1) if ip_m else '?'} loc={loc_m.group(1) if loc_m else '?'}"
            return idx, True, ms, detail
        err = (p.stderr or "").strip()[:160]
        return idx, False, ms, f"curl rc={p.returncode} {err}"
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=3)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait(timeout=2)
        for pth in (cfg_path, err_path, out_path):
            try:
                pth.unlink()
            except OSError:
                pass


def upsert_ex(
    conn: sqlite3.Connection,
    index_id: str,
    delay: int,
    message: str,
) -> None:
    row = conn.execute(
        "SELECT IndexId FROM ProfileExItem WHERE IndexId=?", (index_id,)
    ).fetchone()
    if row:
        conn.execute(
            "UPDATE ProfileExItem SET Delay=?, Message=? WHERE IndexId=?",
            (delay, message, index_id),
        )
    else:
        conn.execute(
            "INSERT INTO ProfileExItem (IndexId, Delay, Speed, Sort, Message, IpInfo) "
            "VALUES (?, ?, 0, 0, ?, NULL)",
            (index_id, delay, message),
        )


def delete_profiles(conn: sqlite3.Connection, ids: list[str]) -> None:
    if not ids:
        return
    # Chunk deletes for sqlite variable limits
    for i in range(0, len(ids), 200):
        chunk = ids[i : i + 200]
        q = ",".join("?" * len(chunk))
        conn.execute(f"DELETE FROM ProfileItem WHERE IndexId IN ({q})", chunk)
        conn.execute(f"DELETE FROM ProfileExItem WHERE IndexId IN ({q})", chunk)
        conn.execute(f"DELETE FROM ServerStatItem WHERE IndexId IN ({q})", chunk)


def run_filter(args: argparse.Namespace) -> int:
    db_path = Path(args.db)
    gui_path = Path(args.gui)
    xray = Path(args.xray)
    state_dir = Path(args.state_dir)
    state_dir.mkdir(parents=True, exist_ok=True)
    log_path = state_dir / "filter.log"

    class Tee:
        def __init__(self, stream, path: Path):
            self.stream = stream
            self.fp = open(path, "a")

        def write(self, s: str) -> int:
            self.stream.write(s)
            self.fp.write(s)
            self.fp.flush()
            return len(s)

        def flush(self) -> None:
            self.stream.flush()
            self.fp.flush()

    sys.stdout = Tee(sys.__stdout__, log_path)  # type: ignore[assignment]

    if not db_path.is_file():
        log(f"ERROR: db missing: {db_path}")
        return 1
    if not xray.is_file() or not os.access(xray, os.X_OK):
        log(f"ERROR: xray missing/not executable: {xray}")
        return 1

    # setgid proxy-exempt bit is required so probes dial direct under tproxy
    st = xray.stat()
    if not (st.st_mode & 0o2000):
        log(
            f"WARN: {xray} is not setgid; under transparent proxy probes may "
            "loop through the active outbound"
        )

    conn = connect_db(db_path)
    subid = resolve_subid(conn, args.sub_remarks, args.sub_id)
    active = active_index_id(gui_path)
    profiles = load_profiles(conn, subid)
    fp_before = profile_fingerprint(conn, subid)
    log(
        f"sub={subid} profiles={len(profiles)} active={active} "
        f"dry_run={args.dry_run} concurrency={args.concurrency}"
    )

    ru: list[dict] = []
    probe_targets: list[dict] = []
    for d in profiles:
        if is_ru(d.get("Remarks"), d.get("Address")):
            ru.append(d)
        else:
            probe_targets.append(d)

    if args.limit and args.limit > 0:
        probe_targets = probe_targets[: args.limit]
        log(f"RU kept (not probed): {len(ru)}; non-RU to probe (limited): {len(probe_targets)}")
    else:
        log(f"RU kept (not probed): {len(ru)}; non-RU to probe: {len(probe_targets)}")

    # Clear polluted delay numbers on RU so they do not look "live"
    if not args.dry_run:
        for d in ru:
            upsert_ex(conn, d["IndexId"], -1, RU_MESSAGE)
        conn.commit()

    work_dir = Path(tempfile.mkdtemp(prefix="globalinet-filter-"))
    ok_ids: dict[str, tuple[int, str]] = {}
    fail_ids: list[str] = []
    skipped_active_fail: str | None = None

    try:
        with concurrent.futures.ThreadPoolExecutor(max_workers=args.concurrency) as ex:
            futs = {
                ex.submit(probe_one, d, xray, work_dir, args.timeout): d
                for d in probe_targets
            }
            done_n = 0
            total = len(futs)
            for fut in concurrent.futures.as_completed(futs):
                d = futs[fut]
                done_n += 1
                try:
                    idx, ok, ms, detail = fut.result()
                except Exception as e:
                    idx, ok, ms, detail = d["IndexId"], False, -1, f"exc {e}"
                tag = (d.get("Remarks") or idx)[:56]
                if ok:
                    ok_ids[idx] = (ms, detail)
                    log(f"OK  [{done_n}/{total}] {ms}ms {tag} :: {detail}")
                else:
                    if active and idx == active:
                        skipped_active_fail = idx
                        log(
                            f"KEEP[{done_n}/{total}] active failed probe "
                            f"(not deleting): {tag} :: {detail}"
                        )
                    else:
                        fail_ids.append(idx)
                        log(f"FAIL[{done_n}/{total}] {tag} :: {detail}")
    finally:
        for p in work_dir.glob("*"):
            try:
                p.unlink()
            except OSError:
                pass
        try:
            work_dir.rmdir()
        except OSError:
            pass

    log(
        f"probe done: ok={len(ok_ids)} fail_delete={len(fail_ids)} "
        f"active_kept_fail={1 if skipped_active_fail else 0} ru={len(ru)}"
    )

    if args.dry_run:
        log("dry-run: no DB deletes/updates (fingerprint unchanged)")
        return 0

    # Re-open in case of long probe (and refresh)
    conn.close()
    conn = connect_db(db_path)
    # Only delete ids that still exist and still belong to this sub
    still = {
        r["IndexId"]
        for r in conn.execute(
            "SELECT IndexId FROM ProfileItem WHERE Subid=?", (subid,)
        )
    }
    to_delete = [i for i in fail_ids if i in still and i != active]
    delete_profiles(conn, to_delete)
    for idx, (ms, _detail) in ok_ids.items():
        if idx in still:
            upsert_ex(conn, idx, ms, OK_MESSAGE)
    # Re-assert RU markers (sub update may have refreshed ProfileEx)
    for d in ru:
        if d["IndexId"] in still or d["IndexId"] in {
            r["IndexId"]
            for r in conn.execute(
                "SELECT IndexId FROM ProfileItem WHERE Subid=?", (subid,)
            )
        }:
            upsert_ex(conn, d["IndexId"], -1, RU_MESSAGE)
    # Refresh RU from DB after possible concurrent sub rewrite
    for r in conn.execute(
        "SELECT IndexId, Remarks, Address FROM ProfileItem WHERE Subid=?", (subid,)
    ):
        if is_ru(r["Remarks"], r["Address"]):
            upsert_ex(conn, r["IndexId"], -1, RU_MESSAGE)
    conn.commit()
    fp_after = profile_fingerprint(conn, subid)
    conn.close()

    (state_dir / "last-fingerprint.txt").write_text(fp_after + "\n")
    (state_dir / "last-run.json").write_text(
        json.dumps(
            {
                "ts": int(time.time()),
                "subid": subid,
                "ok": len(ok_ids),
                "deleted": len(to_delete),
                "ru": len(ru),
                "active": active,
                "active_failed_kept": skipped_active_fail,
                "fingerprint": fp_after,
            },
            indent=2,
        )
        + "\n"
    )
    log(f"deleted {len(to_delete)} dead non-RU; fingerprint saved")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--db", default=str(DEFAULT_DB))
    ap.add_argument("--gui", default=str(DEFAULT_GUI))
    ap.add_argument("--xray", default=str(DEFAULT_XRAY))
    ap.add_argument("--state-dir", default=str(DEFAULT_STATE))
    ap.add_argument("--sub-remarks", default=DEFAULT_SUB_REMARKS)
    ap.add_argument("--sub-id", default=None)
    ap.add_argument("--concurrency", type=int, default=6)
    ap.add_argument("--timeout", type=float, default=12.0)
    ap.add_argument("--limit", type=int, default=0, help="Probe at most N non-RU (0=all)")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument(
        "--fingerprint-only",
        action="store_true",
        help="Print ProfileItem fingerprint for the sub and exit",
    )
    args = ap.parse_args()
    if args.fingerprint_only:
        conn = connect_db(Path(args.db))
        subid = resolve_subid(conn, args.sub_remarks, args.sub_id)
        print(profile_fingerprint(conn, subid))
        return 0
    return run_filter(args)


if __name__ == "__main__":
    raise SystemExit(main())
