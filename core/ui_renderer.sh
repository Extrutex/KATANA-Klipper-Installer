#!/bin/bash

# --- VISUAL ENGINE (Restored) ---
C_PURPLE='\033[38;5;93m'
C_PINK='\033[38;5;201m'
C_CYAN='\033[38;5;51m'
C_NEON='\033[38;5;87m'
C_GREEN='\033[38;5;46m'
C_RED='\033[38;5;196m'
C_GREY='\033[38;5;238m'
C_TXT='\033[38;5;255m'
C_WARN='\033[38;5;226m'
NC='\033[0m'

WIDTH=72

# --- PIXEL PERFECT HELPER ---
function print_box_line() {
    local content="$1"
    # 1. Remove color codes to measure real length
    local clean_content=$(echo -e "$content" | sed "s/\x1B\[[0-9;]*[a-zA-Z]//g")
    # 2. Calculate length
    local len=${#clean_content}
    # 3. Calculate padding
    local pad_len=$((WIDTH - 2 - len))
    if [ $pad_len -lt 0 ]; then pad_len=0; fi
    local padding=$(printf '%*s' "$pad_len")
    # 4. Print line
    echo -e "${C_PURPLE}║${NC}${content}${padding}${C_PURPLE}║${NC}"
}

function draw_line() { printf "${C_PURPLE}╠═$(printf '═%.0s' $(seq 1 $((WIDTH-2))))═╣${NC}\n"; }
function draw_top()  { printf "${C_PURPLE}╔═$(printf '═%.0s' $(seq 1 $((WIDTH-2))))═╗${NC}\n"; }
function draw_bot()  { printf "${C_PURPLE}╚═$(printf '═%.0s' $(seq 1 $((WIDTH-2))))═╝${NC}\n"; }

function menu_item() {
    local id=$1 title=$2 desc=$3
    local row_content=" ${C_PINK}[${id}]${NC} ${C_CYAN}$(printf "%-25s" "$title")${NC} ${C_GREY}${desc}${NC}"
    print_box_line "$row_content"
}

function draw_main_menu() {
    clear
    echo -e "${C_PURPLE}"
    cat << "EOF"
      /\      _  __    _    _____    _    _   _    _      ___    ____ 
     /  \    | |/ /   / \  |_   _|  / \  | \ | |  / \    / _ \  / ___|
     \  /    | ' /   / _ \   | |   / _ \ |  \| | / _ \  | | | | \___ \
      \/     | . \  / ___ \  | |  / ___ \| |\  |/ ___ \ | |_| |  ___) |
             |_|\_\/_/   \_\ |_| /_/   \_\_| \_/_/   \_\ \___/  |____/ 
                                                         v2.0 MASTER
EOF
    echo -e "${C_NEON}    >> SYSTEM OVERLORD // COMMAND INTERFACE${NC}"
    
    draw_top
    print_box_line " ${C_TXT}COMMAND DECK${NC}"
    draw_line
    print_box_line " ${C_TXT}[ INSTALLATION ]${NC}"
    menu_item "1" "AUTO-PILOT" "Full Stack Install (God Mode)"
    menu_item "2" "CORE ENGINE" "Klipper, Moonraker & Nginx"
    menu_item "3" "WEB INTERFACE" "Mainsail / Fluidd"
    menu_item "4" "KATANA-FLOW" "Smart Park & Adaptive Purge"
    draw_line
    print_box_line " ${C_TXT}[ CONFIGURATION ]${NC}"
    menu_item "5" "THE FORGE" "Flash MCU & CAN-Bus"
    menu_item "6" "ENGINE MANAGER" "Klipper <-> Kalico Switch"
    draw_line
    print_box_line " ${C_TXT}[ MAINTENANCE ]${NC}"
    menu_item "7" "KATANA DOCTOR" "Diagnostic & Repair"
    menu_item "8" "SYSTEM PREP" "Updates & Dependencies"
    menu_item "9" "SEC & BACKUP" "Firewall & Backup"
    draw_line
    menu_item "X" "EXIT" "Close KATANAOS"
    draw_bot
    echo ""
}

