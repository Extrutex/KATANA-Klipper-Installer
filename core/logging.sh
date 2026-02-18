#!/bin/bash

# --- COLORS ---
C_PURPLE='\033[38;5;93m'
C_CYAN='\033[38;5;51m'
C_GREEN='\033[38;5;46m'
C_RED='\033[38;5;196m'
C_WARN='\033[38;5;226m'
C_GREY='\033[38;5;238m'
C_RESET='\033[0m'

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
