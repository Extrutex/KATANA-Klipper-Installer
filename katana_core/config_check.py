"""Config validation — replaces the legacy Bash greps (strangler phase 2).

Validates moonraker.conf and printer.cfg far beyond v2.6's Bash check
(which only grepped for a [server] section):

- real INI parsing; duplicate sections/options are hard errors (like Klipper)
- moonraker.conf: [server] present, port sane, klippy_uds_address plausible,
  [authorization] reviewed (open API surface is a security finding)
- printer.cfg: [printer] kinematics + motion limits, [mcu] present,
  placeholder serials flagged, [include ...] targets resolved (wildcards ok)

This module only REPORTS; it never rewrites configs. The caller decides.
Report schema is identical to katana_core.env_check for a uniform Bash seam.

CLI:    python3 -m katana_core.config_check [--json]
            [--moonraker PATH] [--printer PATH]
Exit:   0 = valid, 1 = fatal findings, 2 = invocation error
"""

from __future__ import annotations

import argparse
import configparser
import glob
import json
import os
import sys
from typing import Dict, List, Optional, Tuple

KNOWN_KINEMATICS = frozenset((
    "cartesian", "corexy", "corexz", "hybrid_corexy", "hybrid_corexz",
    "generic_cartesian", "delta", "deltesian", "rotary_delta", "polar",
    "winch", "none",
))
PLACEHOLDER_MARKERS = ("change-me", "changeme", "<", "xxx")
_PORT_MIN, _PORT_MAX = 1, 65535


def _finding(name: str, ok: bool, fatal: bool, detail: str) -> Dict:
    return {"name": name, "ok": ok, "fatal": fatal, "detail": detail}


def _load(path: str, name: str) -> Tuple[Optional[configparser.ConfigParser], Optional[Dict]]:
    """Parse an ini-style Klipper/Moonraker config. Returns (parser, fatal_finding)."""
    parser = configparser.ConfigParser(
        delimiters=("=", ":"),
        comment_prefixes=("#", ";"),
        inline_comment_prefixes=("#",),
        strict=True,            # duplicate sections/options -> error, like Klipper
        interpolation=None,     # '%' is legal in gcode macros
    )
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            parser.read_file(fh, source=os.path.basename(path))
    except OSError as exc:
        return None, _finding(name, False, True, f"cannot read {path}: {exc}")
    except configparser.DuplicateSectionError as exc:
        return None, _finding(name, False, True,
                              f"duplicate section [{exc.section}] (line {exc.lineno})")
    except configparser.DuplicateOptionError as exc:
        return None, _finding(name, False, True,
                              f"duplicate option '{exc.option}' in [{exc.section}] (line {exc.lineno})")
    except configparser.Error as exc:
        return None, _finding(name, False, True, f"syntax error: {exc}")
    return parser, None


# ==========================================================================
# moonraker.conf
# ==========================================================================

def check_moonraker_conf(path: str) -> List[Dict]:
    findings: List[Dict] = []
    parser, fatal = _load(path, "moonraker_syntax")
    if fatal:
        return [fatal]
    findings.append(_finding("moonraker_syntax", True, False,
                             f"parsed OK ({len(parser.sections())} sections)"))

    # [server] — the check the legacy Bash grep performed, done properly
    if not parser.has_section("server"):
        findings.append(_finding("server_section", False, True,
                                 "[server] section missing"))
        return findings
    findings.append(_finding("server_section", True, False, "[server] present"))

    # port
    port_raw = parser.get("server", "port", fallback="7125").strip()
    try:
        port = int(port_raw)
        ok = _PORT_MIN <= port <= _PORT_MAX
        findings.append(_finding(
            "server_port", ok, not ok,
            f"port = {port}" if ok else f"port {port} out of range {_PORT_MIN}-{_PORT_MAX}"))
    except ValueError:
        findings.append(_finding("server_port", False, True,
                                 f"port is not a number: {port_raw!r}"))

    # klippy_uds_address — parent dir should exist on a provisioned host
    uds = parser.get("server", "klippy_uds_address", fallback="").strip()
    if uds:
        parent = os.path.dirname(uds) or "/"
        if os.path.isdir(parent):
            findings.append(_finding("klippy_uds", True, False, f"uds dir exists: {parent}"))
        else:
            findings.append(_finding("klippy_uds", False, False,
                                     f"uds directory missing: {parent} (klipper not provisioned yet?)"))

    # [authorization] — open API without it is a security finding, not fatal
    if parser.has_section("authorization"):
        findings.append(_finding("authorization", True, False, "[authorization] configured"))
    else:
        findings.append(_finding("authorization", False, False,
                                 "no [authorization] section — Moonraker API is unrestricted"))
    return findings


# ==========================================================================
# printer.cfg
# ==========================================================================

def _check_includes(parser: configparser.ConfigParser, base_dir: str) -> List[Dict]:
    findings: List[Dict] = []
    for section in parser.sections():
        if not section.startswith("include "):
            continue
        target = section[len("include "):].strip()
        pattern = target if os.path.isabs(target) else os.path.join(base_dir, target)
        matches = glob.glob(pattern)
        if matches:
            findings.append(_finding("include", True, False,
                                     f"[include {target}] -> {len(matches)} file(s)"))
        elif any(ch in target for ch in "*?["):
            # Klipper allows wildcard includes that match nothing
            findings.append(_finding("include", False, False,
                                     f"[include {target}] matches nothing (wildcard, allowed)"))
        else:
            findings.append(_finding("include", False, True,
                                     f"[include {target}] file not found"))
    return findings


def _check_printer_section(parser: configparser.ConfigParser) -> List[Dict]:
    findings: List[Dict] = []
    if not parser.has_section("printer"):
        findings.append(_finding("printer_section", False, True,
                                 "[printer] section missing"))
        return findings
    findings.append(_finding("printer_section", True, False, "[printer] present"))

    kin = parser.get("printer", "kinematics", fallback="").strip()
    if not kin:
        findings.append(_finding("kinematics", False, True, "kinematics not set"))
        return findings
    if kin in KNOWN_KINEMATICS:
        findings.append(_finding("kinematics", True, False, f"kinematics = {kin}"))
    else:
        findings.append(_finding("kinematics", False, False,
                                 f"unknown kinematics {kin!r} (typo?)"))

    if kin != "none":
        for opt in ("max_velocity", "max_accel"):
            raw = parser.get("printer", opt, fallback="").strip()
            try:
                value = float(raw)
                ok = value > 0
                findings.append(_finding(
                    opt, ok, not ok,
                    f"{opt} = {value:g}" if ok else f"{opt} must be positive, got {value:g}"))
            except ValueError:
                findings.append(_finding(opt, False, True,
                                         f"{opt} missing or not a number: {raw!r}"))
    return findings


def _check_mcus(parser: configparser.ConfigParser) -> List[Dict]:
    findings: List[Dict] = []
    mcus = [s for s in parser.sections() if s == "mcu" or s.startswith("mcu ")]
    if not mcus:
        findings.append(_finding("mcu", False, True, "no [mcu] section"))
        return findings
    for section in mcus:
        serial = parser.get(section, "serial", fallback="").strip()
        canbus = parser.get(section, "canbus_uuid", fallback="").strip()
        if not serial and not canbus:
            findings.append(_finding("mcu", False, False,
                                     f"[{section}] has neither serial nor canbus_uuid"))
        elif serial and any(m in serial.lower() for m in PLACEHOLDER_MARKERS):
            findings.append(_finding("mcu", False, False,
                                     f"[{section}] serial is a placeholder: {serial}"))
        else:
            via = f"serial {serial}" if serial else f"canbus {canbus}"
            findings.append(_finding("mcu", True, False, f"[{section}] via {via}"))
    return findings


def check_printer_cfg(path: str) -> List[Dict]:
    findings: List[Dict] = []
    parser, fatal = _load(path, "printer_syntax")
    if fatal:
        return [fatal]
    findings.append(_finding("printer_syntax", True, False,
                             f"parsed OK ({len(parser.sections())} sections)"))

    findings.extend(_check_includes(parser, os.path.dirname(os.path.abspath(path))))
    findings.extend(_check_printer_section(parser))
    findings.extend(_check_mcus(parser))

    if not any(s.startswith("stepper_") for s in parser.sections()):
        findings.append(_finding("steppers", False, False,
                                 "no [stepper_*] sections (ok only for none-kinematics or includes)"))
    return findings


# ==========================================================================
# Report / CLI
# ==========================================================================

def run_all(moonraker: Optional[str] = None, printer: Optional[str] = None) -> Dict:
    checks: List[Dict] = []
    if moonraker:
        checks.extend(check_moonraker_conf(moonraker))
    if printer:
        checks.extend(check_printer_cfg(printer))
    fatal = [c["name"] for c in checks if c["fatal"]]
    return {"ready": not fatal, "fatal_checks": fatal, "checks": checks}


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(prog="katana_core.config_check",
                                     description=__doc__.splitlines()[0])
    parser.add_argument("--moonraker", metavar="PATH", help="moonraker.conf to validate")
    parser.add_argument("--printer", metavar="PATH", help="printer.cfg to validate")
    parser.add_argument("--json", action="store_true",
                        help="machine-readable report on stdout")
    args = parser.parse_args(argv)
    if not args.moonraker and not args.printer:
        parser.error("at least one of --moonraker/--printer is required")

    report = run_all(moonraker=args.moonraker, printer=args.printer)
    if args.json:
        json.dump(report, sys.stdout, indent=2)
        sys.stdout.write("\n")
    else:
        for c in report["checks"]:
            mark = "OK " if c["ok"] else ("!! " if c["fatal"] else "warn")
            print(f"[{mark}] {c['name']}: {c['detail']}")
        print("VALID" if report["ready"]
              else f"FATAL: {', '.join(report['fatal_checks'])}")
    return 0 if report["ready"] else 1


if __name__ == "__main__":
    sys.exit(main())
