#!/bin/bash

# katana_is_interactive() lives in core/interaction.sh, which katanaos.sh
# sources before this file. The guard is for the isolated case — tests and
# tooling that load env_check.sh on its own — so a missing primitive is a
# resolvable dependency rather than a "command not found" mid-preflight.
if ! declare -f katana_is_interactive > /dev/null 2>&1; then
    _katana_env_check_dir="${CORE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
    if [[ -f "$_katana_env_check_dir/interaction.sh" ]]; then
        # shellcheck source=core/interaction.sh
        source "$_katana_env_check_dir/interaction.sh"
    fi
    unset _katana_env_check_dir
fi


# Ensures a single command is available, installing its apt package if missing.
# Usage: check_dependency <command> [apt_package]   (package defaults to command)
# Used by the Vault (zip/unzip) and the Medic diagnostics packager.
function check_dependency() {
    local cmd="$1"
    local pkg="${2:-$1}"

    if command -v "$cmd" >/dev/null 2>&1; then
        return 0
    fi

    log_warn "Dependency '$cmd' is missing. Installing package '$pkg'..."
    if sudo apt-get install -y "$pkg" >> "$LOG_FILE" 2>&1; then
        log_success "Installed '$pkg'."
        return 0
    else
        log_error "Failed to install '$pkg'. Please install it manually: sudo apt-get install $pkg"
        return 1
    fi
}


# ==============================================================================
# STRANGLER PHASE 1 (docs/PYTHON_CORE_STRATEGY.md):
# Delegate the preflight to the Python core when it is importable.
# Contract: Python REPORTS (JSON on stdout), Bash DECIDES (install/abort).
# ==============================================================================

function katana_py_core_available() {
    PYTHONPATH="$KATANA_ROOT" python3 -c "import katana_core.env_check" 2>/dev/null
}

# STRANGLER PHASE 2: moonraker.conf validation via Python core.
# Falls back to the legacy [server]-grep when the Python core is unavailable.
function katana_moonraker_conf_valid() {
    local conf="$1"
    if katana_py_core_available; then
        PYTHONPATH="$KATANA_ROOT" python3 -m katana_core.config_check \
            --moonraker "$conf" --json >/dev/null 2>>"$LOG_FILE"
    else
        grep -q "\[server\]" "$conf" 2>/dev/null
    fi
}

function check_environment() {
    if katana_py_core_available; then
        check_environment_python
    else
        check_environment_bash
    fi
}

function check_environment_python() {
    draw_header "SYSTEM PREFLIGHT CHECK"
    log_info "Preflight via Python core (katana_core.env_check)..."

    local report rc=0
    report=$(PYTHONPATH="$KATANA_ROOT" python3 -m katana_core.env_check --json 2>>"$LOG_FILE") || rc=$?

    # rc: 0 = ready, 1 = fatal findings. Anything else / bad JSON => core broken,
    # fall back to the battle-tested Bash path.
    if [ "$rc" -gt 1 ] || ! printf '%s' "$report" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
        log_warn "Python core unavailable or invalid output. Falling back to Bash checks."
        check_environment_bash
        return $?
    fi

    # Render verdicts in the existing log style (no UI change)
    printf '%s' "$report" | python3 -c '
import json, sys
for c in json.load(sys.stdin)["checks"]:
    state = "ok" if c["ok"] else ("fatal" if c["fatal"] else "warn")
    print("%s\t%s: %s" % (state, c["name"], c["detail"]))' | \
    while IFS=$'\t' read -r state line; do
        case "$state" in
            ok)    log_success "$line" ;;
            fatal) log_error   "$line" ;;
            *)     log_warn    "$line" ;;
        esac
    done || true

    # Fatal findings -> abort (mirrors legacy Bash behavior)
    if [ "$rc" -ne 0 ]; then
        log_error "PREFLIGHT CHECK FAILED. Aborting."
        return 1
    fi

    # Non-fatal missing dependencies -> Bash installs (Python only reports)
    local missing
    missing=$(printf '%s' "$report" | python3 -c '
import json, sys
r = json.load(sys.stdin)
print(" ".join(sum((c.get("missing", []) for c in r["checks"]), [])))') || missing=""

    if [ -n "$missing" ]; then
        log_warn "Missing dependencies: $missing"
        log_info "Attempting minimal install (requires sudo)..."
        # shellcheck disable=SC2086
        if sudo apt-get update && sudo apt-get install -y $missing; then
            log_success "Dependencies installed."
        else
            log_error "Dependency installation failed. Check $LOG_FILE."
            return 1
        fi
    fi

    echo ""
    log_info "System is ready for KATANA."
    # Same reason as in check_environment_bash below: the verdict is stated,
    # not inherited from whatever cosmetic command happens to be last.
    katana_is_interactive && sleep 1
    return 0
}

# Preflight, Bash implementation.
#
# Returns 0 when the host is fit to install on, 1 when it is not. It does NOT
# call exit, and that is the whole point of this function's contract:
#
# It used to. Three `exit 1` statements sat inside it — root check, dependency
# install after a fatal finding, and the final verdict — and every one of them
# killed the process from inside a sourced module function. Both call sites
# already do the right thing with a return value (katanaos.sh aborts with its
# own message, run_headless_install returns KATANA_EXIT_STEP_FAILED), and
# neither ever got the chance: the module decided the process's fate before its
# caller could translate it into the documented exit-code contract. A headless
# run that failed preflight exited 1 by accident rather than by contract, and a
# future caller wanting to try a second profile could not, because there was no
# "after" to run in.
#
# `exit` from a module function is also what makes the function untestable:
# a test harness sourcing this file cannot assert on a preflight verdict that
# takes the test process down with it. See tests/test_headless_install.sh.
function check_environment_bash() {
    draw_header "SYSTEM PREFLIGHT CHECK"

    local fatal_error=0

    # 1. Root Check
    if [ "$EUID" -eq 0 ]; then
        log_error "Do NOT run KATANA as root. Run as regular user (e.g., pi/biqu)."
        return 1
    fi

    # 2. OS Check
    if [ -f /etc/os-release ]; then
        # Sourced in a subshell-free context on purpose (the values are needed
        # here), but the names it sets are NOT guaranteed: ID_LIKE is absent on
        # plain Debian, and under `set -u` referencing it unguarded aborts the
        # preflight on precisely the platform KATANA targets. The `${x:-}`
        # defaults are what let this run under -u at all.
        . /etc/os-release
        local os_id="${ID:-unknown}"
        local os_id_like="${ID_LIKE:-}"
        if [[ "$os_id" != "debian" && "$os_id" != "raspbian" && "$os_id_like" != *"debian"* ]]; then
            log_warn "Unsupported OS detected: $os_id. KATANA is optimized for Debian/Raspbian."
            echo "  (Continuing anyway as requested by architecture)"
        fi
    fi

    # 3. Disk Space Check (>2GB required for compilation)
    #
    # Declaration and assignment are split (SC2155): `local x=$(...)` makes the
    # exit status that of `local`, which is always 0, so a failing df was
    # invisible. The value is then range-checked before it is compared —
    # a non-numeric result (df unavailable, unexpected locale) used to make
    # `[ "$x" -lt 2 ]` itself fail, which under `set -e` aborts the step with
    # an arithmetic error instead of a readable verdict.
    local available_space
    available_space="$(df -BG / 2>/dev/null | awk 'NR==2 {print $4}' | tr -d 'G')"
    if [[ ! "$available_space" =~ ^[0-9]+$ ]]; then
        log_warn "Disk Space: could not be determined (df returned '${available_space}'). Skipping check."
    elif [ "$available_space" -lt 2 ]; then
        log_error "Insufficient Disk Space! Only ${available_space}GB free. KATANA requires >2GB."
        fatal_error=1
    else
        log_success "Disk Space: ${available_space}GB available (OK)"
    fi

    # 4. Internet Connectivity
    echo -ne "  [..] Checking Internet Connection..."
    if ping -c 1 -W 2 google.com &> /dev/null; then
        echo -e "\r${C_GREEN}  [OK] Internet Connection (OK)${C_RESET}    "
    else
        echo -e "\r${C_RED}  [!!] NO INTERNET CONNECTION${C_RESET}"
        log_error "Cannot reach google.com. Check network settings."
        fatal_error=1
    fi

    # 5. Time Synchronization Check
    # Important for SSL/APT.
    #
    # timedatectl is absent in a container and on a host without systemd, where
    # the unredirected call wrote an error to the terminal and, under `set -e`,
    # aborted the whole preflight over a check that is explicitly non-fatal.
    # ntp_status was assigned and never read; it is gone rather than silenced.
    local synced_status
    synced_status="$(timedatectl show -p NTPSynchronized --value 2>/dev/null || true)"

    if [ "$synced_status" == "yes" ]; then
        log_success "System Time: Synced (OK)"
    else
        log_warn "System Time NOT synced. This may cause SSL errors."
        # Non-fatal, just warn
    fi

    # 6. Dependencies
    local deps=("git" "curl" "wget" "python3" "virtualenv" "dfu-util" "rsync" "make" "gcc" "python3-serial" "python3-can")
    local missing=()
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        log_warn "Missing dependencies: ${missing[*]}"

        if [ $fatal_error -eq 1 ]; then
             log_error "Cannot install dependencies due to network/disk errors."
             return 1
        fi

        log_info "Attempting minimal install (requires sudo)..."

        # The two branches used to differ only in the message: both then ran a
        # bare `sudo apt-get`, so the "no passwordless sudo" path printed a
        # warning and immediately did the thing it had just warned about —
        # opening a password prompt. On an unattended run that prompt has
        # nobody to answer it and the provisioning blocks indefinitely, which
        # is the same defect class this branch is closing for `read`.
        #
        # Passwordless sudo is therefore a precondition, not a preference, and
        # its absence is reported as a refusal with the command the operator
        # can run by hand.
        if sudo -n true 2>/dev/null; then
            if ! sudo -n apt-get update || ! sudo -n apt-get install -y "${missing[@]}"; then
                log_error "Dependency installation failed. Check $LOG_FILE."
                return 1
            fi
            log_success "Dependencies installed."
        elif katana_is_interactive; then
            echo "  [!] Sudo password required for dependency installation."
            if ! sudo apt-get update || ! sudo apt-get install -y "${missing[@]}"; then
                log_error "Dependency installation failed. Check $LOG_FILE."
                return 1
            fi
            log_success "Dependencies installed."
        else
            log_error "Missing dependencies and no passwordless sudo on an unattended run."
            log_error "Install them first, then re-run:"
            log_error "  sudo apt-get update && sudo apt-get install -y ${missing[*]}"
            return 1
        fi
    else
        log_success "Core Dependencies: Installed (OK)"
    fi

    # Final Decision
    if [ $fatal_error -eq 1 ]; then
        log_error "PREFLIGHT CHECK FAILED. Aborting."
        return 1
    fi

    echo ""
    log_info "System is ready for KATANA."
    # Stated rather than inherited from `sleep`: this function's return value is
    # its entire contract and must not depend on the last cosmetic command.
    katana_is_interactive && sleep 1
    return 0
}
