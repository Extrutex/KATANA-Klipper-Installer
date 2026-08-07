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

OCTOPUS_TOML = '''\
id = "btt/octopus-pro"
display_name = "BIGTREETECH Octopus Pro"
mcu_family = "STM32H723"
flash_method = "katapult"
transports = ["usb", "can"]
notes = "8x TMC slots."
'''

CUSTOM_TOML = '''\
id = "windt/prototype-mcu"
display_name = "Windt Prototype MCU"
mcu_family = "RP2040"
flash_method = "katapult"
transports = ["usb"]
notes = ""
'''


def _legacy_board(tmp_path, name="SHT36_Toolhead", meta=VALID_META, with_config=True):
    tmp_path.mkdir(parents=True, exist_ok=True)
    (tmp_path / f"{name}.meta").write_text(meta)
    if with_config:
        (tmp_path / f"{name}.config").write_text("CONFIG_MACH_STM32=y\n")
    return str(tmp_path)


def _hatch_registry(tmp_path, with_device=True, with_custom=True):
    """A contract-shaped HATCH registry under tmp_path/registry."""
    root = tmp_path / "registry"
    boards = root / "boards"
    custom = boards / "custom"
    custom.mkdir(parents=True)

    selected = [{"id": "btt/octopus-pro",
                 "display_name": "BIGTREETECH Octopus Pro",
                 "added_via": "preset"}]
    (boards / "btt-octopus-pro.toml").write_text(OCTOPUS_TOML)
    if with_custom:
        selected.append({"id": "windt/prototype-mcu",
                         "display_name": "Windt Prototype MCU",
                         "added_via": "manual"})
        (custom / "windt-prototype-mcu.toml").write_text(CUSTOM_TOML)

    (root / "selected_boards.json").write_text(
        json.dumps({"schema": 1, "selected": selected}))

    devices = []
    if with_device:
        devices.append({"board_id": "btt/octopus-pro",
                        "uuid": "1a2b3c4d5e6f",
                        "transport": "can",
                        "last_flash": "2026-08-01T09:00:00Z"})
    (root / "devices.json").write_text(
        json.dumps({"schema": 1, "devices": devices}))
    return str(root)


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


class TestLegacyListBoards:
    def test_lists_saved_board(self, tmp_path):
        boards = flash_registry.list_boards(_legacy_board(tmp_path))
        assert len(boards) == 1
        b = boards[0]
        assert b["name"] == "SHT36_Toolhead"
        assert b["source"] == "legacy"
        assert b["arch"] == "stm32"
        assert b["flash_method"] == "can"
        assert b["config_exists"] is True

    def test_missing_config_flagged(self, tmp_path):
        boards = flash_registry.list_boards(_legacy_board(tmp_path, with_config=False))
        assert boards[0]["config_exists"] is False

    def test_empty_or_missing_registry(self, tmp_path):
        assert flash_registry.list_boards(str(tmp_path)) == []
        assert flash_registry.list_boards(str(tmp_path / "nope")) == []

    def test_defaults_for_sparse_meta(self, tmp_path):
        (tmp_path / "old.meta").write_text('BOARD_NAME="old"\n')
        b = flash_registry.list_boards(str(tmp_path))[0]
        assert b["flash_method"] == "usb" and b["arch"] == "unknown"

    def test_sorted_by_filename(self, tmp_path):
        _legacy_board(tmp_path, "zeta", VALID_META.replace("SHT36_Toolhead", "zeta"))
        _legacy_board(tmp_path, "alpha", VALID_META.replace("SHT36_Toolhead", "alpha"))
        names = [b["name"] for b in flash_registry.list_boards(str(tmp_path))]
        assert names == sorted(names)


class TestHatchRegistry:
    def test_id_to_filename_matches_hatch_convention(self):
        assert flash_registry.id_to_filename("btt/octopus-pro") == "btt-octopus-pro.toml"
        assert flash_registry.id_to_filename("Fysetc/Spider v2.2") == "fysetc-spider-v2-2.toml"

    def test_lists_selected_boards_with_device_link(self, tmp_path):
        root = _hatch_registry(tmp_path)
        boards = flash_registry.list_hatch_boards(root)
        assert [b["id"] for b in boards] == ["btt/octopus-pro", "windt/prototype-mcu"]

        octopus = boards[0]
        assert octopus["source"] == "hatch"
        assert octopus["name"] == "BIGTREETECH Octopus Pro"
        assert octopus["mcu_family"] == "STM32H723"
        assert octopus["flash_method"] == "katapult"
        assert octopus["transports"] == ["usb", "can"]
        assert octopus["board_toml_exists"] is True
        # UUID comes from devices.json — flash flows must reuse it, never re-detect.
        assert octopus["uuid"] == "1a2b3c4d5e6f"
        assert octopus["transport"] == "can"
        assert octopus["last_flash"] == "2026-08-01T09:00:00Z"

    def test_custom_board_resolved_from_custom_dir(self, tmp_path):
        root = _hatch_registry(tmp_path)
        custom = flash_registry.list_hatch_boards(root)[1]
        assert custom["added_via"] == "manual"
        assert custom["board_toml_exists"] is True
        assert "custom" in custom["board_toml"]
        assert custom["uuid"] == ""  # never flashed yet

    def test_missing_board_toml_flagged_not_fatal(self, tmp_path):
        root = _hatch_registry(tmp_path, with_custom=False)
        (tmp_path / "registry" / "selected_boards.json").write_text(json.dumps({
            "schema": 1,
            "selected": [{"id": "ghost/board", "display_name": "Ghost",
                          "added_via": "preset"}],
        }))
        board = flash_registry.list_hatch_boards(root)[0]
        assert board["board_toml_exists"] is False
        assert board["mcu_family"] == "unknown"

    def test_corrupt_selected_boards_reported_not_raised(self, tmp_path):
        root = _hatch_registry(tmp_path)
        (tmp_path / "registry" / "selected_boards.json").write_text("{not json")
        boards = flash_registry.list_hatch_boards(root)
        assert len(boards) == 1 and "error" in boards[0]

    def test_unknown_schema_refuses_to_guess(self, tmp_path):
        root = _hatch_registry(tmp_path)
        (tmp_path / "registry" / "selected_boards.json").write_text(
            json.dumps({"schema": 99, "selected": []}))
        boards = flash_registry.list_hatch_boards(root)
        assert len(boards) == 1 and "schema" in boards[0]["error"]


class TestSsotResolution:
    """run_all() must prefer HATCH, fall back to legacy loudly, never guess."""

    def test_hatch_registry_wins(self, tmp_path):
        root = _hatch_registry(tmp_path)
        legacy = _legacy_board(tmp_path / "legacy_dir")
        warnings = []
        report = flash_registry.run_all(registry_root=root, legacy_dir=legacy,
                                        include_devices=False,
                                        warn=warnings.append)
        assert report["source"] == "hatch"
        assert report["registry_dir"] == root
        assert warnings == []
        assert "deprecated" not in report

    def test_legacy_fallback_warns_deprecation(self, tmp_path):
        legacy = _legacy_board(tmp_path / "legacy_dir")
        empty_root = str(tmp_path / "empty_registry")
        warnings = []
        report = flash_registry.run_all(registry_root=empty_root, legacy_dir=legacy,
                                        include_devices=False,
                                        warn=warnings.append)
        assert report["source"] == "legacy"
        assert report["deprecated"] is True
        assert report["boards"][0]["name"] == "SHT36_Toolhead"
        assert len(warnings) == 1 and "DEPRECATION" in warnings[0]
        assert "hatch" in warnings[0].lower()

    def test_neither_source_yields_empty_hatch_report(self, tmp_path):
        warnings = []
        report = flash_registry.run_all(registry_root=str(tmp_path / "none"),
                                        legacy_dir=str(tmp_path / "nada"),
                                        include_devices=False,
                                        warn=warnings.append)
        assert report["source"] == "hatch"
        assert report["boards"] == []
        assert "wizard" in report["hint"]
        assert warnings == []  # nothing to deprecate, nothing guessed


class TestFlatTomlFallback:
    def test_parses_hatch_board_schema(self):
        payload = flash_registry._parse_flat_toml(OCTOPUS_TOML)
        assert payload["id"] == "btt/octopus-pro"
        assert payload["mcu_family"] == "STM32H723"
        assert payload["transports"] == ["usb", "can"]


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
    def test_json_schema_hatch_source(self, tmp_path, capsys):
        root = _hatch_registry(tmp_path)
        code = flash_registry.main(["--registry", root, "--no-devices", "--json"])
        report = json.loads(capsys.readouterr().out)
        assert code == 0
        assert report["registry_dir"] == root
        assert report["source"] == "hatch"
        assert report["boards"][0]["name"] == "BIGTREETECH Octopus Pro"
        assert "devices" not in report

    def test_json_schema_legacy_source(self, tmp_path, capsys):
        legacy = _legacy_board(tmp_path / "legacy_dir")
        code = flash_registry.main(["--registry", str(tmp_path / "empty"),
                                    "--legacy-registry", legacy,
                                    "--no-devices", "--json"])
        captured = capsys.readouterr()
        report = json.loads(captured.out)
        assert code == 0
        assert report["source"] == "legacy"
        assert report["boards"][0]["name"] == "SHT36_Toolhead"
        assert "DEPRECATION" in captured.err

    def test_devices_included_by_default(self, tmp_path, capsys):
        root = _hatch_registry(tmp_path)
        code = flash_registry.main(["--registry", root, "--json"])
        report = json.loads(capsys.readouterr().out)
        assert code == 0
        assert {"serial", "can_interfaces", "dfu"} <= set(report["devices"])
