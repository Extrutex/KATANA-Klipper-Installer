"""Tests for katana_core.env_check — no network, no root, no dpkg required."""

import socket
import subprocess
from unittest.mock import MagicMock

import pytest

from katana_core import env_check


class TestNotRoot:
    def test_regular_user_ok(self):
        assert env_check.check_not_root(euid=1000)["ok"] is True

    def test_root_is_fatal(self):
        result = env_check.check_not_root(euid=0)
        assert result["ok"] is False and result["fatal"] is True


class TestOs:
    def test_debian_like_ok(self, tmp_path):
        f = tmp_path / "os-release"
        f.write_text('ID=raspbian\nID_LIKE="debian"\n')
        assert env_check.check_os(str(f))["ok"] is True

    def test_foreign_os_warns_not_fatal(self, tmp_path):
        f = tmp_path / "os-release"
        f.write_text("ID=fedora\n")
        result = env_check.check_os(str(f))
        assert result["ok"] is False and result["fatal"] is False

    def test_missing_file_not_fatal(self):
        result = env_check.check_os("/nonexistent/os-release")
        assert result["ok"] is False and result["fatal"] is False


class TestDiskSpace:
    def test_current_root_has_some_verdict(self):
        result = env_check.check_disk_space("/", min_gb=0.001)
        assert result["ok"] is True

    def test_impossible_requirement_is_fatal(self):
        result = env_check.check_disk_space("/", min_gb=10**9)
        assert result["ok"] is False and result["fatal"] is True

    def test_invalid_min_gb_raises(self):
        with pytest.raises(ValueError, match="positive"):
            env_check.check_disk_space("/", min_gb=0)

    def test_bad_path_is_fatal(self):
        result = env_check.check_disk_space("/nonexistent/xyz")
        assert result["ok"] is False and result["fatal"] is True


class TestConnectivity:
    def test_first_host_reachable(self):
        conn = MagicMock()
        result = env_check.check_connectivity(
            hosts=(("example.org", 443),), connector=conn)
        assert result["ok"] is True
        conn.assert_called_once()

    def test_all_hosts_down_is_fatal(self):
        def refuse(*_a, **_k):
            raise socket.timeout("timed out")
        result = env_check.check_connectivity(
            hosts=(("a", 443), ("b", 443)), connector=refuse)
        assert result["ok"] is False and result["fatal"] is True
        assert "a:443" in result["detail"] and "b:443" in result["detail"]

    def test_fallback_host_used(self):
        calls = []
        def first_fails(addr, timeout):
            calls.append(addr)
            if len(calls) == 1:
                raise OSError("unreachable")
            return MagicMock()
        result = env_check.check_connectivity(
            hosts=(("a", 443), ("b", 443)), connector=first_fails)
        assert result["ok"] is True and len(calls) == 2


class TestTimeSync:
    @staticmethod
    def _runner(stdout="", raise_exc=None):
        def run(*_a, **_k):
            if raise_exc:
                raise raise_exc
            proc = MagicMock()
            proc.stdout = stdout
            return proc
        return run

    def test_synced(self):
        result = env_check.check_time_sync(runner=self._runner("yes\n"))
        assert result["ok"] is True

    def test_unsynced_warns_not_fatal(self):
        result = env_check.check_time_sync(runner=self._runner("no\n"))
        assert result["ok"] is False and result["fatal"] is False

    def test_missing_timedatectl_not_fatal(self):
        result = env_check.check_time_sync(
            runner=self._runner(raise_exc=FileNotFoundError("timedatectl")))
        assert result["ok"] is False and result["fatal"] is False


class TestBinaries:
    def test_all_present(self):
        result = env_check.check_binaries(("git",), which=lambda _: "/usr/bin/git")
        assert result["ok"] is True and result["missing"] == []

    def test_missing_reported_not_fatal(self):
        result = env_check.check_binaries(("git", "gcc"), which=lambda _: None)
        assert result["ok"] is False and result["fatal"] is False
        assert result["missing"] == ["git", "gcc"]


class TestAptPackages:
    @staticmethod
    def _runner(returncode=0, stdout="install ok installed"):
        def run(*_a, **_k):
            proc = MagicMock()
            proc.returncode = returncode
            proc.stdout = stdout
            return proc
        return run

    def test_installed(self):
        result = env_check.check_apt_packages(("python3-serial",),
                                              runner=self._runner())
        assert result["ok"] is True

    def test_not_installed(self):
        result = env_check.check_apt_packages(
            ("python3-serial",), runner=self._runner(returncode=1, stdout=""))
        assert result["ok"] is False and result["missing"] == ["python3-serial"]

    def test_no_dpkg_degrades_gracefully(self):
        def run(*_a, **_k):
            raise FileNotFoundError("dpkg-query")
        result = env_check.check_apt_packages(("x",), runner=run)
        assert result["ok"] is False and result["fatal"] is False


class TestCli:
    def test_json_output_parses(self, capsys):
        import json
        code = env_check.main(["--json"])
        report = json.loads(capsys.readouterr().out)
        assert code in (0, 1)
        assert {c["name"] for c in report["checks"]} >= {
            "not_root", "disk_space", "connectivity"}
        assert report["ready"] == (code == 0)
