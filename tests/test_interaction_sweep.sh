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

    # PROBE_HOME_DIR / PROBE_FAIL_COMMANDS / PROBE_SEED_PRINTER_CFG are passed
    # through from the caller's environment when set (see the harness header);
    # empty means "not set" on the other side.
    local harness_rc=0
    env -i PATH="$PATH" TERM=dumb \
        HOME="$dir/home" \
        KATANA_NONINTERACTIVE=1 \
        KATANA_ALLOW_DESTRUCTIVE="${ALLOW:-}" \
        PROBE_CALLLOG="$P_CALLS" \
        PROBE_HOME_DIR="${PROBE_HOME_DIR:-}" \
        PROBE_FAIL_COMMANDS="${PROBE_FAIL_COMMANDS:-}" \
        PROBE_SEED_PRINTER_CFG="${PROBE_SEED_PRINTER_CFG:-1}" \
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

# PROBE_HOME_DIR, not HOME: the harness replaces HOME with a prefix of its own,
# so passing HOME here ran the three uninstalls against a throwaway directory
# and then inspected one they had never been pointed at.
for fn in uninstall_klipper uninstall_moonraker uninstall_webui; do
    env -i PATH="$PATH" TERM=dumb PROBE_HOME_DIR="$survivors/home" \
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
# Printer Config Wizard. All four generators ended in an unconditional
# `cat > printer.cfg`: on a configured printer the pin map, the PID values and
# every saved calibration were replaced by a template, with no question and no
# copy — and unattended without even the closing pause to slow it down.
#
# The assertions are on the file, before and after. A generator that returns 1
# after having written the template has refused nothing.
# ------------------------------------------------------------------------------
echo ""
echo "  ─── Printer Config Wizard (printer_config.sh) ───"

CFG_ORIGINAL='# ORIGINAL — a configured printer
[mcu]
serial: /dev/serial/by-id/usb-Klipper_stm32f446xx_REAL-if00

#*# <---------------------- SAVE_CONFIG ---------------------->
#*# [extruder]
#*# pid_kp = 26.213'

# cfg_case <name> [seed]
#   Prepares a caller-owned prefix. Sets CFG_HOME, CFG_DIR, CFG_FILE and
#   PROBE_HOME_DIR for the probes that follow. seed=0 leaves printer.cfg absent.
cfg_case() {
    CFG_HOME="$WORKROOT/cfg-$1/home"
    CFG_DIR="$CFG_HOME/printer_data/config"
    CFG_FILE="$CFG_DIR/printer.cfg"
    mkdir -p "$CFG_DIR"
    if [ "${2:-1}" != "0" ]; then
        printf '%s\n' "$CFG_ORIGINAL" > "$CFG_FILE"
    fi
    PROBE_HOME_DIR="$CFG_HOME"
}
cfg_unchanged()    { [ "$(cat "$CFG_FILE" 2>/dev/null)" = "$CFG_ORIGINAL" ]; }
cfg_backup_count() { find "$CFG_DIR" -maxdepth 1 -name 'printer.cfg.bak.*' | wc -l | tr -d ' '; }

for gen in create_ender3_printer_cfg create_voron_printer_cfg \
           create_custom_printer_cfg create_basic_printer_cfg; do
    cfg_case "refuse-$gen"
    probe "$gen"
    if [ "$P_TIMEOUT" -eq 1 ]; then
        fail "$gen: BLOCKED (killed after ${PROBE_TIMEOUT}s)"
    elif [ "$P_RC" -ne 0 ]; then
        pass "$gen: refuses to replace an existing printer.cfg unattended ($P_RC)"
    else
        fail "$gen: returned 0 on a configured printer without authorisation"
    fi
    if cfg_unchanged; then
        pass "$gen: the existing printer.cfg is byte-identical after the refusal"
    else
        fail "$gen: printer.cfg was OVERWRITTEN despite the refusal"
    fi
    if [ "$(cfg_backup_count)" -eq 0 ]; then
        pass "$gen: a refusal writes no backup"
    else
        fail "$gen: a refused overwrite left a backup file behind"
    fi
done

# create_basic_printer_cfg cannot get past its value prompts unattended (name
# and serial port have no default), so its guard is exercised on the pty below
# and by the structural check; the three template generators are driven through
# the authorised path here.
for gen in create_ender3_printer_cfg create_voron_printer_cfg create_custom_printer_cfg; do
    cfg_case "allow-$gen"
    ALLOW="overwrite" probe "$gen"
    if [ "$P_RC" -eq 0 ] && grep -q "KATANAOS Generated" "$CFG_FILE" 2>/dev/null; then
        pass "$gen: KATANA_ALLOW_DESTRUCTIVE=overwrite writes the template"
    else
        fail "$gen: authorised overwrite did not produce the template (rc=$P_RC)"
        sed 's/^/        /' "$P_OUT" | tail -6
    fi
    cfg_backup="$(find "$CFG_DIR" -maxdepth 1 -name 'printer.cfg.bak.*' | head -1)"
    if [ "$(cfg_backup_count)" -eq 1 ] && [ "$(cat "$cfg_backup")" = "$CFG_ORIGINAL" ]; then
        pass "$gen: exactly one backup next to it, holding the original content"
    else
        fail "$gen: backup missing, duplicated or not the original ($(cfg_backup_count) file(s))"
    fi
done

cfg_case "wrong-class"
ALLOW="flash,uninstall" probe create_ender3_printer_cfg
if [ "$P_RC" -ne 0 ] && cfg_unchanged; then
    pass "authorising other classes does not authorise the printer.cfg overwrite"
else
    fail "printer.cfg overwritten under KATANA_ALLOW_DESTRUCTIVE=flash,uninstall (rc=$P_RC)"
fi

# The backup is the condition the consent was given under. If it cannot be
# written, the overwrite must not happen — `cp` is replaced by the recording,
# failing stub, and its entry in the call log proves the backup was attempted
# and that its failure is what stopped the run.
cfg_case "backup-fails"
ALLOW="overwrite" PROBE_FAIL_COMMANDS="cp" probe create_voron_printer_cfg
if [ "$P_RC" -ne 0 ] && cfg_unchanged; then
    pass "a failed backup aborts the generator and leaves printer.cfg untouched"
else
    fail "printer.cfg was replaced although its backup could not be written (rc=$P_RC)"
fi
if grep -q '^cp ' "$P_CALLS" 2>/dev/null; then
    pass "the abort was caused by the backup step (cp was attempted and failed)"
else
    fail "the backup was never attempted — the generator stopped for another reason"
fi

# Two overwrites in a row, typically within the same second. The second backup
# must not land on the first one's name: the first is the only copy of the
# original configuration.
cfg_case "twice"
ALLOW="overwrite" probe create_ender3_printer_cfg
ALLOW="overwrite" probe create_voron_printer_cfg
cfg_has_original=0
while IFS= read -r cfg_backup; do
    [ "$(cat "$cfg_backup")" = "$CFG_ORIGINAL" ] && cfg_has_original=1
done < <(find "$CFG_DIR" -maxdepth 1 -name 'printer.cfg.bak.*')
if [ "$(cfg_backup_count)" -eq 2 ] && [ "$cfg_has_original" -eq 1 ]; then
    pass "a second overwrite adds a second backup and the original survives"
else
    fail "second overwrite lost a backup ($(cfg_backup_count) file(s), original kept: $cfg_has_original)"
fi

# The other side of the gate: on a host with no printer.cfg nothing is
# destroyed, so the generator must work without any authorisation.
cfg_case "fresh" 0
PROBE_SEED_PRINTER_CFG=0 probe create_ender3_printer_cfg
if [ "$P_RC" -eq 0 ] && grep -q "KATANAOS Generated" "$CFG_FILE" 2>/dev/null \
        && [ "$(cfg_backup_count)" -eq 0 ]; then
    pass "a host without printer.cfg gets one without any authorisation, and no backup"
else
    fail "fresh host: generator did not create printer.cfg cleanly (rc=$P_RC)"
    sed 's/^/        /' "$P_OUT" | tail -6
fi
unset PROBE_HOME_DIR

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

PTY_OK=0
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
        PTY_OK=1
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
# The printer.cfg overwrite with a human present. The unattended cases above
# prove the refusal; these prove the question itself: that it is asked, that
# only an explicit yes replaces the file, and that the yes leaves a backup.
# It is also the only way to reach the guard in create_basic_printer_cfg, whose
# value prompts cannot be answered without a terminal.
#
# The answers are piped into script(1), which types them into the pty; the
# harness runs WITHOUT KATANA_NONINTERACTIVE, so the prompts really read.
# ------------------------------------------------------------------------------
echo ""
echo "  ─── printer.cfg overwrite, answered on a pty ───"

# cfg_pty <case> <generator> <answers, printf %b format>
cfg_pty() {
    cfg_case "pty-$1"
    CFG_PTY_OUT="$CFG_HOME/../pty-output.txt"
    printf '%b' "$3" | env -i PATH="$PATH" TERM=dumb \
        PROBE_HOME_DIR="$CFG_HOME" PROBE_CALLLOG="$CFG_HOME/../calls.log" \
        timeout "$PROBE_TIMEOUT" script -qec "bash '$PROBE' $2" /dev/null \
        > "$CFG_PTY_OUT" 2>&1
    CFG_PTY_RC="$(tr -d '\r' < "$CFG_PTY_OUT" | sed -n "s/^.*PROBE $2 rc=\([0-9]*\).*/\1/p" | tail -1)"
    [ -n "$CFG_PTY_RC" ] || CFG_PTY_RC="none"
    unset PROBE_HOME_DIR
}

# assert_cfg_declined <label>
assert_cfg_declined() {
    if [ "$CFG_PTY_RC" = "1" ] && cfg_unchanged && [ "$(cfg_backup_count)" -eq 0 ] \
            && grep -q "ueberschreiben" "$CFG_PTY_OUT"; then
        pass "$1: asked, not confirmed, printer.cfg untouched"
    else
        fail "$1: expected a declined prompt and an untouched file (rc=$CFG_PTY_RC, backups=$(cfg_backup_count))"
    fi
}

# assert_cfg_replaced <label>
assert_cfg_replaced() {
    local backup
    backup="$(find "$CFG_DIR" -maxdepth 1 -name 'printer.cfg.bak.*' | head -1)"
    if [ "$CFG_PTY_RC" = "0" ] && grep -q "KATANAOS Generated" "$CFG_FILE" 2>/dev/null \
            && [ "$(cfg_backup_count)" -eq 1 ] && [ "$(cat "$backup")" = "$CFG_ORIGINAL" ]; then
        pass "$1: an explicit yes writes the template and keeps the original as a backup"
    else
        fail "$1: expected the template plus one backup of the original (rc=$CFG_PTY_RC, backups=$(cfg_backup_count))"
    fi
}

if [ "$PTY_OK" -eq 1 ]; then
    cfg_pty "ender3-no" create_ender3_printer_cfg 'n\n'
    assert_cfg_declined "template generator, answer 'n'"

    # [y/N]: an empty line is the default, and the default of a destructive
    # question is no.
    cfg_pty "ender3-enter" create_ender3_printer_cfg '\n'
    assert_cfg_declined "template generator, bare Enter"

    # EOF (CTRL+D) is not consent either.
    cfg_pty "ender3-eof" create_ender3_printer_cfg ''
    assert_cfg_declined "template generator, EOF"

    cfg_pty "ender3-yes" create_ender3_printer_cfg 'y\n\n'
    assert_cfg_replaced "template generator, answer 'y'"

    # name, serial port, Enter for the default baud rate, then the question.
    cfg_pty "basic-no" create_basic_printer_cfg 'myprinter\n/dev/ttyACM0\n\nn\n'
    assert_cfg_declined "basic generator, answer 'n'"

    cfg_pty "basic-yes" create_basic_printer_cfg 'myprinter\n/dev/ttyACM0\n\ny\n\n'
    assert_cfg_replaced "basic generator, answer 'y'"
else
    info "no usable pty — interactive printer.cfg cases skipped"
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

# Every write of printer.cfg in the wizard must sit directly behind the shared
# guard. The behaviour cases above cover the generators that exist; this covers
# the fifth one somebody adds next year by copying one of the four.
unguarded="$(awk '
    /printer_cfg_guard_overwrite "\$config_dir\/printer\.cfg" \|\| return 1/ { guarded_at = NR }
    /^[[:space:]]*cat > "\$config_dir\/printer\.cfg"/ {
        writes++
        if (guarded_at == 0 || NR - guarded_at > 2) print FILENAME ":" NR ": " $0
    }
    END { if (writes == 0) print FILENAME ": no printer.cfg write found — this guard is checking nothing" }
' "$REPO_ROOT/modules/system/printer_config.sh")"
if [ -z "$unguarded" ]; then
    pass "every printer.cfg write in the wizard is preceded by printer_cfg_guard_overwrite"
else
    fail "printer.cfg written without the overwrite guard:"
    printf '%s\n' "$unguarded" | sed 's/^/        /'
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
