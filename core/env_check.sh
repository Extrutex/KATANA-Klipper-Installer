#!/bin/bash


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
    sleep 1
}

function check_environment_bash() {
    draw_header "SYSTEM PREFLIGHT CHECK"

    local fatal_error=0

    # 1. Root Check
    if [ "$EUID" -eq 0 ]; then
        log_error "Do NOT run KATANA as root. Run as regular user (e.g., pi/biqu)."
        exit 1
    fi

    # 2. OS Check
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" != "debian" && "$ID" != "raspbian" && "$ID_LIKE" != *"debian"* ]]; then
            log_warn "Unsupported OS detected: $ID. KATANA is optimized for Debian/Raspbian."
            echo "  (Continuing anyway as requested by architecture)"
        fi
    fi

    # 3. Disk Space Check (>2GB required for compilation)
    # Using df -h / to get available space
    local available_space=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
    if [ "$available_space" -lt 2 ]; then
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
    # Important for SSL/APT
    local ntp_status=$(timedatectl show -p NTP --value)
    local synced_status=$(timedatectl show -p NTPSynchronized --value)
    
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
             exit 1
        fi

        log_info "Attempting minimal install (requires sudo)..."
        
        # Simple check to avoid blocking prompt if sudo is not passwordless or user is not watching
        if sudo -n true 2>/dev/null; then
             sudo apt-get update && sudo apt-get install -y "${missing[@]}"
        else
             echo "  [!] Sudo password required for dependency installation."
             sudo apt-get update && sudo apt-get install -y "${missing[@]}"
        fi
    else
        log_success "Core Dependencies: Installed (OK)"
    fi

    # Final Decision
    if [ $fatal_error -eq 1 ]; then
        log_error "PREFLIGHT CHECK FAILED. Aborting."
        exit 1
    fi
    
    echo ""
    log_info "System is ready for KATANA."
    sleep 1
}
