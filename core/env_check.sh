#!/bin/bash

function check_environment() {
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

    # 3. Dependencies
    local deps=("git" "curl" "wget" "python3" "virtualenv" "dfu-util" "rsync")
    local missing=()
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        log_warn "Missing dependencies: ${missing[*]}"
        log_info "Attempting minimal install (requires sudo)..."
        
        # Simple check to avoid blocking prompt if sudo is not passwordless or user is not watching
        if sudo -n true 2>/dev/null; then
             sudo apt-get update && sudo apt-get install -y "${missing[@]}"
        else
             echo "  [!] Sudo password required for dependency installation."
             sudo apt-get update && sudo apt-get install -y "${missing[@]}"
        fi
    fi
}
