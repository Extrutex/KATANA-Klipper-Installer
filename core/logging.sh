#!/bin/bash

# LOG_FILE is set by katanaos.sh. The fallback exists because the install steps
# now run under `set -u` (see core/headless.sh): an unset LOG_FILE would turn
# every log line into a fatal error and abort an otherwise healthy install.
# Logging must never be the thing that fails a provisioning run.
: "${LOG_FILE:=${KATANA_ROOT:-.}/katana.log}"

# --- COLORS ---
#
# This is the ONE palette. It used to be two: logging.sh defined seven names in
# `\033`-escape form (for `echo -e`), ui_renderer.sh defined nine more in $'...'
# form (already-expanded, for plain `echo`), and the overlap — C_PURPLE, C_GREY,
# C_RED — was defined twice with different values. Which definition won depended
# purely on source order in katanaos.sh, and every module sourced without the
# renderer (the module harness, any future headless entrypoint) referenced names
# that simply did not exist. That is what kept `set -u` off at the top level:
# an undefined C_YELLOW is a fatal error under -u, so the tool would die
# mid-render on a status line.
#
# logging.sh owns the palette because it is the lowest layer — it is sourced
# first and nothing above it is optional. ui_renderer.sh consumes these names
# instead of redefining them.
#
# All values use $'...' (expanded at definition time) rather than '\033[...'
# (expanded by `echo -e` at use time). Both forms existed side by side, which
# meant a colour worked or printed a literal "\033[38;5;46m" depending on which
# file it came from and whether the caller remembered -e. The expanded form is
# correct with both `echo` and `echo -e`, so it is the one that survives.
C_PURPLE=$'\033[38;5;93m'
C_NEON=$'\033[38;5;51m'
C_GREEN=$'\033[38;5;46m'
C_GREY=$'\033[38;5;240m'
C_WHITE=$'\033[38;5;255m'
C_RED=$'\033[38;5;196m'
C_YELLOW=$'\033[38;5;226m'
C_ORANGE=$'\033[38;5;208m'
C_RESET=$'\033[0m'

# Aliases kept because they are used across the module tree and renaming ~400
# call sites would bury the actual fix in this commit. They are aliases, not
# second definitions: each is assigned from a name above.
#   C_CYAN  — logging.sh's original name for the colour ui_renderer calls C_NEON
#   C_WARN  — logging.sh's original name for C_YELLOW
#   NC      — ui_renderer.sh's original name for C_RESET
C_CYAN="$C_NEON"
C_WARN="$C_YELLOW"
NC="$C_RESET"

# Legacy semantic names, previously defined in ui_renderer.sh.
C_TXT="$C_WHITE"
C_OK="$C_GREEN"
C_ERR="$C_RED"

# --- LOGGING FUNCTIONS ---

function log_info() {
    local msg="$1"
    echo -e "${C_CYAN}[INFO]${C_RESET} $msg"
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $msg" >> "$LOG_FILE"
}

function log_success() {
    local msg="$1"
    echo -e "${C_GREEN}[OK]${C_RESET} $msg"
    echo "[OK] $(date '+%Y-%m-%d %H:%M:%S') - $msg" >> "$LOG_FILE"
}

function log_warn() {
    local msg="$1"
    echo -e "${C_WARN}[WARN]${C_RESET} $msg"
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') - $msg" >> "$LOG_FILE"
}

function log_error() {
    local msg="$1"
    echo -e "${C_RED}[ERROR]${C_RESET} $msg"
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $msg" >> "$LOG_FILE"
}

function exec_silent() {
    local desc="$1"
    local cmd="$2"
    
    echo -ne "  [..] $desc..."
    # CAUTION: eval is used here because callers pass compound commands as strings.
    # All current callers use static strings only. Do NOT pass user-controlled input.
    if eval "$cmd" >> "$LOG_FILE" 2>&1; then
        echo -e "\r${C_GREEN}  [OK] $desc${C_RESET}    "
    else
        echo -e "\r${C_RED}  [!!] $desc FAILED${C_RESET}"
        log_error "Command failed: $cmd"
        return 1
    fi
}
