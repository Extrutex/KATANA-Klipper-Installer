#!/bin/bash
# --- KATANA HEADLESS INSTALL ---
#
# Non-interactive provisioning: one command, no menu, no prompt, an exit code
# that a script can branch on.
#
# Why this exists. KATANA's whole claim against KIAUH is fleet provisioning,
# and neither tool could do it: KIAUH has carried "Make a headless mode"
# (issue #594) open for years, and KATANA had a menu and three flags. A shop
# with eight printers reimages a host by hand either way. This closes it on
# our side, and it is the one differentiator that is checkable from a CI job.
#
# The install steps themselves are NOT reimplemented here. do_install_klipper,
# do_install_moonraker and do_install_mainsail/fluidd are the same functions
# the interactive Auto-Pilot calls. This file only decides what runs, in what
# order, and what happens when a step fails — a second install path would
# drift from the first within a release.
#
# Contract:
#   katanaos.sh install --profile <p> [--ui mainsail|fluidd|none] [--yes]
#                       [--dry-run]
#   0  everything requested succeeded
#   1  a step failed (the failing step is named on stderr)
#   2  the invocation itself was wrong (unknown flag, missing value)
#   3  refused: --yes missing on a run that changes the system

# Exit codes, named so callers and tests agree on them.
readonly KATANA_EXIT_OK=0
readonly KATANA_EXIT_STEP_FAILED=1
readonly KATANA_EXIT_USAGE=2
readonly KATANA_EXIT_UNCONFIRMED=3

# Which components each profile provisions. Kept here as data rather than as
# branches so a new profile is one line, and so --dry-run can print the plan
# without executing any part of it.
headless_components_for() {
    case "$1" in
        minimal)  echo "klipper moonraker" ;;
        standard) echo "klipper moonraker ui" ;;
        power)    echo "klipper moonraker ui" ;;
        *)        return 1 ;;
    esac
}

headless_log() { printf '%s\n' "$*"; }
headless_err() { printf '%s\n' "$*" >&2; }

# Prints the plan a run would execute. Reads nothing, writes nothing, needs no
# root — which is what makes the CLI testable off the target hardware.
headless_print_plan() {
    local profile="$1" ui="$2"
    local components
    components="$(headless_components_for "$profile")" || return 1

    headless_log "KATANA headless plan"
    headless_log "  profile: $profile"
    # A profile without a ui component ignores --ui entirely. Echoing the
    # requested value anyway would promise a web interface the run never
    # installs — the plan has to say what will happen, not what was typed.
    if [[ "$components" == *ui* && "$ui" != "none" ]]; then
        headless_log "  ui:      $ui"
    elif [[ "$components" == *ui* ]]; then
        headless_log "  ui:      keine (--ui none)"
    else
        headless_log "  ui:      keine (Profil $profile enthaelt keine UI)"
    fi
    headless_log "  steps:"
    local step=0
    local component
    for component in $components; do
        [[ "$component" == "ui" && "$ui" == "none" ]] && continue
        step=$((step + 1))
        case "$component" in
            klipper)   headless_log "    $step. klipper" ;;
            moonraker) headless_log "    $step. moonraker" ;;
            ui)        headless_log "    $step. $ui" ;;
        esac
    done
    [[ $step -eq 0 ]] && headless_log "    (nothing to do)"
    return 0
}

# Runs one step through the function the interactive path uses. A missing
# function is a failure, not a skip: silently installing less than was asked
# for is how a fleet ends up in two different states.
headless_run_step() {
    local label="$1" function_name="$2"
    shift 2
    headless_log "── $label ──"
    if ! declare -f "$function_name" > /dev/null; then
        headless_err "KATANA: step '$label' unavailable — function $function_name not loaded."
        return 1
    fi
    if ! "$function_name" "$@"; then
        headless_err "KATANA: step '$label' failed."
        return 1
    fi
    return 0
}

run_headless_install() {
    local profile="${1:-standard}" ui="${2:-mainsail}" confirmed="${3:-0}" dry_run="${4:-0}"

    if ! headless_components_for "$profile" > /dev/null; then
        headless_err "KATANA: unknown profile '$profile' (minimal|standard|power)."
        return $KATANA_EXIT_USAGE
    fi
    case "$ui" in
        mainsail|fluidd|none) ;;
        *) headless_err "KATANA: unknown UI '$ui' (mainsail|fluidd|none)."
           return $KATANA_EXIT_USAGE ;;
    esac

    if [[ "$dry_run" == "1" ]]; then
        headless_print_plan "$profile" "$ui"
        return $KATANA_EXIT_OK
    fi

    # An unattended run installs system packages and enables services. It does
    # that only when the caller said so in the command line — there is nobody
    # at the terminal to ask.
    if [[ "$confirmed" != "1" ]]; then
        headless_err "KATANA: refusing to install unattended without --yes."
        headless_err "        Preview the plan first: katanaos.sh install --profile $profile --dry-run"
        return $KATANA_EXIT_UNCONFIRMED
    fi

    if declare -f check_environment > /dev/null && ! check_environment; then
        headless_err "KATANA: environment check failed."
        return $KATANA_EXIT_STEP_FAILED
    fi

    headless_log "KATANA headless install — profile $profile, ui $ui"
    local components
    components="$(headless_components_for "$profile")"
    local component
    for component in $components; do
        case "$component" in
            klipper)
                headless_run_step "klipper" do_install_klipper "Standard" \
                    || return $KATANA_EXIT_STEP_FAILED ;;
            moonraker)
                headless_run_step "moonraker" do_install_moonraker \
                    || return $KATANA_EXIT_STEP_FAILED ;;
            ui)
                [[ "$ui" == "none" ]] && continue
                if [[ "$ui" == "fluidd" ]]; then
                    headless_run_step "fluidd" do_install_fluidd \
                        || return $KATANA_EXIT_STEP_FAILED
                else
                    headless_run_step "mainsail" do_install_mainsail \
                        || return $KATANA_EXIT_STEP_FAILED
                fi ;;
        esac
    done

    headless_log "KATANA headless install complete."
    declare -f post_install_verify > /dev/null && post_install_verify
    return $KATANA_EXIT_OK
}
