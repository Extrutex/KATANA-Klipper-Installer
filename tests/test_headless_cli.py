"""Tests for the unattended install path (``katanaos.sh install``).

Driven through the real script with ``--dry-run``, which is what makes them
runnable on a developer machine: the dry run reads nothing, writes nothing and
needs no root, so the CLI contract — flags, plan, exit codes — is checkable
without a Raspberry Pi.

The contract these pin down matters more than usual: an unattended installer is
called by another script, and a script can only react to an exit code. A run
that fails must not exit 0, and a flag that was not understood must not be
silently ignored.
"""

from __future__ import annotations

import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPT = REPO_ROOT / "katanaos.sh"

EXIT_OK = 0
EXIT_STEP_FAILED = 1
EXIT_USAGE = 2
EXIT_UNCONFIRMED = 3


def run(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["bash", str(SCRIPT), *args],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        timeout=60,
    )


class TestPlan:
    def test_the_standard_profile_plans_klipper_moonraker_and_a_ui(self):
        result = run("install", "--profile", "standard", "--dry-run")

        assert result.returncode == EXIT_OK
        assert "1. klipper" in result.stdout
        assert "2. moonraker" in result.stdout
        assert "3. mainsail" in result.stdout

    def test_the_minimal_profile_plans_no_ui(self):
        result = run("install", "--profile", "minimal", "--dry-run")

        assert result.returncode == EXIT_OK
        assert "moonraker" in result.stdout
        assert "mainsail" not in result.stdout
        assert "fluidd" not in result.stdout

    def test_ui_none_drops_the_ui_step_from_a_profile_that_has_one(self):
        result = run("install", "--profile", "standard", "--ui", "none", "--dry-run")

        assert result.returncode == EXIT_OK
        assert "mainsail" not in result.stdout
        assert "2. moonraker" in result.stdout

    def test_fluidd_replaces_mainsail_rather_than_joining_it(self):
        result = run("install", "--profile", "standard", "--ui", "fluidd", "--dry-run")

        assert result.returncode == EXIT_OK
        assert "fluidd" in result.stdout
        assert "mainsail" not in result.stdout

    def test_a_dry_run_installs_nothing(self):
        """The plan must be printed without any step being executed."""
        result = run("install", "--profile", "power", "--dry-run")

        assert result.returncode == EXIT_OK
        assert "plan" in result.stdout.lower()
        for marker in ("── klipper ──", "── moonraker ──", "complete"):
            assert marker not in result.stdout


class TestExitCodes:
    def test_an_unattended_run_without_yes_is_refused(self):
        """Nobody is at the terminal, so consent has to be in the command line."""
        result = run("install", "--profile", "standard")

        assert result.returncode == EXIT_UNCONFIRMED
        assert "--yes" in result.stderr

    def test_an_unknown_flag_fails_instead_of_being_ignored(self):
        result = run("install", "--profil", "standard")

        assert result.returncode == EXIT_USAGE
        assert "--profil" in result.stderr

    def test_an_unknown_profile_is_refused(self):
        result = run("install", "--profile", "turbo", "--dry-run")

        assert result.returncode == EXIT_USAGE

    def test_an_unknown_ui_is_refused(self):
        result = run("install", "--ui", "octoprint", "--dry-run")

        assert result.returncode == EXIT_USAGE

    def test_profile_without_a_value_is_a_usage_error(self):
        result = run("install", "--profile")

        assert result.returncode == EXIT_USAGE


class TestArgumentParsing:
    def test_every_argument_is_read_not_only_the_first(self):
        """Regression: handle_args inspected $1 alone, so --help was dropped."""
        result = run("--profile", "power", "--help")

        assert result.returncode == EXIT_OK
        assert "Usage" in result.stdout

    def test_flags_may_come_in_any_order(self):
        ordered = run("install", "--profile", "minimal", "--dry-run")
        shuffled = run("install", "--dry-run", "--profile", "minimal")

        assert ordered.returncode == shuffled.returncode == EXIT_OK
        assert ordered.stdout == shuffled.stdout

    def test_version_still_works(self):
        result = run("--version")

        assert result.returncode == EXIT_OK
        assert "KATANAOS" in result.stdout

    def test_help_documents_the_headless_contract(self):
        """The exit codes are the API; an undocumented API is not usable."""
        result = run("--help")

        assert result.returncode == EXIT_OK
        for expected in ("install", "--dry-run", "--yes", "Exit-Codes"):
            assert expected in result.stdout


@pytest.mark.parametrize("profile", ["minimal", "standard", "power"])
def test_every_documented_profile_produces_a_plan(profile: str):
    result = run("install", "--profile", profile, "--dry-run")

    assert result.returncode == EXIT_OK
    assert "1. klipper" in result.stdout
