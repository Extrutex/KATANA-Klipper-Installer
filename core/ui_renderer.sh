# --- VISUAL ENGINE (v1.5 NEON RESTORED) ---
C_PURPLE='\033[38;5;93m'
C_NEON='\033[38;5;51m'   # Cyan/Neon
C_GREEN='\033[38;5;46m'
C_GREY='\033[38;5;238m'
C_WHITE='\033[38;5;255m'
C_RED='\033[38;5;196m'
NC='\033[0m'

WIDTH=68

# --- HELPERS ---
function header() {
    clear
    echo -e "${C_PURPLE}"
    cat << "EOF"
      /\      _  __    _    _____    _    _   _    _      ___    ____ 
     /  \    | |/ /   / \  |_   _|  / \  | \ | |  / \    / _ \  / ___|
     \  /    | ' /   / _ \   | |   / _ \ |  \| | / _ \  | | | | \___ \
      \/     | . \  / ___ \  | |  / ___ \| |\  |/ ___ \ | |_| |  ___) |
             |_|\_\/_/   \_\ |_| /_/   \_\_| \_/_/   \_\ \___/  |____/ 
                                                    v1.5 NEON
EOF
    echo -e "      ${C_NEON}>> SYSTEM OVERLORD // COMMAND INTERFACE${NC}"
    echo ""
}

function draw_header() {
    local title="$1"
    header
    echo -e "  ${C_NEON}:: $title ::${NC}"
    echo ""
}

function get_status_line() {
    local name="$1"
    local service="$2"
    local desc="$3"
    local active=${4:-false} # If true, check file/dir instead of service
    
    local status="${C_GREY}OFFLINE${NC}"
    local dot="${C_GREY}○${NC}"
    
    if [ "$active" == "true" ]; then
         # Special check for files/dirs (e.g. Kalico)
         if [ -d "$service" ]; then
             status="${C_GREEN}ONLINE ${NC}"
             dot="${C_GREEN}●${NC}"
         fi
    else
        # Service check
        if systemctl is-active --quiet "$service"; then
            status="${C_GREEN}ONLINE ${NC}"
            dot="${C_GREEN}●${NC}"
        fi
    fi
    
    # Format:  ● Name    : ONLINE    Description
    printf "  ${C_PURPLE}║${NC} %b %-12s : %b   %-28s ${C_PURPLE}║${NC}\n" "$dot" "$name" "$status" "$desc"
}

function draw_top() { echo -e "${C_PURPLE}╔══════════════════════════════════════════════════════════════════╗${NC}"; }
function draw_mid() { echo -e "${C_PURPLE}╠══════════════════════════════════════════════════════════════════╣${NC}"; }
function draw_bot() { echo -e "${C_PURPLE}╚══════════════════════════════════════════════════════════════════╝${NC}"; }

function draw_main_menu() {
    header
    
    draw_top
    echo -e "  ${C_PURPLE}║${NC} ${C_WHITE}SYSTEM STATUS MATRIX${NC}                                         ${C_PURPLE}║${NC}"
    draw_mid
    get_status_line "Klipper" "klipper" "3D Printer Firmware"
    get_status_line "Kalico" "$HOME/kalico_repo" "Alternative Firmware" "true"
    get_status_line "Moonraker" "moonraker" "API Server"
    get_status_line "Mainsail" "$HOME/mainsail" "Web Interface" "true"
    get_status_line "Crowsnest" "crowsnest" "Webcam Daemon"

    draw_mid
    echo -e "  ${C_PURPLE}║${NC}                                                                  ${C_PURPLE}║${NC}"
    echo -e "  ${C_PURPLE}║${NC} ${C_WHITE}COMMAND DECK${NC}                                                 ${C_PURPLE}║${NC}"
    draw_mid
    
    # Menu Items
    # Format: [ID] NAME     Description
    printf "  ${C_PURPLE}║${NC} ${C_NEON}[1] AUTO-PILOT${NC}       ${C_GREY}Full Stack Install (God Mode)${NC}      ${C_PURPLE}║${NC}\n"
    printf "  ${C_PURPLE}║${NC} ${C_NEON}[2] CORE ENGINE${NC}      ${C_GREY}Klipper, Moonraker & Nginx${NC}         ${C_PURPLE}║${NC}\n"
    printf "  ${C_PURPLE}║${NC} ${C_NEON}[3] WEB INTERFACE${NC}    ${C_GREY}Mainsail / Fluidd${NC}                  ${C_PURPLE}║${NC}\n"
    printf "  ${C_PURPLE}║${NC} ${C_NEON}[4] HMI & VISION${NC}     ${C_GREY}Crowsnest & KlipperScreen${NC}          ${C_PURPLE}║${NC}\n"
    echo -e "  ${C_PURPLE}║${NC}                                                                  ${C_PURPLE}║${NC}"
    printf "  ${C_PURPLE}║${NC} ${C_NEON}[5] THE FORGE${NC}        ${C_GREY}Flash & CAN-Bus Automator${NC}          ${C_PURPLE}║${NC}\n"
    printf "  ${C_PURPLE}║${NC} ${C_NEON}[6] ENGINE MGR${NC}       ${C_GREY}Klipper <-> Kalico Switch${NC}          ${C_PURPLE}║${NC}\n"
    echo -e "  ${C_PURPLE}║${NC}                                                                  ${C_PURPLE}║${NC}"
    printf "  ${C_PURPLE}║${NC} ${C_NEON}[7] DR. KATANA${NC}       ${C_GREY}Log Diagnostics & Repair${NC}           ${C_PURPLE}║${NC}\n"
    printf "  ${C_PURPLE}║${NC} ${C_NEON}[8] SYSTEM PREP${NC}      ${C_GREY}Updates & Dependencies${NC}             ${C_PURPLE}║${NC}\n"
    printf "  ${C_PURPLE}║${NC} ${C_NEON}[9] SEC & BACKUP${NC}     ${C_GREY}Firewall & Backup Vault${NC}            ${C_PURPLE}║${NC}\n"
    draw_mid
    printf "  ${C_PURPLE}║${NC} ${C_RED}[X] EXIT${NC}             ${C_GREY}Close KATANAOS${NC}                     ${C_PURPLE}║${NC}\n"
    draw_bot
    echo ""
}


