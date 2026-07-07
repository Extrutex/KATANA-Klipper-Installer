"""Board registry & device detection — Python data source (strangler phase 3).

Replaces two fragile Bash mechanisms in THE FORGE:

- ``source "$board.meta"`` executed the metadata files as shell code.
  Anything written into a .meta file ran with user privileges. This module
  PARSES the KEY="value" format instead — nothing is ever executed.
- Device detection was scattered greps over lsusb / /dev / /sys. Here it is
  one structured, testable inventory (USB serial, CAN interfaces, DFU/
  bootloader devices).

This module only REPORTS; flashing stays in Bash. The caller decides.

CLI:    python3 -m katana_core.flash_registry [--json]
            [--registry DIR] [--no-devices]
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

# KEY="value" or KEY=value — the format save_board_config() writes.
_META_LINE = re.compile(r'^\s*([A-Z][A-Z0-9_]*)\s*=\s*"?([^"\n]*)"?\s*$')

# USB IDs that mean "bootloader / flash-ready"
DFU_USB_IDS = {
    "0483:df11": "STM32 DFU",
    "1d50:6177": "Katapult (stm32)",
    "2e8a:0003": "RP2040 BOOTSEL",
    "16d0:0cca": "Katapult (rp2040)",
}

SERIAL_BY_ID_DIR = "/dev/serial/by-id"
NET_CLASS_DIR = "/sys/class/net"


# ==========================================================================
# Board registry (.meta / .config pairs)
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
    """All saved boards, sorted by name. Broken .meta files are reported, not fatal."""
    boards: List[Dict] = []
    for meta_path in sorted(glob.glob(os.path.join(registry_dir, "*.meta"))):
        stem = os.path.splitext(os.path.basename(meta_path))[0]
        try:
            fields = parse_meta(meta_path)
        except OSError as exc:
            boards.append({"name": stem, "meta_path": meta_path,
                           "error": f"unreadable: {exc}"})
            continue
        name = fields.get("BOARD_NAME", stem)
        config_path = os.path.join(registry_dir, f"{name}.config")
        boards.append({
            "name": name,
            "arch": fields.get("ARCH", "unknown"),
            "flash_method": fields.get("FLASH_METHOD", "usb"),
            "last_built": fields.get("LAST_BUILT", ""),
            "meta_path": meta_path,
            "config_path": config_path,
            "config_exists": os.path.isfile(config_path),
        })
    return boards


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

def run_all(registry_dir: str, include_devices: bool = True) -> Dict:
    report: Dict = {
        "registry_dir": registry_dir,
        "boards": list_boards(registry_dir),
    }
    if include_devices:
        report["devices"] = detect_devices()
    return report


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(prog="katana_core.flash_registry",
                                     description=__doc__.splitlines()[0])
    parser.add_argument("--registry", metavar="DIR",
                        default=os.path.expanduser(
                            "~/printer_data/config/katana_boards"),
                        help="board registry directory (default: %(default)s)")
    parser.add_argument("--no-devices", action="store_true",
                        help="skip USB/CAN device detection")
    parser.add_argument("--json", action="store_true",
                        help="machine-readable report on stdout")
    args = parser.parse_args(argv)

    report = run_all(args.registry, include_devices=not args.no_devices)
    if args.json:
        json.dump(report, sys.stdout, indent=2)
        sys.stdout.write("\n")
    else:
        print(f"Registry: {report['registry_dir']}")
        for b in report["boards"]:
            if "error" in b:
                print(f"  [!!] {b['name']}: {b['error']}")
            else:
                cfg = "ok" if b["config_exists"] else "CONFIG MISSING"
                print(f"  [{b['flash_method']:>6}] {b['name']} "
                      f"({b['arch']}, built {b['last_built'] or 'never'}, {cfg})")
        if "devices" in report:
            dev = report["devices"]
            print(f"Serial: {len(dev['serial'])}  "
                  f"CAN: {', '.join(dev['can_interfaces']) or 'none'}  "
                  f"DFU: {len(dev['dfu'])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
