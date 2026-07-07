"""Tests for katana_core.flash_registry — tmp_path fixtures, no hardware."""

import json
from unittest.mock import MagicMock

from katana_core import flash_registry

VALID_META = '''\
BOARD_NAME="SHT36_Toolhead"
LAST_BUILT="2026-07-01 12:00:00"
ARCH="stm32"
FLASH_METHOD="can"
'''


def _board(tmp_path, name="SHT36_Toolhead", meta=VALID_META, with_config=True):
    (tmp_path / f"{name}.meta").write_text(meta)
    if with_config:
        (tmp_path / f"{name}.config").write_text("CONFIG_MACH_STM32=y\n")
    return str(tmp_path)


class TestParseMeta:
    def test_parses_key_value_pairs(self, tmp_path):
        f = tmp_path / "b.meta"
        f.write_text(VALID_META)
        fields = flash_registry.parse_meta(str(f))
        assert fields["BOARD_NAME"] == "SHT36_Toolhead"
        assert fields["ARCH"] == "stm32"
        assert fields["FLASH_METHOD"] == "can"

    def test_shell_code_is_NOT_executed(self, tmp_path):
        """The whole point of the port: hostile .meta must stay inert."""
        marker = tmp_path / "pwned"
        f = tmp_path / "evil.meta"
        f.write_text(f'BOARD_NAME="x"\nrm_marker=$(touch {marker})\n'
                     f'$(touch {marker})\n`touch {marker}`\n')
        fields = flash_registry.parse_meta(str(f))
        assert not marker.exists()
        assert fields["BOARD_NAME"] == "x"

    def test_unquoted_values_and_junk_lines(self, tmp_path):
        f = tmp_path / "b.meta"
        f.write_text("BOARD_NAME=octopus\n# comment\nnot a meta line\nARCH=\"rp2040\"\n")
        fields = flash_registry.parse_meta(str(f))
        assert fields == {"BOARD_NAME": "octopus", "ARCH": "rp2040"}


class TestListBoards:
    def test_lists_saved_board(self, tmp_path):
        boards = flash_registry.list_boards(_board(tmp_path))
        assert len(boards) == 1
        b = boards[0]
        assert b["name"] == "SHT36_Toolhead"
        assert b["arch"] == "stm32"
        assert b["flash_method"] == "can"
        assert b["config_exists"] is True

    def test_missing_config_flagged(self, tmp_path):
        boards = flash_registry.list_boards(_board(tmp_path, with_config=False))
        assert boards[0]["config_exists"] is False

    def test_empty_or_missing_registry(self, tmp_path):
        assert flash_registry.list_boards(str(tmp_path)) == []
        assert flash_registry.list_boards(str(tmp_path / "nope")) == []

    def test_defaults_for_sparse_meta(self, tmp_path):
        (tmp_path / "old.meta").write_text('BOARD_NAME="old"\n')
        b = flash_registry.list_boards(str(tmp_path))[0]
        assert b["flash_method"] == "usb" and b["arch"] == "unknown"

    def test_sorted_by_filename(self, tmp_path):
        _board(tmp_path, "zeta", VALID_META.replace("SHT36_Toolhead", "zeta"))
        _board(tmp_path, "alpha", VALID_META.replace("SHT36_Toolhead", "alpha"))
        names = [b["name"] for b in flash_registry.list_boards(str(tmp_path))]
        assert names == sorted(names)


class TestDetectDevices:
    def test_serial_listing(self, tmp_path):
        (tmp_path / "usb-Klipper_stm32-if00").touch()
        devices = flash_registry.detect_serial(str(tmp_path))
        assert devices[0]["id"] == "usb-Klipper_stm32-if00"
        assert devices[0]["path"].endswith("usb-Klipper_stm32-if00")

    def test_serial_dir_absent(self):
        assert flash_registry.detect_serial("/nonexistent/by-id") == []

    def test_can_interfaces(self, tmp_path):
        (tmp_path / "can0").mkdir()
        (tmp_path / "eth0").mkdir()
        assert flash_registry.detect_can_interfaces(str(tmp_path)) == ["can0"]

    def test_dfu_detection(self):
        proc = MagicMock()
        proc.stdout = ("Bus 001 Device 004: ID 0483:df11 STMicro STM32 BOOTLOADER\n"
                       "Bus 001 Device 002: ID 1d6b:0002 Linux Foundation hub\n")
        found = flash_registry.detect_dfu(runner=lambda *a, **k: proc)
        assert len(found) == 1 and found[0]["usb_id"] == "0483:df11"

    def test_no_lsusb_degrades(self):
        def boom(*_a, **_k):
            raise FileNotFoundError("lsusb")
        assert flash_registry.detect_dfu(runner=boom) == []


class TestCli:
    def test_json_schema(self, tmp_path, capsys):
        registry = _board(tmp_path)
        code = flash_registry.main(["--registry", registry, "--no-devices", "--json"])
        report = json.loads(capsys.readouterr().out)
        assert code == 0
        assert report["registry_dir"] == registry
        assert report["boards"][0]["name"] == "SHT36_Toolhead"
        assert "devices" not in report

    def test_devices_included_by_default(self, tmp_path, capsys):
        code = flash_registry.main(["--registry", str(tmp_path), "--json"])
        report = json.loads(capsys.readouterr().out)
        assert code == 0
        assert {"serial", "can_interfaces", "dfu"} <= set(report["devices"])
