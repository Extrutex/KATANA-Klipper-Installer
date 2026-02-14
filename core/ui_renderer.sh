# --- VISUAL ENGINE (v2.0 BETA) ---
C_PURPLE='\033[38;5;93m'
C_NEON='\033[38;5;51m'   # Cyan/Neon
C_GREEN='\033[38;5;46m'
C_GREY='\033[38;5;238m'
C_WHITE='\033[38;5;255m'
C_RED='\033[38;5;196m'
NC='\033[0m'

WIDTH=66 # Inner width excluding borders

function get_current_engine_short() {
    if [ -L "$HOME/klipper" ]; then
        local target=$(readlink "$HOME/klipper")
        if [[ "$target" == *"kalico"* ]]; then echo "KALICO"; 
        elif [[ "$target" == *"ratos"* ]]; then echo "RatOS";
        elif [[ "$target" == *"klipper"* ]]; then echo "KLIPPER";
        else echo "UNKNOWN"; fi
    else echo "NONE"; fi
}

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
                                                    v2.0 BETA 
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

# Draws a line with left/right borders and fills content with spaces up to WIDTH
# Usage: print_line "Left Content" "Right Content (Optional)" "Color Code for Left"
function print_line() {
    local left="$1"
    local right="$2"
    local color_left="${3:-$C_NEON}"
    
    # Calculate pure lengths without colors
    local len_left=${#left}
    local len_right=${#right}
    
    # Total available space for padding
    local padding=$((WIDTH - len_left - len_right - 2)) # -2 for spacing
    
    # Build the line
    # Left Border
    printf "  ${C_PURPLE}║${NC} "
    
    # Left Content
    echo -ne "${color_left}${left}${NC}"
    
    # Middle Padding
    for ((i=0; i<padding; i++)); do echo -ne " "; done
    
    # Right Content
    echo -ne " ${C_GREY}${right}${NC}"
    
    # Right Border
    echo -e " ${C_PURPLE}║${NC}"
}

function get_status_line() {
    local name="$1"
    local service="$2"
    local desc="$3"
    local active=${4:-false} # If true, check file/dir instead of service
    
    local status="OFFLINE"
    local color="$C_GREY"
    local dot="○"
    
    if [ "$active" == "true" ]; then
         # Special check for files/dirs (e.g. Kalico)
         if [ -d "$service" ]; then
             status="ONLINE "
             color="$C_GREEN"
             dot="●"
         fi
    else
        # Service check
        if systemctl is-active --quiet "$service" 2>/dev/null; then
             status="ONLINE "
             color="$C_GREEN"
             dot="●"
        fi
    fi
    
    # Manual padding to avoid printf color issues
    # Format: ● Name [12 chars] : STATUS [7 chars]    Description
    # Total inner width is 66 chars.
    # Pattern: " D Name         : STATUS   Description                "
    
    # 1. Build the status block (fixed width 25 chars)
    # "● Name        : STATUS "
    local s_block_len=25
    local name_pad=$((12 - ${#name}))
    
    printf "  ${C_PURPLE}║${NC} ${color}${dot} ${name}${NC}"
    for ((i=0; i<name_pad; i++)); do echo -ne " "; done
    echo -ne " : ${color}${status}${NC}   "
    
    # 2. Description (Flexible)
    # Remaining width: 66 - 2 (space) - 1 (dot) - 1 (space) - 12 (name) - 3 ( : ) - 7 (status) - 3 (spaces) = 37 chars?
    # Actually: 1+1+12+3+7+3 = 27 chars used.
    # 66 - 27 = 39 chars for description + spaces
    local used_len=27
    local desc_pad=$((WIDTH - used_len - ${#desc}))
    
    echo -ne "${C_WHITE}${desc}${NC}"
    for ((i=0; i<desc_pad; i++)); do echo -ne " "; done
    
    echo -e "${C_PURPLE}║${NC}"
}

function draw_top() { echo -e "  ${C_PURPLE}╔══════════════════════════════════════════════════════════════════╗${NC}"; }
function draw_mid() { echo -e "  ${C_PURPLE}╠══════════════════════════════════════════════════════════════════╣${NC}"; }
function draw_bot() { echo -e "  ${C_PURPLE}╚══════════════════════════════════════════════════════════════════╝${NC}"; }

function draw_main_menu() {
    header
    
    draw_top
    # Title Line
    printf "  ${C_PURPLE}║${NC} ${C_WHITE}SYSTEM STATUS MATRIX${NC}"
    for ((i=0; i<46; i++)); do echo -ne " "; done
    echo -e "${C_PURPLE}║${NC}"
    
    draw_mid
    get_status_line "Klipper" "klipper" "3D Printer Firmware"
    get_status_line "Kalico" "$HOME/kalico_repo" "Alternative Firmware" "true"
    get_status_line "RatOS" "$HOME/ratos_repo" "Klipper Fork (RatRig)" "true"
    get_status_line "Moonraker" "moonraker" "API Server"
    get_status_line "Mainsail" "$HOME/mainsail" "Web Interface" "true"
    get_status_line "Crowsnest" "crowsnest" "Webcam Daemon"

    draw_mid
    # Empty Line
    printf "  ${C_PURPLE}║${NC}"
    for ((i=0; i<66; i++)); do echo -ne " "; done
    echo -e "${C_PURPLE}║${NC}"
    
    # Command Deck Title
    printf "  ${C_PURPLE}║${NC} ${C_WHITE}COMMAND DECK${NC}"
    for ((i=0; i<54; i++)); do echo -ne " "; done
    echo -e "${C_PURPLE}║${NC}"
    
    draw_mid
    
    # Menu Items
    print_line "[1] AUTO-PILOT" "Full Stack Install (God Mode)"
    print_line "[2] CORE INSTALLER" "Get Klipper, Kalico or RatOS"
    print_line "[3] WEB INTERFACE" "Mainsail / Fluidd"
    print_line "[4] HMI & VISION" "Crowsnest & KlipperScreen"
    
    # Empty Line
    printf "  ${C_PURPLE}║${NC}"
    for ((i=0; i<66; i++)); do echo -ne " "; done
    echo -e "${C_PURPLE}║${NC}"
    
    print_line "[5] THE FORGE" "Flash & CAN-Bus Automator"
    
    # Active Engine (Dynamic)
    local eng=$(get_current_engine_short)
    print_line "[6] ENGINE SWITCH" "Active: $eng"
    
    # Empty Line
    printf "  ${C_PURPLE}║${NC}"
    for ((i=0; i<66; i++)); do echo -ne " "; done
    echo -e "${C_PURPLE}║${NC}"
    
    print_line "[7] UPDATE" "Update Klipper & Moonraker"
    print_line "[8] DR. KATANA" "Log Diagnostics & Repair"
    print_line "[9] KATANA FLOW" "Smart Purge & Adaptive Mesh"
    print_line "[10] SEC & BACKUP" "Firewall & Backup Vault"
    print_line "[11] BACKUP/RESTORE" "Backup & Restore"
    print_line "[12] UNINSTALL" "Remove Klipper Stack"
    print_line "[H] HARDWARE VR." "Happy Hare & Smart Probes"
    
    draw_mid
    print_line "[X] EXIT" "Close KATANAOS" "$C_RED"
    draw_bot
    echo ""
}

function draw_exit_screen() {
    clear
    echo -e "${C_PURPLE}"
    echo "  >> DISENGAGED."
    echo -e "${NC}"
}
