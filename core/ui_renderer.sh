# --- VISUAL ENGINE (PRO - LILA EDITION) ---
C_PC='\033[38;5;93m'  # Primary Purple (Lila)
C_SC='\033[38;5;201m' # Secondary Pink
C_HL='\033[38;5;51m'  # Highlight Cyan
C_OK='\033[38;5;46m'  # Success Green
C_ER='\033[38;5;196m' # Error Red
C_BG='\033[48;5;234m' # Dark BG
NC='\033[0m'

WIDTH=70

# --- HELPERS ---
function header() {
    clear
    echo -e "${C_PC}"
    cat << "EOF"
      /\      _  __    _    _____    _    _   _    _      ___    ____ 
     /  \    | |/ /   / \  |_   _|  / \  | \ | |  / \    / _ \  / ___|
     \  /    | ' /   / _ \   | |   / _ \ |  \| | / _ \  | | | | \___ \
      \/     | . \  / ___ \  | |  / ___ \| |\  |/ ___ \ | |_| |  ___) |
             |_|\_\/_/   \_\ |_| /_/   \_\_| \_/_/   \_\ \___/  |____/ 
                                                         v2.0 MASTER
EOF
    echo -e "${NC}"
}

function draw_header() {
    local title="$1"
    header
    echo -e "  ${C_HL}:: $title ::${NC}"
    echo ""
}

function status_dot() {
    local service=$1
    if systemctl is-active --quiet "$service"; then
        echo -e "${C_OK}●${NC}"
    else
        echo -e "${C_SC}○${NC}"
    fi
}

function draw_row() {
    local id="$1"
    local title="$2"
    local desc="$3"
    local status="$4"
    
    # Format: [ID] Title .......... Desc [Status]
    printf "  ${C_HL}%-3s${NC} ${C_PC}%-18s${NC} ${C_SC}%-30s${NC}" "[$id]" "$title" "$desc"
    if [ ! -z "$status" ]; then
        echo -e "$status"
    else
        echo ""
    fi
}

function draw_sep() {
    echo -e "${C_SC}  ──────────────────────────────────────────────────────────${NC}"
}

function draw_main_menu() {
    header
    
    # Fetch Statuses (Silent)
    local s_klipper=$(status_dot "klipper")
    local s_moonraker=$(status_dot "moonraker")
    local s_crowsnest=$(status_dot "crowsnest")

    echo -e "  ${C_SC}:: SYSTEM STATUS ::${NC}   Klipper: $s_klipper   Moonraker: $s_moonraker   Cam: $s_crowsnest"
    echo ""
    draw_sep
    draw_row "1" "AUTO-PILOT" "One-Click Execution (Recommended)" ""
    draw_sep
    echo ""
    echo -e "  ${C_PC}:: CORE STACK ::${NC}"
    draw_row "2" "Core Engine" "Klipper, Moonraker & Nginx" ""
    draw_row "3" "Web Interface" "Mainsail / Fluidd Dashboard" ""
    draw_row "4" "KATANA-FLOW" "Smart Park & Adaptive Purge" ""
    echo ""
    echo -e "  ${C_PC}:: HARDWARE & CONFIG ::${NC}"
    draw_row "5" "The Forge" "MCU Flashing & CAN-Bus" ""
    draw_row "6" "Engine Manager" "Switch: Klipper <-> Kalico" ""
    echo ""
    echo -e "  ${C_PC}:: MAINTENANCE ::${NC}"
    draw_row "7" "Dr. KATANA" "Log Analysis & Diagnostics" ""
    draw_row "8" "System Prep" "Update OS & Dependencies" ""
    draw_row "9" "Vault" "Security & Backup" ""
    echo ""
    draw_sep
    draw_row "X" "EXIT" "" ""
    echo ""
}


