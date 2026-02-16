# ============================================================
# KATANAOS VISUAL ENGINE v2.2
# ============================================================

# Colors
C_PURPLE='\033[38;5;93m'
C_NEON='\033[38;5;51m'
C_GREEN='\033[38;5;46m'
C_GREY='\033[38;5;240m'
C_WHITE='\033[38;5;255m'
C_RED='\033[38;5;196m'
C_YELLOW='\033[38;5;226m'
C_BLUE='\033[38;5;33m'
C_ORANGE='\033[38;5;208m'
NC='\033[0m'

# Box dimensions
BOX_WIDTH=70
INDENT="  "

# ============================================================
# BOX DRAWING FUNCTIONS
# ============================================================

function draw_box_top() {
    echo -e "${INDENT}${C_PURPLE}┌${C_PURPLE}$(printf '─%.0s' $(seq 1 $BOX_WIDTH))${C_PURPLE}┐${NC}"
}

function draw_box_mid() {
    echo -e "${INDENT}${C_PURPLE}├${C_PURPLE}$(printf '─%.0s' $(seq 1 $BOX_WIDTH))${C_PURPLE}┤${NC}"
}

function draw_box_bot() {
    echo -e "${INDENT}${C_PURPLE}└${C_PURPLE}$(printf '─%.0s' $(seq 1 $BOX_WIDTH))${C_PURPLE}┘${NC}"
}

function draw_sub_top() {
    echo -e "${INDENT}${C_BLUE}┌${C_BLUE}$(printf '─%.0s' $(seq 1 $BOX_WIDTH))${C_BLUE}┐${NC}"
}

function draw_sub_mid() {
    echo -e "${INDENT}${C_BLUE}├${C_BLUE}$(printf '─%.0s' $(seq 1 $BOX_WIDTH))${C_BLUE}┤${NC}"
}

function draw_sub_bot() {
    echo -e "${INDENT}${C_BLUE}└${C_BLUE}$(printf '─%.0s' $(seq 1 $BOX_WIDTH))${C_BLUE}┘${NC}"
}

function draw_warn_top() {
    echo -e "${INDENT}${C_ORANGE}┌${C_ORANGE}$(printf '─%.0s' $(seq 1 $BOX_WIDTH))${C_ORANGE}┐${NC}"
}

function draw_warn_mid() {
    echo -e "${INDENT}${C_ORANGE}├${C_ORANGE}$(printf '─%.0s' $(seq 1 $BOX_WIDTH))${C_ORANGE}┤${NC}"
}

function draw_warn_bot() {
    echo -e "${INDENT}${C_ORANGE}└${C_ORANGE}$(printf '─%.0s' $(seq 1 $BOX_WIDTH))${C_ORANGE}┘${NC}"
}

# ============================================================
# LINE DRAWING FUNCTIONS
# ============================================================

function box_row() {
    local content="$1"
    local len=${#content}
    local padding=$((BOX_WIDTH - len))
    echo -e "${INDENT}${C_PURPLE}│${NC} ${content}$(printf ' %.0s' $(seq 1 $padding)) ${C_PURPLE}│${NC}"
}

function box_row_left() {
    local content="$1"
    local len=${#content}
    local padding=$((BOX_WIDTH - len))
    echo -e "${INDENT}${C_PURPLE}│${NC}${content}$(printf ' %.0s' $(seq 1 $padding))${C_PURPLE}│${NC}"
}

function box_row_center() {
    local content="$1"
    local len=${#content}
    local left_pad=$(( (BOX_WIDTH - len) / 2 ))
    local right_pad=$((BOX_WIDTH - len - left_pad))
    echo -e "${INDENT}${C_PURPLE}│${NC}$(printf ' %.0s' $(seq 1 $left_pad))${content}$(printf ' %.0s' $(seq 1 $right_pad))${C_PURPLE}│${NC}"
}

function sub_row() {
    local content="$1"
    local len=${#content}
    local padding=$((BOX_WIDTH - len))
    echo -e "${INDENT}${C_BLUE}│${NC} ${content}$(printf ' %.0s' $(seq 1 $padding)) ${C_BLUE}│${NC}"
}

function warn_row() {
    local content="$1"
    local len=${#content}
    local padding=$((BOX_WIDTH - len))
    echo -e "${INDENT}${C_ORANGE}│${NC} ${content}$(printf ' %.0s' $(seq 1 $padding)) ${C_ORANGE}│${NC}"
}

# ============================================================
# STATUS FUNCTIONS
# ============================================================

function get_current_engine_short() {
    if [ -L "$HOME/klipper" ]; then
        local target=$(readlink "$HOME/klipper")
        if [[ "$target" == *"kalico"* ]]; then echo "KALICO"; 
        elif [[ "$target" == *"ratos"* ]]; then echo "RatOS";
        elif [[ "$target" == *"klipper"* ]]; then echo "KLIPPER";
        else echo "UNKNOWN"; fi
    else echo "NONE"; fi
}

function check_service_status() {
    local service="$1"
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo "ONLINE"
    else
        echo "OFFLINE"
    fi
}

function check_dir_status() {
    local dir="$1"
    if [ -d "$dir" ]; then
        echo "INSTALLED"
    else
        echo "NOT INSTALLED"
    fi
}

function check_katanaflow_status() {
    if [ -d "$HOME/printer_data/config/katana_flow" ]; then
        echo "INSTALLED"
    else
        echo "NOT INSTALLED"
    fi
}

function check_shaketune_status() {
    if [ -d "$HOME/klippain_shaketune" ]; then
        echo "INSTALLED"
    else
        echo "NOT INSTALLED"
    fi
}

function check_octoprint_status() {
    if [ -d "$HOME/OctoPrint" ]; then
        echo "INSTALLED"
    else
        echo "NOT INSTALLED"
    fi
}

function check_log2ram_status() {
    if dpkg -s log2ram >/dev/null 2>&1; then
        echo "INSTALLED"
    else
        echo "NOT INSTALLED"
    fi
}

function check_stealthchanger_status() {
    if [ -d "$HOME/printer_data/config/stealthchanger" ]; then
        echo "INSTALLED"
    else
        echo "NOT INSTALLED"
    fi
}

function check_madmax_status() {
    if [ -d "$HOME/printer_data/config/madmax" ]; then
        echo "INSTALLED"
    else
        echo "NOT INSTALLED"
    fi
}

function check_cartographer_status() {
    if [ -d "$HOME/printer_data/config/cartographer" ]; then
        echo "INSTALLED"
    else
        echo "NOT INSTALLED"
    fi
}

function check_beacon_status() {
    if [ -d "$HOME/printer_data/config/beacon" ]; then
        echo "INSTALLED"
    else
        echo "NOT INSTALLED"
    fi
}

function check_btt_eddy_status() {
    if [ -d "$HOME/printer_data/config/btt_eddy" ]; then
        echo "INSTALLED"
    else
        echo "NOT INSTALLED"
    fi
}

# ============================================================
# HEADER
# ============================================================

function draw_header_main() {
    clear
    echo -e "${C_PURPLE}"
    cat << "EOF"
      /\      _  __    _    _____    _    _   _    _      ___    ____ 
     /  \    | |/ /   / \  |_   _|  / \  | \ | |  / \    / _ \  / ___|
     \  /    | ' /   / _ \   | |   / _ \ |  \| | / _ \  | | | | \___ \
      \/     | . \  / ___ \  | |  / ___ \| |\  |/ ___ \ | |_| |  ___) |
             |_|\_\/_/   \_\ |_| /_/   \_\_| \_/_/   \_\ \___/  |____/ 
EOF
    echo -e "                                                    ${C_YELLOW}v2.2${C_PURPLE}"
    echo -e "      ${C_NEON}>> KATANAOS // SYSTEM COMMAND INTERFACE${NC}"
    echo ""
}

function draw_header() {
    local title="$1"
    draw_header_main
    local title_len=${#title}
    local pad=$(( (BOX_WIDTH - title_len) / 2 ))
    box_row_center "${C_NEON}::$title ::${NC}"
    echo ""
}

# ============================================================
# MAIN MENU
# ============================================================

function draw_main_menu() {
    draw_header_main
    
    # === SYSTEM STATUS ===
    draw_box_top
    box_row "${C_WHITE}SYSTEM STATUS${NC}"
    draw_box_mid
    
    local klipper_status=$(check_service_status "klipper")
    local moonraker_status=$(check_service_status "moonraker")
    
    if [ "$klipper_status" = "ONLINE" ]; then
        box_row "${C_GREEN}●${NC} Klipper       : ${C_GREEN}ONLINE ${NC}   3D Printer Firmware"
    else
        box_row "${C_GREY}○${NC} Klipper       : ${C_GREY}OFFLINE${NC}   3D Printer Firmware"
    fi
    
    if [ "$moonraker_status" = "ONLINE" ]; then
        box_row "${C_GREEN}●${NC} Moonraker     : ${C_GREEN}ONLINE ${NC}   API Server"
    else
        box_row "${C_GREY}○${NC} Moonraker     : ${C_GREY}OFFLINE${NC}   API Server"
    fi
    
    # === WEB INTERFACES ===
    draw_sub_top
    sub_row "${C_BLUE}>> WEB INTERFACES${NC}"
    draw_sub_mid
    
    local mainsail_status=$(check_dir_status "$HOME/mainsail")
    local fluidd_status=$(check_dir_status "$HOME/fluidd")
    
    if [ "$mainsail_status" = "INSTALLED" ]; then
        box_row "${C_GREEN}●${NC} Mainsail      : ${C_GREEN}INSTALLED${NC}"
    else
        box_row "${C_GREY}○${NC} Mainsail      : ${C_GREY}NOT INSTALLED${NC}"
    fi
    
    if [ "$fluidd_status" = "INSTALLED" ]; then
        box_row "${C_GREEN}●${NC} Fluidd        : ${C_GREEN}INSTALLED${NC}"
    else
        box_row "${C_GREY}○${NC} Fluidd        : ${C_GREY}NOT INSTALLED${NC}"
    fi
    
    # === HARDWARE & EXTRAS ===
    draw_sub_mid
    sub_row "${C_BLUE}>> HARDWARE & EXTRAS${NC}"
    draw_sub_mid
    
    local crowsnest_status=$(check_dir_status "$HOME/crowsnest")
    local klipperscreen_status=$(check_dir_status "$HOME/KlipperScreen")
    local happuhare_status=$(check_dir_status "$HOME/happy_hare")
    local smartprobe_status=$(check_dir_status "$HOME/smart_probe")
    local stealthchanger_status=$(check_stealthchanger_status)
    local madmax_status=$(check_madmax_status)
    local cartographer_status=$(check_cartographer_status)
    local beacon_status=$(check_beacon_status)
    local btt_eddy_status=$(check_btt_eddy_status)
    local katanaflow_status=$(check_katanaflow_status)
    local shaketune_status=$(check_shaketune_status)
    local octoprint_status=$(check_octoprint_status)
    local log2ram_status=$(check_log2ram_status)
    
    if [ "$crowsnest_status" = "INSTALLED" ]; then
        box_row "${C_GREEN}●${NC} Crowsnest     : ${C_GREEN}INSTALLED${NC}"
    else
        box_row "${C_GREY}○${NC} Crowsnest     : ${C_GREY}NOT INSTALLED${NC}"
    fi
    
    if [ "$klipperscreen_status" = "INSTALLED" ]; then
        box_row "${C_GREEN}●${NC} KlipperScreen : ${C_GREEN}INSTALLED${NC}"
    else
        box_row "${C_GREY}○${NC} KlipperScreen : ${C_GREY}NOT INSTALLED${NC}"
    fi
    
    if [ "$happuhare_status" = "INSTALLED" ]; then
        box_row "${C_GREEN}●${NC} Happy Hare    : ${C_GREEN}INSTALLED${NC}"
    else
        box_row "${C_GREY}○${NC} Happy Hare    : ${C_GREY}NOT INSTALLED${NC}"
    fi
    
    if [ "$smartprobe_status" = "INSTALLED" ]; then
        box_row "${C_GREEN}●${NC} Smart Probe   : ${C_GREEN}INSTALLED${NC}"
    else
        box_row "${C_GREY}○${NC} Smart Probe   : ${C_GREY}NOT INSTALLED${NC}"
    fi
    
    if [ "$katanaflow_status" = "INSTALLED" ]; then
        box_row "${C_GREEN}●${NC} Katana Flow   : ${C_GREEN}INSTALLED${NC}"
    else
        box_row "${C_GREY}○${NC} Katana Flow   : ${C_GREY}NOT INSTALLED${NC}"
    fi
    
    if [ "$shaketune_status" = "INSTALLED" ]; then
        box_row "${C_GREEN}●${NC} ShakeTune     : ${C_GREEN}INSTALLED${NC}"
    else
        box_row "${C_GREY}○${NC} ShakeTune     : ${C_GREY}NOT INSTALLED${NC}"
    fi
    
    if [ "$stealthchanger_status" = "INSTALLED" ]; then
        box_row "${C_GREEN}●${NC} StealthChangr: ${C_GREEN}INSTALLED${NC}"
    else
        box_row "${C_GREY}○${NC} StealthChangr: ${C_GREY}NOT INSTALLED${NC}"
    fi
    
    if [ "$madmax_status" = "INSTALLED" ]; then
        box_row "${C_GREEN}●${NC} MADMAX        : ${C_GREEN}INSTALLED${NC}"
    else
        box_row "${C_GREY}○${NC} MADMAX        : ${C_GREY}NOT INSTALLED${NC}"
    fi
    
    if [ "$cartographer_status" = "INSTALLED" ]; then
        box_row "${C_GREEN}●${NC} Cartographer  : ${C_GREEN}INSTALLED${NC}"
    else
        box_row "${C_GREY}○${NC} Cartographer  : ${C_GREY}NOT INSTALLED${NC}"
    fi
    
    if [ "$beacon_status" = "INSTALLED" ]; then
        box_row "${C_GREEN}●${NC} Beacon Probe  : ${C_GREEN}INSTALLED${NC}"
    else
        box_row "${C_GREY}○${NC} Beacon Probe  : ${C_GREY}NOT INSTALLED${NC}"
    fi
    
    if [ "$btt_eddy_status" = "INSTALLED" ]; then
        box_row "${C_GREEN}●${NC} BTT Eddy      : ${C_GREEN}INSTALLED${NC}"
    else
        box_row "${C_GREY}○${NC} BTT Eddy      : ${C_GREY}NOT INSTALLED${NC}"
    fi
    
    if [ "$octoprint_status" = "INSTALLED" ]; then
        box_row "${C_GREEN}●${NC} OctoPrint     : ${C_GREEN}INSTALLED${NC}"
    else
        box_row "${C_GREY}○${NC} OctoPrint     : ${C_GREY}NOT INSTALLED${NC}"
    fi
    
    if [ "$log2ram_status" = "INSTALLED" ]; then
        box_row "${C_GREEN}●${NC} Log2Ram       : ${C_GREEN}INSTALLED${NC}"
    else
        box_row "${C_GREY}○${NC} Log2Ram       : ${C_GREY}NOT INSTALLED${NC}"
    fi
    
    # === COMMAND DECK ===
    draw_box_mid
    box_row "${C_WHITE}⚡ INSTALLER${NC}"
    draw_box_mid
    box_row "${C_GREEN}[1]${NC} Full Install       Klipper + Moonraker + UI"
    box_row "${C_NEON}[2]${NC} Core Firmware       Klipper / Kalico / RatOS"
    box_row "${C_NEON}[3]${NC} Web UI              Mainsail / Fluidd"
    box_row "${C_NEON}[4]${NC} Vision Stack        Crowsnest / KlipperScreen"
    box_row "${C_NEON}[5]${NC} The Forge         MCU Flash / CAN-Bus / Katapult"
    
    draw_box_mid
    box_row "${C_WHITE}🔧 SYSTEM${NC}"
    draw_box_mid
    local engine=$(get_current_engine_short)
    box_row "${C_NEON}[6]${NC} Engine Switch     Current: ${C_YELLOW}$engine${NC}"
    box_row "${C_NEON}[7]${NC} Update            Klipper & Moonraker"
    box_row "${C_NEON}[8]${NC} Diagnostics       Log Analysis & Repair"
    
    draw_box_mid
    box_row "${C_WHITE}🧩 EXTRAS${NC}"
    draw_box_mid
    box_row "${C_NEON}[9]${NC} KATANA-FLOW       Smart Purge & ShakeTune"
    box_row "${C_NEON}[10]${NC} Hardware          Toolchanger / Probes"
    
    draw_box_mid
    box_row "${C_WHITE}🔒 MANAGEMENT${NC}"
    draw_box_mid
    box_row "${C_NEON}[11]${NC} Security          Firewall / SSH Hardening"
    box_row "${C_NEON}[12]${NC} Backup            Backup & Restore"
    box_row "${C_NEON}[13]${NC} Uninstall         Remove Klipper Stack"
    box_row "${C_NEON}[14]${NC} Printer Config    Create printer.cfg"
    box_row "${C_NEON}[15]${NC} Auto-Restart     Service Health Watch"
    
    draw_box_mid
    box_row "${C_RED}[X]${NC} Exit              Close KATANAOS"
    draw_box_bot
    echo ""
}

# ============================================================
# EXIT SCREEN
# ============================================================

function draw_exit_screen() {
    clear
    draw_warn_top
    warn_row " "
    warn_row "${C_YELLOW}>> KATANAOS DISENGAGED.${NC}"
    warn_row " "
    draw_warn_bot
    echo ""
}

# ============================================================
# PROGRESS / LOADING
# ============================================================

function draw_loading() {
    local message="$1"
    draw_box_top
    box_row_center "${C_YELLOW}>> ${message}${NC}"
    draw_box_mid
    box_row " "
    box_row " ${C_NEON}Please wait...${NC}"
    box_row " "
    draw_box_bot
}

function draw_success() {
    local message="$1"
    draw_box_top
    box_row_center "${C_GREEN}✓ SUCCESS${NC}"
    draw_box_mid
    box_row " "
    box_row " ${C_WHITE}$message${NC}"
    box_row " "
    draw_box_bot
    echo ""
}

function draw_error() {
    local message="$1"
    draw_warn_top
    warn_row_center "${C_RED}✗ ERROR${NC}"
    draw_warn_mid
    warn_row " "
    warn_row " ${C_WHITE}$message${NC}"
    warn_row " "
    draw_warn_bot
    echo ""
}

function warn_row_center() {
    local content="$1"
    local len=$((${#content} - 27))  # Subtract color codes
    local pad=$(( (BOX_WIDTH - len) / 2 ))
    echo -e "${INDENT}${C_ORANGE}│${NC}$(printf ' %.0s' $(seq 1 $pad))${content}$(printf ' %.0s' $(seq 1 $pad))${C_ORANGE}│${NC}"
}

# ============================================================
# BACKWARD COMPATIBILITY ALIASES
# ============================================================

# Legacy function aliases for other modules
function draw_top() { draw_box_top; }
function draw_mid() { draw_box_mid; }
function draw_bot() { draw_box_bot; }
function draw_line() { draw_box_mid; }

function print_line() {
    local left="$1"
    local right="$2"
    local color="${3:-$C_NEON}"
    local line="${left} ${right}"
    box_row "${color}${line}${NC}"
}

function print_box_line() {
    local content="$1"
    box_row "$content"
}

function menu_item() {
    local num="$1"
    local title="$2"
    local desc="$3"
    local line=$(printf "%-5s %-20s %s" "$num" "$title" "$desc")
    box_row "$line"
}

# Legacy colors (if used by other modules)
C_TXT="$C_WHITE"
C_OK="$C_GREEN"
C_ERR="$C_RED"
C_WARN="$C_YELLOW"
