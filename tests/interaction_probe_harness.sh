#!/usr/bin/env bash
# ==============================================================================
# KATANA — INTERACTION PROBE HARNESS
# ------------------------------------------------------------------------------
# Loads the full module chain into a throwaway prefix and calls ONE function,
# then prints a single machine-readable line:
#
#     PROBE <function> rc=<exit code>
#
# Invoked by tests/test_interaction_sweep.sh, once per function, under
# `timeout`. It is a separate file because each probe must run in its own
# process: the functions under test call `return` at depths the caller cannot
# unwind, several of them `cd`, and a hang in one must not take the suite down
# with it.
#
# Usage:  interaction_probe_harness.sh <function> [args...]
#
# Environment the caller is expected to set:
#   KATANA_NONINTERACTIVE   1 for the unattended case, unset for the pty case
#   KATANA_ALLOW_DESTRUCTIVE  operation allow-list, when testing the switch
#   PROBE_CALLLOG           file the command stubs append to
#
# Optional, for tests that assert on what is on disk AFTER the function ran:
#   PROBE_HOME_DIR          use this directory as the prefix instead of a
#                           throwaway one, and leave it in place on exit. Files
#                           the caller put there are not overwritten by the
#                           seeding below. Setting HOME has no such effect —
#                           this harness always replaces it.
#   PROBE_SEED_PRINTER_CFG  0 to leave the prefix without a printer.cfg (the
#                           freshly imaged host); anything else seeds one
#   PROBE_FAIL_COMMANDS     space-separated extra commands to replace with the
#                           recording, failing stub (e.g. "cp", to prove that a
#                           failed backup stops the overwrite it was meant to
#                           protect)
# ==============================================================================

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export KATANA_ROOT="$REPO_ROOT"
export CORE_DIR="$REPO_ROOT/core"
export MODULES_DIR="$REPO_ROOT/modules"
export CONFIGS_DIR="$REPO_ROOT/configs"
export KATANA_VERSION="probe"
export INSTALL_PROFILE="standard"
export TERM="${TERM:-dumb}"

# A prefix that is not the developer's home. Everything the functions under
# test touch below $HOME lands here and dies with the process.
if [[ -n "${PROBE_HOME_DIR:-}" ]]; then
    # Caller-owned prefix: created if needed, never removed here. The caller
    # inspects it afterwards and cleans it up with its own trap.
    PROBE_HOME="$PROBE_HOME_DIR"
    mkdir -p "$PROBE_HOME" || { echo "PROBE load-error PROBE_HOME_DIR"; exit 90; }
else
    PROBE_HOME="$(mktemp -d "${TMPDIR:-/tmp}/katana-probe.XXXXXX")" \
        || { echo "PROBE load-error mktemp"; exit 90; }
    trap 'rm -rf "$PROBE_HOME"' EXIT
fi
export HOME="$PROBE_HOME"
export LOG_FILE="$PROBE_HOME/katana.log"

# Minimal plausible installation, so the functions reach their prompt instead
# of returning early on "Klipper is not installed".
mkdir -p "$PROBE_HOME/klipper/out" \
         "$PROBE_HOME/printer_data/config" \
         "$PROBE_HOME/katapult/scripts" \
         "$PROBE_HOME/printer_data/config/katana_boards"
: > "$PROBE_HOME/klipper/out/klipper.bin"
: > "$PROBE_HOME/klipper/out/klipper.uf2"
: > "$PROBE_HOME/klipper/.config"
# Only when absent: a caller-owned prefix may carry a printer.cfg whose content
# the test asserts on afterwards.
if [[ "${PROBE_SEED_PRINTER_CFG:-1}" != "0" && ! -e "$PROBE_HOME/printer_data/config/printer.cfg" ]]; then
    printf '[printer]\nkinematics: none\n' > "$PROBE_HOME/printer_data/config/printer.cfg"
fi

# A saved board, for the registry-driven paths.
cat > "$PROBE_HOME/printer_data/config/katana_boards/probe_board.meta" <<'META'
BOARD_NAME="probe_board"
ARCH="stm32"
FLASH_METHOD="usb"
LAST_BUILT="1970-01-01"
META
: > "$PROBE_HOME/printer_data/config/katana_boards/probe_board.config"

# A backup archive, so restore_backup reaches its RESTORE confirmation instead
# of returning early on "no backups found". The file only has to exist and be
# listed; the gate fires before anything reads it.
mkdir -p "$PROBE_HOME/katana_backups"
: > "$PROBE_HOME/katana_backups/katana_backup_19700101_000000.zip"

# An alternative engine repo, so switch_core gets past its "target repo not
# found" check and reaches the confirmation that guards the rm -rf.
mkdir -p "$PROBE_HOME/kalico_repo" "$PROBE_HOME/kalico_env"

# ------------------------------------------------------------------------------
# Command stubs.
#
# The assertion this suite is built on is not "the function returned 1" — a
# function can return 1 after already erasing a board. It is "the flash tool was
# never invoked". So every command capable of writing to hardware, to system
# state or to the network is replaced by a stub that records the call and fails.
#
# Recording AND failing is deliberate: if a refusal ever regresses, the test
# sees both the call log entry and a non-zero result, and the log says which
# tool would have run.
# ------------------------------------------------------------------------------
STUBDIR="$PROBE_HOME/.stubs"
mkdir -p "$STUBDIR"
: "${PROBE_CALLLOG:=$PROBE_HOME/calls.log}"
export PROBE_CALLLOG
: > "$PROBE_CALLLOG"

# PROBE_FAIL_COMMANDS is word-split on purpose: it is a list of command names.
# shellcheck disable=SC2086
for cmd in dfu-util make sudo systemctl apt-get git picotool avrdude \
           stm32flash ip ifup ifdown modprobe curl wget dpkg \
           ${PROBE_FAIL_COMMANDS:-}; do
    cat > "$STUBDIR/$cmd" <<STUB
#!/usr/bin/env bash
printf '%s %s\n' "$cmd" "\$*" >> "\$PROBE_CALLLOG"
exit 87
STUB
    chmod +x "$STUBDIR/$cmd"
done

# python3 is needed for real (the Python core and the meta parser use it), so it
# is wrapped rather than stubbed: only flashtool.py / flash_can.py invocations
# are intercepted, everything else is passed through.
REAL_PYTHON3="$(command -v python3 || true)"
cat > "$STUBDIR/python3" <<STUB
#!/usr/bin/env bash
for arg in "\$@"; do
    case "\$arg" in
        *flashtool.py|*flash_can.py)
            printf 'flashtool %s\n' "\$*" >> "\$PROBE_CALLLOG"
            exit 87
            ;;
    esac
done
exec "$REAL_PYTHON3" "\$@"
STUB
chmod +x "$STUBDIR/python3"

export PATH="$STUBDIR:$PATH"

# ------------------------------------------------------------------------------
# Load the chain in katanaos.sh's order.
# ------------------------------------------------------------------------------
for m in core/logging.sh core/interaction.sh core/ui_renderer.sh core/env_check.sh \
         core/engine_manager.sh core/dispatchers.sh core/headless.sh \
         core/service_manager.sh; do
    # shellcheck disable=SC1090
    source "$REPO_ROOT/$m" || { echo "PROBE load-error $m"; exit 90; }
done
for m in "$REPO_ROOT"/modules/*/*.sh; do
    # shellcheck disable=SC1090
    source "$m" 2>/dev/null || true
done

FN="${1:?function name required}"
shift || true

if ! declare -f "$FN" > /dev/null; then
    echo "PROBE $FN rc=91 (not defined)"
    exit 91
fi

rc=0
"$FN" "$@" || rc=$?
echo "PROBE $FN rc=$rc"
exit 0
