"""Board registry & device detection — Python data source (strangler phase 3).

SINGLE SOURCE OF TRUTH (CLAUDE.md contract):

    The authoritative board registry is owned by HATCH and lives at
    ``~/.config/katana/registry/`` (selected_boards.json, devices.json,
    boards/*.toml, boards/custom/*.toml). KATANA *reads* this registry —
    it never owns a second board list.

    The old ``~/printer_data/config/katana_boards`` (.meta/.config pairs)
    directory is supported ONLY as a deprecated legacy fallback so existing
    installations keep working until the operator runs the HATCH wizard.
    Every legacy read emits a deprecation warning on stderr.

This module replaces two fragile Bash mechanisms in THE FORGE:

- ``source "$board.meta"`` executed the metadata files as shell code.
  Anything written into a .meta file ran with user privileges. This module
  PARSES the KEY="value" format instead — nothing is ever executed.
- Device detection was scattered greps over lsusb / /dev / /sys. Here it is
  one structured, testable inventory (USB serial, CAN interfaces, DFU/
  bootloader devices).

This module only REPORTS; flashing stays in Bash. The caller decides.

CLI:    python3 -m katana_core.flash_registry [--json]
            [--registry DIR] [--legacy-registry DIR] [--no-devices]
Exit:   0 = report produced, 2 = invocation error
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import re
import subprocess
import sys
from typing import Callable, Dict, List, Optional

try:  # Python >= 3.11
    import tomllib
except ModuleNotFoundError:  # pragma: no cover - exercised only on < 3.11 hosts
    tomllib = None

# KEY="value" or KEY=value — the format save_board_config() writes.
_META_LINE = re.compile(r'^\s*([A-Z][A-Z0-9_]*)\s*=\s*"?([^"\n]*)"?\s*$')

# Flat TOML fallback for hosts without tomllib: key = "value" | key = ["a", "b"]
_TOML_STRING_LINE = re.compile(r'^\s*([A-Za-z0-9_-]+)\s*=\s*"((?:[^"\\]|\\.)*)"\s*$')
_TOML_ARRAY_LINE = re.compile(r"^\s*([A-Za-z0-9_-]+)\s*=\s*\[(.*)\]\s*$")
_TOML_ARRAY_ITEM = re.compile(r'"((?:[^"\\]|\\.)*)"')

# `vendor/model` -> `vendor-model.toml` — MUST match hatch.boards.id_to_filename.
_ID_SAFE_RE = re.compile(r"[^a-z0-9]+")

# USB IDs that mean "bootloader / flash-ready"
DFU_USB_IDS = {
    "0483:df11": "STM32 DFU",
    "1d50:6177": "Katapult (stm32)",
    "2e8a:0003": "RP2040 BOOTSEL",
    "16d0:0cca": "Katapult (rp2040)",
}

SERIAL_BY_ID_DIR = "/dev/serial/by-id"
NET_CLASS_DIR = "/sys/class/net"

LEGACY_REGISTRY_DIR = "~/printer_data/config/katana_boards"

DEPRECATION_MESSAGE = (
    "[DEPRECATION] Board list read from the legacy printer_data directory. "
    "HATCH owns the authoritative registry at ~/.config/katana/registry — "
    "run `hatch` once to select your boards there (SSOT contract). "
    "The printer_data board list will be removed in a future release."
)


def default_registry_root() -> str:
    """Authoritative HATCH registry root.

    ``HATCH_REGISTRY_DIR`` is honored only so tests can isolate themselves —
    identical semantics to hatch.registry.registry_root(). It must never be
    set in a real operator environment.
    """
    override = os.environ.get("HATCH_REGISTRY_DIR")
    if override:
        return os.path.expanduser(override)
    return os.path.join(os.path.expanduser("~"), ".config", "katana", "registry")


def id_to_filename(board_id: str) -> str:
    """`vendor/model` -> `vendor-model.toml` — mirrors hatch.boards.id_to_filename."""
    safe = _ID_SAFE_RE.sub("-", board_id.lower()).strip("-")
    return f"{safe}.toml"


# ==========================================================================
# TOML loading (stdlib tomllib, flat-file fallback for older hosts)
# ==========================================================================

def _parse_flat_toml(text: str) -> Dict:
    """Minimal parser for HATCH's flat board TOML files (strings + string arrays).

    Used only when tomllib is unavailable (< Python 3.11). HATCH board files
    are guaranteed flat (see hatch.boards.BoardPreset.to_toml_dict), so this
    covers the full schema. Nothing is ever executed.
    """
    payload: Dict = {}
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        match = _TOML_STRING_LINE.match(line)
        if match:
            payload[match.group(1)] = match.group(2).replace('\\"', '"')
            continue
        match = _TOML_ARRAY_LINE.match(line)
        if match:
            payload[match.group(1)] = [
                item.replace('\\"', '"')
                for item in _TOML_ARRAY_ITEM.findall(match.group(2))
            ]
    return payload


def load_board_toml(path: str) -> Dict:
    with open(path, "rb") as fh:
        raw = fh.read()
    if tomllib is not None:
        return tomllib.loads(raw.decode("utf-8"))
    return _parse_flat_toml(raw.decode("utf-8"))


# ==========================================================================
# HATCH registry (authoritative): selected_boards.json + boards/*.toml + devices.json
# ==========================================================================

def _load_registry_json(path: str, list_key: str) -> List[Dict]:
    """Load one of the registry JSON files. Missing file = empty list.

    Corrupt files raise ValueError — the caller reports, never guesses
    (mirrors HATCH's refusing-to-guess policy).
    """
    if not os.path.isfile(path):
        return []
    with open(path, encoding="utf-8") as fh:
        raw = json.load(fh)
    if not isinstance(raw, dict) or "schema" not in raw or list_key not in raw:
        raise ValueError(f"{path} is missing required top-level keys 'schema'/'{list_key}'")
    if raw["schema"] != 1:
        raise ValueError(
            f"{path} has schema {raw['schema']!r} — no migration path here, "
            "resolve via HATCH (`hatch registry`)"
        )
    entries = raw[list_key]
    if not isinstance(entries, list):
        raise ValueError(f"{path}: '{list_key}' must be a list")
    return entries


def hatch_registry_present(registry_root: str) -> bool:
    """True iff HATCH has completed first-run board selection here."""
    return os.path.isfile(os.path.join(registry_root, "selected_boards.json"))


def list_hatch_boards(registry_root: str) -> List[Dict]:
    """Boards from the authoritative HATCH registry, enriched with device UUIDs.

    Broken individual files are reported per-entry, not fatal — this module
    only reports, HATCH owns repair.
    """
    boards: List[Dict] = []

    try:
        selected = _load_registry_json(
            os.path.join(registry_root, "selected_boards.json"), "selected")
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        return [{"name": "selected_boards.json", "source": "hatch",
                 "error": f"unreadable registry: {exc}"}]

    try:
        device_entries = _load_registry_json(
            os.path.join(registry_root, "devices.json"), "devices")
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        device_entries = []
        boards.append({"name": "devices.json", "source": "hatch",
                       "error": f"unreadable device ledger: {exc}"})

    devices_by_board: Dict[str, Dict] = {}
    for entry in device_entries:
        board_id = entry.get("board_id", "")
        known = devices_by_board.get(board_id)
        # Newest flash wins if a board was ever linked to more than one record.
        if known is None or entry.get("last_flash", "") >= known.get("last_flash", ""):
            devices_by_board[board_id] = entry

    for item in sorted(selected, key=lambda e: e.get("id", "")):
        board_id = item.get("id", "")
        filename = id_to_filename(board_id)
        candidates = [
            os.path.join(registry_root, "boards", filename),
            os.path.join(registry_root, "boards", "custom", filename),
        ]
        toml_path = next((c for c in candidates if os.path.isfile(c)), None)

        detail: Dict = {}
        if toml_path is not None:
            try:
                detail = load_board_toml(toml_path)
            except (OSError, ValueError) as exc:
                boards.append({"name": board_id, "source": "hatch",
                               "error": f"unreadable board file {toml_path}: {exc}"})
                continue

        device = devices_by_board.get(board_id, {})
        boards.append({
            "id": board_id,
            "name": item.get("display_name", board_id),
            "source": "hatch",
            "added_via": item.get("added_via", ""),
            "mcu_family": detail.get("mcu_family", "unknown"),
            "flash_method": detail.get("flash_method", "unknown"),
            "transports": list(detail.get("transports", [])),
            "board_toml": toml_path or os.path.join(registry_root, "boards", filename),
            "board_toml_exists": toml_path is not None,
            "uuid": device.get("uuid", ""),
            "transport": device.get("transport", ""),
            "last_flash": device.get("last_flash", ""),
        })
    return boards


# ==========================================================================
# Legacy board registry (.meta / .config pairs) — DEPRECATED fallback only
# ==========================================================================

def parse_meta(path: str) -> Dict[str, str]:
    """Parse a .meta file WITHOUT executing it. Unknown lines are ignored."""
    fields: Dict[str, str] = {}
    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            match = _META_LINE.match(line)
            if match:
                fields[match.group(1)] = match.group(2).strip()
    return fields


def list_boards(registry_dir: str) -> List[Dict]:
    """All saved LEGACY boards, sorted by name. Broken .meta files are reported, not fatal.

    Deprecated: kept only for the printer_data fallback and for
    flash_engine.sh's .meta parsing. New code reads list_hatch_boards().
    """
    boards: List[Dict] = []
    for meta_path in sorted(glob.glob(os.path.join(registry_dir, "*.meta"))):
        stem = os.path.splitext(os.path.basename(meta_path))[0]
        try:
            fields = parse_meta(meta_path)
        except OSError as exc:
            boards.append({"name": stem, "source": "legacy", "meta_path": meta_path,
                           "error": f"unreadable: {exc}"})
            continue
        name = fields.get("BOARD_NAME", stem)
        config_path = os.path.join(registry_dir, f"{name}.config")
        boards.append({
            "name": name,
            "source": "legacy",
            "arch": fields.get("ARCH", "unknown"),
            "flash_method": fields.get("FLASH_METHOD", "usb"),
            "last_built": fields.get("LAST_BUILT", ""),
            "meta_path": meta_path,
            "config_path": config_path,
            "config_exists": os.path.isfile(config_path),
        })
    return boards


def legacy_registry_present(legacy_dir: str) -> bool:
    return bool(glob.glob(os.path.join(legacy_dir, "*.meta")))


# ==========================================================================
# Device detection
# ==========================================================================

def detect_serial(by_id_dir: str = SERIAL_BY_ID_DIR) -> List[Dict]:
    devices = []
    try:
        entries = sorted(os.listdir(by_id_dir))
    except OSError:
        return devices
    for entry in entries:
        devices.append({"id": entry, "path": os.path.join(by_id_dir, entry)})
    return devices


def detect_can_interfaces(net_dir: str = NET_CLASS_DIR) -> List[str]:
    try:
        return sorted(i for i in os.listdir(net_dir) if i.startswith("can"))
    except OSError:
        return []


def detect_dfu(runner: Callable = subprocess.run) -> List[Dict]:
    """Bootloader-mode USB devices via lsusb (absent lsusb = empty list)."""
    try:
        proc = runner(["lsusb"], capture_output=True, text=True,
                      timeout=10, check=False)
    except (OSError, subprocess.TimeoutExpired):
        return []
    found = []
    for line in proc.stdout.splitlines():
        for usb_id, label in DFU_USB_IDS.items():
            if usb_id in line.lower():
                found.append({"usb_id": usb_id, "label": label,
                              "lsusb": line.strip()})
    return found


def detect_devices(runner: Callable = subprocess.run,
                   by_id_dir: str = SERIAL_BY_ID_DIR,
                   net_dir: str = NET_CLASS_DIR) -> Dict:
    return {
        "serial": detect_serial(by_id_dir),
        "can_interfaces": detect_can_interfaces(net_dir),
        "dfu": detect_dfu(runner),
    }


# ==========================================================================
# Report / CLI
# ==========================================================================

def run_all(registry_root: Optional[str] = None,
            legacy_dir: Optional[str] = None,
            include_devices: bool = True,
            warn: Callable[[str], None] = lambda msg: print(msg, file=sys.stderr)) -> Dict:
    """Build the board/device report.

    Resolution order (SSOT contract):
      1. HATCH registry (selected_boards.json present) — authoritative.
      2. Legacy printer_data .meta directory — deprecated, warns loudly.
      3. Neither: empty HATCH-shaped report. First-run board selection is
         HATCH's job (its wizard); KATANA never guesses boards.
    """
    resolved_root = registry_root or default_registry_root()
    resolved_legacy = os.path.expanduser(legacy_dir or LEGACY_REGISTRY_DIR)

    if hatch_registry_present(resolved_root):
        report: Dict = {
            "registry_dir": resolved_root,
            "source": "hatch",
            "boards": list_hatch_boards(resolved_root),
        }
    elif legacy_registry_present(resolved_legacy):
        warn(DEPRECATION_MESSAGE)
        report = {
            "registry_dir": resolved_legacy,
            "source": "legacy",
            "deprecated": True,
            "warning": DEPRECATION_MESSAGE,
            "boards": list_boards(resolved_legacy),
        }
    else:
        report = {
            "registry_dir": resolved_root,
            "source": "hatch",
            "boards": [],
            "hint": "no boards selected yet — run the HATCH first-run wizard",
        }

    if include_devices:
        report["devices"] = detect_devices()
    return report


def _print_board_line(board: Dict) -> None:
    if "error" in board:
        print(f"  [!!] {board['name']}: {board['error']}")
        return
    if board.get("source") == "hatch":
        uuid = board["uuid"] or "no uuid yet"
        toml_state = "ok" if board["board_toml_exists"] else "BOARD FILE MISSING"
        transport = board["transport"] or "/".join(board["transports"]) or "?"
        print(f"  [{transport:>6}] {board['name']} "
              f"({board['mcu_family']}, {board['flash_method']}, {uuid}, {toml_state})")
        return
    cfg = "ok" if board["config_exists"] else "CONFIG MISSING"
    print(f"  [{board['flash_method']:>6}] {board['name']} "
          f"({board['arch']}, built {board['last_built'] or 'never'}, {cfg})")


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(prog="katana_core.flash_registry",
                                     description=__doc__.splitlines()[0])
    parser.add_argument("--registry", metavar="DIR", default=None,
                        help="HATCH registry root "
                             "(default: ~/.config/katana/registry)")
    parser.add_argument("--legacy-registry", metavar="DIR",
                        default=LEGACY_REGISTRY_DIR,
                        help="DEPRECATED fallback board dir "
                             "(default: %(default)s)")
    parser.add_argument("--no-devices", action="store_true",
                        help="skip USB/CAN device detection")
    parser.add_argument("--json", action="store_true",
                        help="machine-readable report on stdout")
    args = parser.parse_args(argv)

    report = run_all(registry_root=args.registry,
                     legacy_dir=args.legacy_registry,
                     include_devices=not args.no_devices)
    if args.json:
        json.dump(report, sys.stdout, indent=2)
        sys.stdout.write("\n")
    else:
        print(f"Registry: {report['registry_dir']} (source: {report['source']})")
        for board in report["boards"]:
            _print_board_line(board)
        if "devices" in report:
            dev = report["devices"]
            print(f"Serial: {len(dev['serial'])}  "
                  f"CAN: {', '.join(dev['can_interfaces']) or 'none'}  "
                  f"DFU: {len(dev['dfu'])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
