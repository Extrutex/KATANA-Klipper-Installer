# KATANA Python Core — Strangler Strategy

> Decision 2026-06-11: KATANA migrates to Python **incrementally** (strangler
> pattern), not via big-bang rewrite. Bash stays the live product throughout.
> Rationale: KIAUH v6 proved the Python end-state; KATANA's advantage is that
> it ships today. A rewrite freeze would kill the only live product.

## Principles

1. **Bash remains the entry point** (`katanaos.sh`) until the Python core
   reaches feature parity for a given module. Users never notice the migration.
2. **Migrate by pain, not by plan.** Port a module to Python only when Bash is
   the actual bottleneck there. Current pain ranking:
   1. `core/env_check.sh` — structured host/dependency probing (JSON output)
   2. moonraker.conf / printer.cfg parsing & validation (regex hell in Bash)
   3. board detection / flash registry (`modules/hardware/flash_registry.sh`)
   4. CAN bus interface management
3. **Contract: JSON over stdout.** Each Python module is a CLI
   (`python3 -m katana_core.<module> --json`) that Bash calls and parses with
   `jq`. No shared state, no sourcing, clean seam.
4. **Stdlib only** (same discipline as PrintOps): Python 3.9+ stdlib, no venv,
   no pip dependencies on the target Pi. Anything else breaks the installer
   promise ("works on a fresh Pi OS Lite").
5. **QA gate per module:** pytest suite, zero-trust input validation, explicit
   error paths, exit codes documented. A Python module replaces its Bash
   counterpart only when its tests cover the Bash module's observable behavior.

## Phases

| Phase | Deliverable | Exit criterion |
|---|---|---|
| 0 | `katana_core/` package skeleton + CI (pytest + shellcheck) | CI green on main |
| 1 | `env_check` ported, Bash delegates when Python present | identical verdicts on 3 reference hosts |
| 2 | config parser/validator (`moonraker.conf`, `printer.cfg`) | replaces v2.6 `[server]`-section check |
| 3 | flash registry + board detection | katapult flow uses Python data source |
| 4 | Python TUI (`textual`/stdlib curses) as alternative front end | menu parity for install path |
| 5 | Desktop/mobile shell (e.g. Tauri/PWA) **on top of the same core** | out of scope until Phase 4 ships |

## Non-goals (for now)

- No FastAPI/daemon mode. KATANA stays a run-and-exit tool.
- No GUI before Phase 4. The "app" wish is satisfied by the core/API split —
  the front end is swappable once the core is Python.

## History note

`backup/main-legacy-history-20260611` preserves the pre-v2.6 line (171
commits) including `rescue/hatch-provider-mode-20260603`. That rescue work is
superseded: v2.6's loader already sources optional modules conditionally.
