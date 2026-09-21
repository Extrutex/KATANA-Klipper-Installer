"""Runs the headless install behaviour suite from pytest.

tests/test_headless_cli.py covers the CLI contract with ``--dry-run``, which
never executes a step. The suite wrapped here executes the real steps with
stdin closed and asserts the artefacts exist, which is the gap that let a
broken unattended install pass fifteen green tests.

The assertions live in Bash because the fixtures are shell-level (a temporary
HOME, a file:// release bundle, stubbed privileged tooling). This wrapper only
makes ``pytest -q`` a complete gate, so a developer does not have to know about
a second entry point.
"""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[1]
SUITE = REPO_ROOT / "tests" / "test_headless_install.sh"


@pytest.mark.skipif(
    not all(shutil.which(tool) for tool in ("bash", "curl", "unzip", "zip")),
    reason="needs bash, curl, unzip and zip for the release-bundle fixtures",
)
def test_unattended_install_succeeds_and_leaves_artefacts():
    result = subprocess.run(
        ["bash", str(SUITE)],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        stdin=subprocess.DEVNULL,
        timeout=300,
    )

    assert result.returncode == 0, (
        "headless install behaviour suite failed:\n"
        f"{result.stdout}\n{result.stderr}"
    )
