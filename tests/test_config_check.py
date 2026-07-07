"""Tests for katana_core.config_check — tmp_path fixtures only, no host deps."""

import json

import pytest

from katana_core import config_check

VALID_MOONRAKER = """\
[server]
host = 0.0.0.0
port = 7125
klippy_uds_address = /tmp/klippy.sock

[authorization]
trusted_clients =
    127.0.0.1
    192.168.0.0/16
"""

VALID_PRINTER = """\
[mcu]
serial: /dev/serial/by-id/usb-Klipper_stm32f446xx_ABC-if00

[stepper_x]
step_pin: PA2
dir_pin: !PA1

[printer]
kinematics: corexy
max_velocity: 300
max_accel: 3000

[gcode_macro START_PRINT]
gcode:
    M117 Heating 50%
    G28 ; home all
"""


def _write(tmp_path, name, content):
    f = tmp_path / name
    f.write_text(content)
    return str(f)


def _by_name(findings, name):
    return [f for f in findings if f["name"] == name]


class TestMoonrakerConf:
    def test_valid_conf_passes(self, tmp_path):
        findings = config_check.check_moonraker_conf(
            _write(tmp_path, "moonraker.conf", VALID_MOONRAKER))
        assert not any(f["fatal"] for f in findings)
        assert _by_name(findings, "server_section")[0]["ok"] is True

    def test_missing_server_section_fatal(self, tmp_path):
        findings = config_check.check_moonraker_conf(
            _write(tmp_path, "moonraker.conf", "[authorization]\ntrusted_clients = 127.0.0.1\n"))
        server = _by_name(findings, "server_section")[0]
        assert server["ok"] is False and server["fatal"] is True

    def test_unreadable_file_fatal(self):
        findings = config_check.check_moonraker_conf("/nonexistent/moonraker.conf")
        assert findings[0]["fatal"] is True

    def test_bad_port_fatal(self, tmp_path):
        findings = config_check.check_moonraker_conf(
            _write(tmp_path, "m.conf", "[server]\nport = klipper\n"))
        port = _by_name(findings, "server_port")[0]
        assert port["ok"] is False and port["fatal"] is True

    def test_port_out_of_range_fatal(self, tmp_path):
        findings = config_check.check_moonraker_conf(
            _write(tmp_path, "m.conf", "[server]\nport = 99999\n"))
        assert _by_name(findings, "server_port")[0]["fatal"] is True

    def test_duplicate_section_fatal(self, tmp_path):
        findings = config_check.check_moonraker_conf(
            _write(tmp_path, "m.conf", "[server]\nport = 7125\n[server]\nport = 7126\n"))
        assert findings[0]["fatal"] is True
        assert "duplicate" in findings[0]["detail"]

    def test_missing_authorization_warns_not_fatal(self, tmp_path):
        findings = config_check.check_moonraker_conf(
            _write(tmp_path, "m.conf", "[server]\nport = 7125\n"))
        auth = _by_name(findings, "authorization")[0]
        assert auth["ok"] is False and auth["fatal"] is False

    def test_missing_uds_dir_warns_not_fatal(self, tmp_path):
        findings = config_check.check_moonraker_conf(_write(
            tmp_path, "m.conf",
            "[server]\nport = 7125\nklippy_uds_address = /nonexistent/dir/klippy.sock\n"))
        uds = _by_name(findings, "klippy_uds")[0]
        assert uds["ok"] is False and uds["fatal"] is False


class TestPrinterCfg:
    def test_valid_cfg_passes(self, tmp_path):
        findings = config_check.check_printer_cfg(
            _write(tmp_path, "printer.cfg", VALID_PRINTER))
        assert not any(f["fatal"] for f in findings)

    def test_missing_printer_section_fatal(self, tmp_path):
        findings = config_check.check_printer_cfg(
            _write(tmp_path, "p.cfg", "[mcu]\nserial: /dev/x\n"))
        assert _by_name(findings, "printer_section")[0]["fatal"] is True

    def test_missing_mcu_fatal(self, tmp_path):
        findings = config_check.check_printer_cfg(_write(
            tmp_path, "p.cfg",
            "[printer]\nkinematics: cartesian\nmax_velocity: 300\nmax_accel: 3000\n"))
        assert _by_name(findings, "mcu")[0]["fatal"] is True

    def test_katana_placeholder_serial_warns(self, tmp_path):
        cfg = VALID_PRINTER.replace(
            "/dev/serial/by-id/usb-Klipper_stm32f446xx_ABC-if00",
            "/dev/serial/by-id/change-me")
        findings = config_check.check_printer_cfg(_write(tmp_path, "p.cfg", cfg))
        mcu = _by_name(findings, "mcu")[0]
        assert mcu["ok"] is False and mcu["fatal"] is False
        assert "placeholder" in mcu["detail"]

    def test_unknown_kinematics_warns_not_fatal(self, tmp_path):
        cfg = VALID_PRINTER.replace("kinematics: corexy", "kinematics: corexz2000")
        findings = config_check.check_printer_cfg(_write(tmp_path, "p.cfg", cfg))
        kin = _by_name(findings, "kinematics")[0]
        assert kin["ok"] is False and kin["fatal"] is False

    def test_bad_max_velocity_fatal(self, tmp_path):
        cfg = VALID_PRINTER.replace("max_velocity: 300", "max_velocity: fast")
        findings = config_check.check_printer_cfg(_write(tmp_path, "p.cfg", cfg))
        assert _by_name(findings, "max_velocity")[0]["fatal"] is True

    def test_negative_max_accel_fatal(self, tmp_path):
        cfg = VALID_PRINTER.replace("max_accel: 3000", "max_accel: -5")
        findings = config_check.check_printer_cfg(_write(tmp_path, "p.cfg", cfg))
        assert _by_name(findings, "max_accel")[0]["fatal"] is True

    def test_none_kinematics_skips_limits(self, tmp_path):
        findings = config_check.check_printer_cfg(_write(
            tmp_path, "p.cfg", "[mcu]\nserial: /dev/x\n[printer]\nkinematics: none\n"))
        assert not _by_name(findings, "max_velocity")
        assert not any(f["fatal"] for f in findings)

    def test_missing_include_fatal(self, tmp_path):
        cfg = "[include macros.cfg]\n" + VALID_PRINTER
        findings = config_check.check_printer_cfg(_write(tmp_path, "p.cfg", cfg))
        inc = _by_name(findings, "include")[0]
        assert inc["fatal"] is True and "macros.cfg" in inc["detail"]

    def test_present_include_resolves(self, tmp_path):
        (tmp_path / "macros.cfg").write_text("[gcode_macro M600]\ngcode:\n    PAUSE\n")
        cfg = "[include macros.cfg]\n" + VALID_PRINTER
        findings = config_check.check_printer_cfg(_write(tmp_path, "p.cfg", cfg))
        assert _by_name(findings, "include")[0]["ok"] is True

    def test_wildcard_include_no_match_warns_not_fatal(self, tmp_path):
        cfg = "[include conf.d/*.cfg]\n" + VALID_PRINTER
        findings = config_check.check_printer_cfg(_write(tmp_path, "p.cfg", cfg))
        inc = _by_name(findings, "include")[0]
        assert inc["ok"] is False and inc["fatal"] is False

    def test_duplicate_section_fatal(self, tmp_path):
        findings = config_check.check_printer_cfg(_write(
            tmp_path, "p.cfg", "[mcu]\nserial: /dev/x\n[mcu]\nserial: /dev/y\n"))
        assert findings[0]["fatal"] is True

    def test_no_steppers_warns_not_fatal(self, tmp_path):
        findings = config_check.check_printer_cfg(_write(
            tmp_path, "p.cfg",
            "[mcu]\nserial: /dev/x\n[printer]\nkinematics: cartesian\n"
            "max_velocity: 300\nmax_accel: 3000\n"))
        steppers = _by_name(findings, "steppers")[0]
        assert steppers["ok"] is False and steppers["fatal"] is False

    def test_gcode_macro_percent_and_jinja_parse(self, tmp_path):
        cfg = VALID_PRINTER + (
            "\n[gcode_macro PARK]\ngcode:\n"
            "    {% set pos = printer.toolhead.position %}\n"
            "    M117 Parked at {pos.x}\n")
        findings = config_check.check_printer_cfg(_write(tmp_path, "p.cfg", cfg))
        assert findings[0]["ok"] is True  # syntax


class TestCli:
    def test_json_schema_and_exit_code(self, tmp_path, capsys):
        m = _write(tmp_path, "moonraker.conf", VALID_MOONRAKER)
        p = _write(tmp_path, "printer.cfg", VALID_PRINTER)
        code = config_check.main(["--moonraker", m, "--printer", p, "--json"])
        report = json.loads(capsys.readouterr().out)
        assert code == 0 and report["ready"] is True
        assert report["fatal_checks"] == []
        assert {c["name"] for c in report["checks"]} >= {
            "moonraker_syntax", "server_section", "printer_syntax", "mcu"}

    def test_broken_conf_exits_1(self, tmp_path, capsys):
        m = _write(tmp_path, "moonraker.conf", "[file_manager]\n")
        code = config_check.main(["--moonraker", m, "--json"])
        report = json.loads(capsys.readouterr().out)
        assert code == 1 and report["ready"] is False
        assert "server_section" in report["fatal_checks"]

    def test_no_args_is_invocation_error(self):
        with pytest.raises(SystemExit) as exc:
            config_check.main([])
        assert exc.value.code == 2
