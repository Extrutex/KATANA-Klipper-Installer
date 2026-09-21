#!/usr/bin/env bash
# ==============================================================================
# KATANA — INTERACTION BEHAVIOUR TEST (flash, CAN and destructive paths)
# ------------------------------------------------------------------------------
# tests/test_headless_install.sh covers the install path. This file covers the
# paths that a headless install never touches and that nobody could previously
# run unattended at all: the Forge (build & flash), the CAN manager, Katapult,
# and every operation that deletes something.
#
# One assertion runs through all of it. For each entry point, with stdin closed
# and no controlling terminal, the function must:
#
#     terminate                 — never block, never spin
#     AND report honestly       — 0 only if it did what it was asked
#     AND touch no hardware     — the flash tool must not have been invoked
#
# The third is the one that matters and the one an exit code cannot prove. A
# function can return 1 after erasing a board. So the harness replaces every
# command capable of writing to hardware or system state with a recording stub,
# and the tests assert the call log is empty. "Refused" means dfu-util never
# ran, not that the shell said so.
#
# ------------------------------------------------------------------------------
# WHAT THIS TEST DOES NOT COVER
#
#   * A real flash. dfu-util, make flash, flashtool.py and picotool are stubs.
#     Whether firmware actually lands on an MCU is provable only with an MCU
#     attached, and is out of reach of any CI runner. What IS proved here is
#     the complement, which is the property this branch is about: on an
#     unattended run those tools are never reached.
#
#   * The build. `make menuconfig` and `make -j` are stubbed, so compiler
#     behaviour, .config generation and artefact layout are untested. The
#     interaction around them — the pauses, the confirmations, the exit codes —
#     is what is under test.
#
#   * CAN hardware. `ip link`, candump and a live can0 are absent on a runner,
#     so the "bus is up and a board answers" branches are not exercised. The
#     branch that IS exercised is the one that matters unattended: a scan that
#     returns nothing, or returns devices that then need a human to choose
#     between.
#
#   * systemd. `systemctl` is a stub, so "the service really stopped before the
#     flash" is not verified — only that the code asked before trying.
#
#   * The interactive happy path beyond the prompt itself. A pty is used to
#     prove prompts do not block, not to drive a full session.
# ==============================================================================

# No `set -e`: this harness reports every failing case in one run and decides
# its exit code at the bottom. -u and pipefail stay on.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROBE="$REPO_ROOT/tests/interaction_probe_harness.sh"

GREEN=$'\033[0;32m'; RED=$'\033[0;31m'; YEL=$'\033[0;33m'; NC=$'\033[0m'
PASS=0; FAIL=0
pass() { echo "  ${GREEN}[PASS]${NC} $1"; PASS=$((PASS+1)); }
fail() { echo "  ${RED}[FAIL]${NC} $1"; FAIL=$((FAIL+1)); }
info() { echo "  ${YEL}[..]${NC} $1"; }

if ! command -v timeout >/dev/null 2>&1; then
    echo "  ${YEL}[SKIP]${NC} timeout(1) not available — the no-blocking assertion cannot be made."
    exit 0
fi

WORKROOT="$(mktemp -d "${TMPDIR:-/tmp}/katana-interaction-test.XXXXXX")"
trap 'rm -rf "$WORKROOT"' EXIT

# How long a function gets before it is called hung. Every function under test
# either prompts or returns; none of them does work that takes seconds once the
# external commands are stubs.
PROBE_TIMEOUT=20

# ------------------------------------------------------------------------------
# probe <function> [args...]
#   Runs one function in its own process with stdin closed and no TTY.
#   Sets: P_RC (the function's own return value), P_TIMEOUT (1 if it hung),
#         P_OUT (output file), P_CALLS (recorded hardware/system calls).
# ------------------------------------------------------------------------------
probe() {
    local fn="$1"; shift
    local dir="$WORKROOT/$fn.$$.$RANDOM"
    mkdir -p "$dir"
    P_OUT="$dir/out.txt"
    P_CALLS="$dir/calls.log"
    : > "$P_CALLS"

    local harness_rc=0
    env -i PATH="$PATH" TERM=dumb \
        HOME="$dir/home" \
        KATANA_NONINTERACTIVE=1 \
        KATANA_ALLOW_DESTRUCTIVE="${ALLOW:-}" \
        PROBE_CALLLOG="$P_CALLS" \
        timeout "$PROBE_TIMEOUT" bash "$PROBE" "$fn" "$@" \
        > "$P_OUT" 2>&1 < /dev/null
    harness_rc=$?

    if [ "$harness_rc" -eq 124 ]; then
        P_TIMEOUT=1; P_RC=124
        return 0
    fi
    P_TIMEOUT=0
    P_RC="$(sed -n "s/^PROBE $fn rc=\([0-9]*\).*/\1/p" "$P_OUT" | tail -1)"
    [ -n "$P_RC" ] || P_RC="$harness_rc"
    return 0
}

# Calls that would have WRITTEN to a board or to system state. The distinction
# matters: flashtool.py is the same binary for `-q` (enumerate the bus, a read)
# and for `-f firmware.bin` (erase and rewrite, a write), so filtering by
# command name alone would flag every scan as a flash. Only the writing forms
# count, and `systemctl is-active` / `ip link show` are reads by definition.
destructive_calls() {
    grep -E '^(dfu-util|flashtool|make flash|picotool|avrdude|stm32flash)' "$P_CALLS" 2>/dev/null \
        | grep -vE '^flashtool .*(^| )-q( |$)' \
        | grep -vE '^dfu-util (-l|--list)' || true
}

# ------------------------------------------------------------------------------
# assert_refuses <label> <function> [args...]
#   The full contract for a destructive entry point on an unattended run.
# ------------------------------------------------------------------------------
assert_refuses() {
    local label="$1" fn="$2"; shift 2
    probe "$fn" "$@"

    if [ "$P_TIMEOUT" -eq 1 ]; then
        fail "$label: BLOCKED (killed after ${PROBE_TIMEOUT}s) — a prompt is still waiting for input"
        return
    fi
    pass "$label: terminates without a terminal"

    if [ "$P_RC" -eq 0 ]; then
        fail "$label: returned 0 — reports success for work it did not do"
        sed 's/^/        /' "$P_OUT" | tail -6
    else
        pass "$label: refuses with a non-zero status ($P_RC)"
    fi

    local calls; calls="$(destructive_calls)"
    if [ -n "$calls" ]; then
        fail "$label: reached hardware despite refusing -> $(echo "$calls" | tr '\n' ';')"
    else
        pass "$label: no flash/erase command was invoked"
    fi
}

# ------------------------------------------------------------------------------
# assert_terminates <label> <function> [args...]
#   For entry points that are allowed to succeed unattended (read-only menus,
#   scanners). They must still never block and never touch hardware.
# ------------------------------------------------------------------------------
assert_terminates() {
    local label="$1" fn="$2"; shift 2
    probe "$fn" "$@"

    if [ "$P_TIMEOUT" -eq 1 ]; then
        fail "$label: BLOCKED (killed after ${PROBE_TIMEOUT}s)"
        return
    fi
    pass "$label: terminates without a terminal"

    local calls; calls="$(destructive_calls)"
    if [ -n "$calls" ]; then
        fail "$label: invoked a flash/erase command -> $(echo "$calls" | tr '\n' ';')"
    else
        pass "$label: no flash/erase command was invoked"
    fi
}

echo ""
echo "═══ INTERACTION SWEEP — FLASH, CAN & DESTRUCTIVE PATHS ═══"
echo ""
echo "  ─── The Forge (flash_engine.sh) ───"

assert_refuses  "run_build_and_flash"       run_build_and_flash
assert_refuses  "flash_via_can"             flash_via_can
assert_refuses  "save_board_config"         save_board_config
assert_refuses  "run_mcu_update_all"        run_mcu_update_all
assert_terminates "run_hal_flasher (menu)"  run_hal_flasher
assert_terminates "run_saved_boards_manager" run_saved_boards_manager
assert_terminates "run_mcu_scanner"         run_mcu_scanner

echo ""
echo "  ─── CAN bus (can_manager.sh, katapult_manager.sh) ───"

assert_refuses  "setup_can_network"           setup_can_network
assert_refuses  "install_katapult_wizard"     install_katapult_wizard
assert_refuses  "flash_via_katapult_wizard"   flash_via_katapult_wizard
assert_refuses  "flash_katapult_dfu"          flash_katapult_dfu
assert_terminates "run_can_manager (menu)"    run_can_manager
assert_terminates "run_katapult_menu (menu)"  run_katapult_menu
assert_terminates "scan_can_devices"          scan_can_devices

echo ""
echo "  ─── Uninstall & restore ───"

assert_refuses "uninstall_klipper"    uninstall_klipper
assert_refuses "uninstall_moonraker"  uninstall_moonraker
assert_refuses "uninstall_webui"      uninstall_webui
assert_refuses "uninstall_nginx"      uninstall_nginx
assert_refuses "remove_katana_files"  remove_katana_files
assert_refuses "full_uninstall"       full_uninstall
assert_refuses "restore_backup"       restore_backup
assert_refuses "disable_auto_restart" disable_auto_restart
assert_refuses "do_remove_ui"         do_remove_ui
assert_refuses "do_remove_crowsnest"  do_remove_crowsnest

# switch_core replaces ~/klipper and ~/klippy-env with symlinks, deleting
# whatever is there first. On a plain installation that is a working Klipper
# checkout, so an engine switch destroys it — and nothing on the path from the
# settings menu to the rm asked anything.
assert_refuses "switch_core (engine switch)" switch_core "kalico"

# setup_service_restart writes a systemd drop-in under /etc. Its counterpart
# disable_auto_restart is gated; gating only the teardown would imply the
# writing half is the safe one.
assert_refuses "setup_service_restart" setup_service_restart "klipper"

# ------------------------------------------------------------------------------
# The refusals above must not be an accident of "nothing is installed". These
# two run against a populated prefix and assert the files are still there
# afterwards — the only assertion that distinguishes "refused" from "deleted
# and then reported an error".
# ------------------------------------------------------------------------------
echo ""
echo "  ─── Refusal actually preserves state ───"

survivors="$WORKROOT/survivors"
mkdir -p "$survivors/home/klipper" "$survivors/home/printer_data/config" \
         "$survivors/home/moonraker" "$survivors/home/mainsail"
echo 'keep me' > "$survivors/home/printer_data/config/printer.cfg"

for fn in uninstall_klipper uninstall_moonraker uninstall_webui; do
    env -i PATH="$PATH" TERM=dumb HOME="$survivors/home" \
        KATANA_NONINTERACTIVE=1 PROBE_CALLLOG="$survivors/calls.log" \
        timeout "$PROBE_TIMEOUT" bash "$PROBE" "$fn" > /dev/null 2>&1 < /dev/null
done

missing=""
for d in klipper moonraker mainsail printer_data/config/printer.cfg; do
    [ -e "$survivors/home/$d" ] || missing="$missing $d"
done
if [ -z "$missing" ]; then
    pass "three uninstall paths refused and deleted nothing"
else
    fail "refusal deleted:$missing — the gate fires after the damage"
fi

# ------------------------------------------------------------------------------
# The explicit switch. A refusal that cannot be lifted is a broken tool, and a
# switch that lifts more than it names is a broken safety gate. Both halves are
# asserted, including that there is no blanket value.
# ------------------------------------------------------------------------------
echo ""
echo "  ─── KATANA_ALLOW_DESTRUCTIVE ───"

ALLOW="uninstall" probe uninstall_moonraker
if [ "${P_RC:-1}" -eq 0 ]; then
    pass "KATANA_ALLOW_DESTRUCTIVE=uninstall lets the named operation proceed"
else
    fail "KATANA_ALLOW_DESTRUCTIVE=uninstall did not lift the refusal (rc=$P_RC)"
fi

ALLOW="flash" probe uninstall_moonraker
if [ "${P_RC:-0}" -ne 0 ]; then
    pass "authorising 'flash' does not authorise 'uninstall'"
else
    fail "KATANA_ALLOW_DESTRUCTIVE=flash lifted an unrelated refusal"
fi

ALLOW="all" probe uninstall_moonraker
if [ "${P_RC:-0}" -ne 0 ]; then
    pass "there is no blanket value: 'all' authorises nothing"
else
    fail "'all' worked as a blanket yes — the gate can be bypassed wholesale"
fi

ALLOW="uninstalling" probe uninstall_moonraker
if [ "${P_RC:-0}" -ne 0 ]; then
    pass "matching is whole-token: 'uninstalling' does not authorise 'uninstall'"
else
    fail "substring match: 'uninstalling' authorised 'uninstall'"
fi

# ------------------------------------------------------------------------------
# The other half of the original defect: a TTY on stdin with nobody watching.
# Closed stdin makes `read` fail fast; a pty makes it block forever. Every
# primitive has to handle the second case too, and only a pty can prove it.
# ------------------------------------------------------------------------------
echo ""
echo "  ─── Prompts on a pty with nobody watching ───"

if command -v script >/dev/null 2>&1; then
    pty_probe="$WORKROOT/pty_probe.sh"
    cat > "$pty_probe" <<EOF
source "$REPO_ROOT/core/interaction.sh"
export KATANA_NONINTERACTIVE=1
[ -t 0 ] || { echo "NO_PTY"; exit 64; }
v=UNSET; katana_read_value v "  >> " 2>/dev/null; echo "VALUE_\$?_\$v"
c=UNSET; katana_read_menu  c "  >> " "T" 2>/dev/null; echo "MENU_\$?"
katana_confirm_destructive "  sure? " flash 2>/dev/null; echo "DESTRUCTIVE_\$?"
katana_confirm "  ok? " no; echo "CONFIRM_\$?"
katana_pause "  Press Enter..."; echo "PAUSE_\$?"
EOF
    pty_out="$(timeout 20 script -qec "bash $pty_probe" /dev/null 2>&1)"
    pty_rc=$?

    if [ "$pty_rc" -eq 124 ]; then
        fail "a prompt blocked on a TTY despite KATANA_NONINTERACTIVE (timed out)"
    elif printf '%s' "$pty_out" | grep -q "NO_PTY"; then
        info "script(1) did not provide a pty — TTY cases skipped"
    else
        check_pty() {
            if printf '%s' "$pty_out" | grep -q "$2"; then pass "$1"; else
                fail "$1 — got: $(printf '%s' "$pty_out" | tr -d '\r' | tr '\n' '|')"
            fi
        }
        check_pty "value prompt refuses on a TTY instead of blocking"        "VALUE_1_UNSET"
        check_pty "menu prompt refuses on a TTY instead of blocking"         "MENU_1"
        check_pty "destructive gate refuses on a TTY instead of blocking"    "DESTRUCTIVE_1"
        check_pty "yes/no falls back to its default on a TTY"                "CONFIRM_1"
        check_pty "pause returns 0 immediately on a TTY"                     "PAUSE_0"
    fi
else
    info "script(1) not available — TTY cases skipped"
fi

# ------------------------------------------------------------------------------
# Structural guard. The classes fixed on this branch can all come back the next
# time someone adds a prompt, and a behaviour test only catches it if the new
# prompt happens to sit on a path this file probes. This catches it everywhere.
# ------------------------------------------------------------------------------
echo ""
echo "  ─── Structural guards ───"

stray="$(grep -rn --include='*.sh' -E '(^|[^_[:alnum:]])read[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*-p' \
    "$REPO_ROOT/core" "$REPO_ROOT/modules" "$REPO_ROOT/katanaos.sh" 2>/dev/null \
    | grep -v '/core/interaction.sh:' \
    | grep -vE ':[0-9]+:[[:space:]]*#' || true)"
if [ -z "$stray" ]; then
    pass "no raw 'read -p' outside core/interaction.sh"
else
    fail "raw 'read -p' reintroduced:"
    printf '%s\n' "$stray" | sed 's/^/        /'
fi

# A bare `read` with the prompt in a preceding echo is the same defect wearing a
# disguise, and it is how full_uninstall's confirmation escaped the original
# inventory. `read -r line`-style data reads in pipelines are not prompts, so
# only reads with no redirection and no here-string are flagged.
stray_bare="$(grep -rn --include='*.sh' -E '^[[:space:]]*read([[:space:]]+-r)?[[:space:]]*$|^[[:space:]]*read[[:space:]]+-r?[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*$' \
    "$REPO_ROOT/core" "$REPO_ROOT/modules" "$REPO_ROOT/katanaos.sh" 2>/dev/null \
    | grep -v '/core/interaction.sh:' || true)"
if [ -z "$stray_bare" ]; then
    pass "no bare 'read' used as a hidden prompt"
else
    fail "bare 'read' used as a prompt (the full_uninstall pattern):"
    printf '%s\n' "$stray_bare" | sed 's/^/        /'
fi

# Every module must be able to call the primitives, i.e. interaction.sh must
# still be loaded before them.
if grep -q 'require_module "$CORE_DIR/interaction.sh"' "$REPO_ROOT/katanaos.sh"; then
    pass "core/interaction.sh is still loaded before the module tree"
else
    fail "core/interaction.sh is no longer loaded by katanaos.sh"
fi

# ------------------------------------------------------------------------------
echo ""
echo "  Bestanden: ${GREEN}${PASS}${NC}  |  Fehlgeschlagen: ${RED}${FAIL}${NC}"
echo ""
[ "$FAIL" -eq 0 ]
