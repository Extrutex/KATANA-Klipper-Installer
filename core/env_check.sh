#!/bin/bash


function check_environment() {
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
        # We don't fail hard here, but warn the user
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
