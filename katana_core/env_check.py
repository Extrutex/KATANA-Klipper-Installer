"""Host preflight check — Python port of core/env_check.sh (strangler phase 1).

Differences from the Bash original (intentional fixes):
- apt packages (python3-serial, python3-can) are checked via dpkg-query,
  not `command -v` (they are packages, not executables).
- connectivity probes an HTTPS endpoint instead of `ping google.com`
  (ICMP/DNS are blocked on many shop networks).
- this module only REPORTS; it never installs anything. The caller decides.

CLI:    python3 -m katana_core.env_check [--json]
Exit:   0 = ready, 1 = fatal findings, 2 = invocation error
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import socket
import subprocess
import sys
from typing import Callable, Dict, List, Optional

REQUIRED_BINARIES = (
    "git", "curl", "wget", "python3", "virtualenv",
    "dfu-util", "rsync", "make", "gcc",
)
REQUIRED_APT_PACKAGES = ("python3-serial", "python3-can")
MIN_DISK_GB = 2.0
CONNECTIVITY_HOSTS = (("github.com", 443), ("raspberrypi.com", 443))
_CONNECT_TIMEOUT_S = 3.0


def check_not_root(euid: Optional[int] = None) -> Dict:
    euid = os.geteuid() if euid is None else euid
    ok = euid != 0
    return {"name": "not_root", "ok": ok, "fatal": not ok,
            "detail": "running as root is forbidden" if not ok else f"euid={euid}"}


def check_os(os_release_path: str = "/etc/os-release") -> Dict:
    """Debian-family check. Non-fatal: KATANA warns but continues elsewhere."""
    try:
        with open(os_release_path, encoding="utf-8") as fh:
            fields = dict(
                line.rstrip("\n").split("=", 1)
                for line in fh if "=" in line
            )
    except OSError as exc:
        return {"name": "os", "ok": False, "fatal": False,
                "detail": f"cannot read {os_release_path}: {exc}"}
    os_id = fields.get("ID", "").strip('"')
    id_like = fields.get("ID_LIKE", "").strip('"')
    ok = os_id in ("debian", "raspbian") or "debian" in id_like
    return {"name": "os", "ok": ok, "fatal": False,
            "detail": f"ID={os_id or '?'} ID_LIKE={id_like or '?'}"}


def check_disk_space(path: str = "/", min_gb: float = MIN_DISK_GB) -> Dict:
    if min_gb <= 0:
        raise ValueError(f"min_gb must be positive, got {min_gb}")
    try:
        usage = shutil.disk_usage(path)
    except OSError as exc:
        return {"name": "disk_space", "ok": False, "fatal": True,
                "detail": f"cannot stat {path}: {exc}"}
    free_gb = usage.free / (1024 ** 3)
    ok = free_gb >= min_gb
    return {"name": "disk_space", "ok": ok, "fatal": not ok,
            "detail": f"{free_gb:.1f} GB free (need >= {min_gb:g} GB)"}


def check_connectivity(
    hosts=CONNECTIVITY_HOSTS,
    connector: Callable = socket.create_connection,
) -> Dict:
    """TCP-connect to known HTTPS hosts; any single success counts."""
    errors: List[str] = []
    for host, port in hosts:
        try:
            with connector((host, port), timeout=_CONNECT_TIMEOUT_S):
                return {"name": "connectivity", "ok": True, "fatal": False,
                        "detail": f"reached {host}:{port}"}
        except OSError as exc:
            errors.append(f"{host}:{port} -> {exc}")
    return {"name": "connectivity", "ok": False, "fatal": True,
            "detail": "; ".join(errors) or "no hosts configured"}


def check_time_sync(runner: Callable = subprocess.run) -> Dict:
    """Non-fatal: unsynced clocks break SSL/APT, but timedatectl may be absent."""
    try:
        proc = runner(
            ["timedatectl", "show", "-p", "NTPSynchronized", "--value"],
            capture_output=True, text=True, timeout=5, check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        return {"name": "time_sync", "ok": False, "fatal": False,
                "detail": f"timedatectl unavailable: {exc}"}
    synced = proc.stdout.strip() == "yes"
    return {"name": "time_sync", "ok": synced, "fatal": False,
            "detail": "NTP synchronized" if synced else "clock NOT synchronized"}


def check_binaries(required=REQUIRED_BINARIES,
                   which: Callable = shutil.which) -> Dict:
    missing = [b for b in required if which(b) is None]
    return {"name": "binaries", "ok": not missing, "fatal": False,
            "detail": f"missing: {', '.join(missing)}" if missing else "all present",
            "missing": missing}


def check_apt_packages(required=REQUIRED_APT_PACKAGES,
                       runner: Callable = subprocess.run) -> Dict:
    missing: List[str] = []
    for pkg in required:
        try:
            proc = runner(
                ["dpkg-query", "-W", "-f=${Status}", pkg],
                capture_output=True, text=True, timeout=10, check=False,
            )
        except (OSError, subprocess.TimeoutExpired):
            return {"name": "apt_packages", "ok": False, "fatal": False,
                    "detail": "dpkg-query unavailable (non-Debian host?)",
                    "missing": list(required)}
        if proc.returncode != 0 or "install ok installed" not in proc.stdout:
            missing.append(pkg)
    return {"name": "apt_packages", "ok": not missing, "fatal": False,
            "detail": f"missing: {', '.join(missing)}" if missing else "all installed",
            "missing": missing}


def run_all() -> Dict:
    checks = [
        check_not_root(),
        check_os(),
        check_disk_space(),
        check_connectivity(),
        check_time_sync(),
        check_binaries(),
        check_apt_packages(),
    ]
    fatal = [c["name"] for c in checks if c["fatal"]]
    return {"ready": not fatal, "fatal_checks": fatal, "checks": checks}


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(prog="katana_core.env_check",
                                     description=__doc__.splitlines()[0])
    parser.add_argument("--json", action="store_true",
                        help="machine-readable report on stdout")
    args = parser.parse_args(argv)

    report = run_all()
    if args.json:
        json.dump(report, sys.stdout, indent=2)
        sys.stdout.write("\n")
    else:
        for c in report["checks"]:
            mark = "OK " if c["ok"] else ("!! " if c["fatal"] else "warn")
            print(f"[{mark}] {c['name']}: {c['detail']}")
        print("READY" if report["ready"]
              else f"FATAL: {', '.join(report['fatal_checks'])}")
    return 0 if report["ready"] else 1


if __name__ == "__main__":
    sys.exit(main())
