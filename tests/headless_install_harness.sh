#!/bin/bash
# ==============================================================================
# KATANA — HEADLESS INSTALL HARNESS (driven by tests/test_headless_install.sh)
# ------------------------------------------------------------------------------
# Loads the real core and the real web-UI module exactly as katanaos.sh does,
# then runs the real run_headless_install against a temporary prefix.
#
# What is REAL here (this is the point of the test):
#   core/logging.sh, core/interaction.sh, core/headless.sh
#   modules/ui/install_ui.sh          — download, unzip -t, staging, swap
#   modules/system/moonraker_update_manager.sh (sourced by do_install_mainsail)
#   the step orchestration, the per-step subshell and the exit-code contract
#
# What is SUBSTITUTED, and why:
#   do_install_klipper / do_install_moonraker
#       a git clone of Klipper plus a virtualenv build needs several minutes
#       and network; the defect under test is not in them. They are replaced by
#       stubs that create their marker directories, so the orchestrator still
#       runs three steps in order and still checks three return values.
#   sudo / systemctl / apt-get / nginx
#       the test must not touch /etc, the service manager or the package
#       database of the machine it runs on. When the harness runs as root with
#       nginx present (the container job) sudo becomes a pass-through and less
#       is stubbed — see katana_install_stubs below.
#
# Argument: the mode, one of
#   ok          the fixed code path
#   prefix-bug  do_install_mainsail is restored to its pre-fix ending (a bare
#               `read -r -p`) to prove this test detects the regression
#   step-midfail
#               the klipper step is a function whose MIDDLE command fails and
#               whose remaining commands would succeed — the shape of a failed
#               git clone followed by a virtualenv build and log_success
#   step-midfail-nested
#               the same, but the failing command is the real exec_silent
#               returning 1, called as a bare statement exactly as
#               do_install_klipper calls it
#   tested-context
#               run_headless_install is invoked as `... || rc=$?`, the call
#               shape under which Bash ignores `set -e` in every step
#   step-sigint the klipper step blocks in a foreground child process, so the
#               caller can interrupt the run and check what is left behind
#
# The step-* and tested-context modes leave marker files in
# $HOME/step-markers so the caller asserts on what actually ran, not on what
# the exit code implies.
# ==============================================================================

# No `set -e`: this harness must reach its own exit statement so the caller sees
# run_headless_install's exit code and not a shell abort code. pipefail is on so
# no pipeline below can mask a producer failure.
set -uo pipefail

MODE="${1:-ok}"

: "${KATANA_ROOT:?KATANA_ROOT must be set by the caller}"
: "${LOG_FILE:?LOG_FILE must be set by the caller}"

# The whole point is a run with no human attached. If stdin is a terminal the
# test would be measuring something else, so refuse rather than pass quietly.
if [ -t 0 ]; then
    echo "HARNESS ERROR: stdin is a TTY — the caller must redirect < /dev/null" >&2
    exit 64
fi

# --- stubs for privileged tooling -------------------------------------------
katana_install_stubs() {
    if [ "$(id -u)" -eq 0 ]; then
        # Running as root (container job): no sudo needed, run the command
        # directly so nginx config writing and `nginx -t` are exercised for real.
        sudo() { "$@"; }
    else
        # Unprivileged (developer machine, GitHub runner): swallow it. Anything
        # behind sudo in this call tree writes to /etc or drives systemd.
        sudo() {
            # `sudo -n true` is a capability probe and must succeed.
            return 0
        }
    fi

    systemctl() { return 0; }
    apt-get()   { return 0; }
}
katana_install_stubs

# --- load the real thing, in katanaos.sh's order ----------------------------
# shellcheck source=/dev/null
source "$KATANA_ROOT/core/logging.sh"
# shellcheck source=/dev/null
source "$KATANA_ROOT/core/interaction.sh"
# shellcheck source=/dev/null
source "$KATANA_ROOT/core/headless.sh"
# shellcheck source=/dev/null
source "$KATANA_ROOT/modules/ui/install_ui.sh"

# --- substituted heavy steps -------------------------------------------------
# They create the directories a later post-install check looks for, so the
# orchestration is exercised end to end rather than short-circuited.
do_install_klipper() {
    log_info "[stub] klipper ($*)"
    mkdir -p "$HOME/klipper" "$HOME/klippy-env" "$HOME/printer_data/config"
    return 0
}

do_install_moonraker() {
    log_info "[stub] moonraker"
    mkdir -p "$HOME/moonraker" "$HOME/moonraker-env"
    return 0
}

# --- regression guard --------------------------------------------------------
# Restores the exact shape of the pre-fix code: work completes, then a bare
# `read` is the last command of the function and therefore its return value.
# With stdin closed that read fails and the step is reported as failed even
# though the installation succeeded. If this mode ever exits 0, the assertion
# in tests/test_headless_install.sh has stopped protecting anything.
if [ "$MODE" = "prefix-bug" ]; then
    do_install_mainsail() {
        log_info "Installing Mainsail..."
        local install_dir="$HOME/mainsail"
        if ! install_web_ui_bundle "mainsail" "$install_dir"; then
            return 1
        fi
        setup_nginx "mainsail" >/dev/null 2>&1
        log_success "Mainsail Installed."
        read -r -p "  Press Enter..."
    }
fi

# --- fail-fast guards ---------------------------------------------------------
# Each of these replaces the klipper step, which runs first, so the assertions
# can also check that the steps after it never started.
MARKERS="$HOME/step-markers"

case "$MODE" in
    step-midfail|tested-context)
        do_install_klipper() {
            mkdir -p "$MARKERS"
            : > "$MARKERS/before-failure"
            false
            : > "$MARKERS/after-failure"
            log_success "Klipper instance ready."
        }
        ;;
    step-midfail-nested)
        do_install_klipper() {
            mkdir -p "$MARKERS"
            : > "$MARKERS/before-failure"
            exec_silent "Cloning Klipper" "false"
            : > "$MARKERS/after-failure"
            log_success "Klipper instance ready."
        }
        ;;
    step-sigint)
        do_install_klipper() {
            mkdir -p "$MARKERS"
            # A foreground child, like git or pip during a real step. It
            # publishes its own PID so the caller can check it is gone.
            bash -c 'printf "%s\n" "$$" > "$1"; exec sleep 60' _ "$MARKERS/child.pid"
            : > "$MARKERS/after-interrupt"
            log_success "Klipper instance ready."
        }
        ;;
esac

if [ "$MODE" = "tested-context" ]; then
    # The call shape that used to be in katanaos.sh. Under it Bash ignores -e
    # in every step; headless_run_step has to notice and refuse.
    tested_rc=0
    run_headless_install "${KATANA_TEST_PROFILE:-standard}" \
                         "${KATANA_TEST_UI:-mainsail}" 1 0 || tested_rc=$?
    exit "$tested_rc"
fi

# A plain statement followed by `exit $?` — the same shape as main() in
# katanaos.sh, and the only one under which the per-step `set -e` is live.
run_headless_install "${KATANA_TEST_PROFILE:-standard}" \
                     "${KATANA_TEST_UI:-mainsail}" 1 0
exit $?
