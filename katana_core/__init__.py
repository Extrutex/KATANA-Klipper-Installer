"""KATANA Python core — strangler-pattern modules behind the Bash front end.

Contract (see docs/PYTHON_CORE_STRATEGY.md):
- stdlib only, Python 3.9+
- each module is callable as `python3 -m katana_core.<module> --json`
- JSON over stdout, diagnostics over stderr, documented exit codes
"""

__version__ = "0.1.0"
