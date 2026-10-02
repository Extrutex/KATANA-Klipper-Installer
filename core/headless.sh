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

# Names the command that aborted a step. Installed as the ERR trap of the step
# subshell (see headless_run_step); never called directly.
#
# Now that -e really is live inside a step, "step 'klipper' failed" alone is not
# a diagnosis: a bare `[ -d x ] && y` at the end of a helper aborts the step
# without printing anything. The trap fires under exactly the conditions errexit
# does, so the line it prints is the command that ended the step.
#
# Two filters keep it from reporting things that did not end the step:
#   - a command substitution inherits the trap (-E) but not -e, so a failure in
#     `x=$(...)` that the surrounding code tolerates would be reported as fatal.
#     Only failures at the step's own subshell depth are reported.
#   - an install function that ends in an explicit `return 1` has already said
#     why. The trap then fires once more for the function call itself, inside
#     headless_run_step, and that echo adds nothing.
headless_report_step_abort() {
    local status="$1" failed_command="$2" in_function="$3" line_no="$4" step_depth="$5" label="$6"
    [[ "$BASH_SUBSHELL" -eq "$step_depth" ]] || return 0
    [[ "$in_function" == "headless_run_step" ]] && return 0
    headless_err "KATANA: step '$label' aborted — '$failed_command' returned $status (${in_function:-top level}, line $line_no)."
    return 0
}

# Runs one step through the function the interactive path uses. A missing
# function is a failure, not a skip: silently installing less than was asked
# for is how a fleet ends up in two different states.
#
# The step body runs in a subshell under `set -euo pipefail`. Why a subshell
# rather than a file-level `set -e`: headless.sh is SOURCED by katanaos.sh, so a
# file-level flag would apply to the interactive menu and to all 30 legacy
# modules, where an unchecked non-zero return is routine and aborting the tool
# on one would be a regression. Scoping the strictness to the step is what makes
# it safe to switch on at all:
#
#   -e            an unchecked failing command inside an install function aborts
#                 the step instead of falling through to its closing
#                 log_success — the exact shape of the bug this branch fixes
#   -u            an unset variable fails the step instead of expanding to ""
#                 and operating on the wrong path
#   -o pipefail   a failing producer stops being masked by its consumer
#                 (`pip install ... | tail -3` hid every dependency failure)
#
# The isolation costs nothing here: a step's side effects are files, packages
# and systemd units, all of which outlive the subshell, and no install function
# returns data through shell variables. It also contains
# moonraker_update_manager.sh, which redefines log_info/log_success when
# do_install_mainsail sources it and would otherwise degrade the logging of
# every later step.
#
# CALLING CONVENTION — this function must be called as a plain statement and
# its status read from $? on the next line. Never `if headless_run_step`,
# `! headless_run_step`, `headless_run_step || ...` or `... && ...`, and the
# same holds for every caller above it, up to and including main().
#
# Why. Bash ignores -e in any command whose status is being tested, and "any
# command" includes everything that command calls: function bodies and
# subshells inherit the exemption, and a `set -e` issued inside them does not
# lift it. The first version of this function was
#
#     if ! ( set -euo pipefail; "$function_name" "$@" ); then
#
# and that -e never fired. Measured: with `f(){ false; echo CONTINUED; }` the
# line above prints CONTINUED and takes the success branch. A failed git clone
# in the middle of do_install_klipper was followed by the virtualenv, the pip
# install and log_success, and the step returned 0. Moving the subshell out of
# the `if` alone does not fix it, because `headless_run_step ... || return` in
# the caller puts this whole body back into a tested context.
#
# The alternative that works from any calling context is to background the
# subshell and `wait` for it, since an asynchronous command starts with a clean
# slate. It was rejected: without job control an async command ignores SIGINT
# and SIGQUIT and reads stdin from /dev/null, and both dispositions are
# inherited by git, pip and apt-get. CTRL+C during an install would kill the
# orchestrator and leave the running step and its children behind as orphans,
# still writing to the host. Undoing that means re-arming the signals inside the
# child, forwarding them from the parent and re-attaching stdin — three
# mechanisms to get back what a foreground subshell has for free: it stays in
# the terminal's foreground process group, so the signal reaches the step and
# every child directly.
#
# So the step stays in the foreground, and the convention it depends on is
# enforced rather than documented and hoped for. Before the step runs, a canary
# subshell executes `set -e; false; exit 0` under the same conditions. It can
# only exit 0 if -e was ignored — which means this function was called from a
# tested context and the real step would run without fail-fast. In that case
# nothing is executed and the step is reported as failed: an install that
# cannot be checked does not start.
#
# What -e covers, stated exactly, because the same rule applies one level down:
# every command the step function runs as a statement, and every function it
# calls as a statement, recursively. A function the install code itself calls
# under `if`/`!`/`||`/`&&` (setup_nginx, install_service_from_template) runs
# with -e ignored by the same Bash rule; its failure is caught by the condition
# that tests it, not by errexit.
headless_run_step() {
    local label="$1" function_name="$2"
    shift 2
    headless_log "── $label ──"
    if ! declare -f "$function_name" > /dev/null; then
        headless_err "KATANA: step '$label' unavailable — function $function_name not loaded."
        return 1
    fi

    # The two subshells below fail on purpose (the canary) or may fail (the
    # step), as plain statements. A caller that itself runs under -e would be
    # terminated by either before the status could be read and reported, so -e
    # is suspended for this function and restored on every way out.
    local caller_errexit=0
    case "$-" in *e*) caller_errexit=1 ;; esac
    set +e

    local canary_status=0
    ( set -e; false; exit 0 )
    canary_status=$?
    if [[ "$canary_status" -eq 0 ]]; then
        headless_err "KATANA: step '$label' not started — headless_run_step was called from a"
        headless_err "        tested context (if / ! / || / &&), where Bash ignores 'set -e'."
        headless_err "        This is a bug in the caller, see the calling convention in core/headless.sh."
        if [[ "$caller_errexit" -eq 1 ]]; then set -e; fi
        return 1
    fi

    local step_status=0
    (
        # -E on top of the documented three: it makes the ERR trap below visible
        # inside the install functions, which is where the failures are.
        set -Eeuo pipefail
        step_depth="$BASH_SUBSHELL"
        trap 'headless_report_step_abort "$?" "$BASH_COMMAND" "${FUNCNAME[0]:-}" "$LINENO" "$step_depth" "$label"' ERR
        "$function_name" "$@"
    )
    step_status=$?
    if [[ "$caller_errexit" -eq 1 ]]; then set -e; fi

    if [[ "$step_status" -ne 0 ]]; then
        headless_err "KATANA: step '$label' failed."
        return 1
    fi
    return 0
}

run_headless_install() {
    local profile="${1:-standard}" ui="${2:-mainsail}" confirmed="${3:-0}" dry_run="${4:-0}"

    # Every prompt below this line is answered by its documented default, and
    # every pause is skipped. Set before validation so even an early return
    # cannot reach a blocking read. See core/interaction.sh for why a TTY test
    # alone is not sufficient: `install --yes` started from a terminal keeps a
    # TTY on stdin and would otherwise wait for a keypress nobody will make.
    export KATANA_NONINTERACTIVE=1

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
    # One call site for every step, and it is a plain statement: see the
    # calling convention on headless_run_step. The `case` only selects what to
    # run. Writing the call once is what keeps a later edit from reintroducing
    # `headless_run_step ... || return` in one arm and silently switching
    # fail-fast off for that step.
    local component step_label step_function step_status
    local -a step_arguments
    for component in $components; do
        step_arguments=()
        case "$component" in
            klipper)
                step_label="klipper"
                step_function="do_install_klipper"
                step_arguments=("Standard") ;;
            moonraker)
                step_label="moonraker"
                step_function="do_install_moonraker" ;;
            ui)
                case "$ui" in
                    none)     continue ;;
                    fluidd)   step_label="fluidd";   step_function="do_install_fluidd" ;;
                    mainsail) step_label="mainsail"; step_function="do_install_mainsail" ;;
                    *)        headless_err "KATANA: unknown UI '$ui' (mainsail|fluidd|none)."
                              return $KATANA_EXIT_USAGE ;;
                esac ;;
            *)
                headless_err "KATANA: profile '$profile' names an unknown component '$component'."
                return $KATANA_EXIT_STEP_FAILED ;;
        esac

        # ${a[@]+"${a[@]}"} rather than "${a[@]}": expanding an empty array is
        # an unbound-variable error under -u before Bash 4.4, and a step without
        # arguments must receive none — not one empty string.
        headless_run_step "$step_label" "$step_function" ${step_arguments[@]+"${step_arguments[@]}"}
        step_status=$?
        if [[ "$step_status" -ne 0 ]]; then
            return $KATANA_EXIT_STEP_FAILED
        fi
    done

    headless_log "KATANA headless install complete."
    declare -f post_install_verify > /dev/null && post_install_verify
    return $KATANA_EXIT_OK
}
