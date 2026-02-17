# ============================================================
# KATANAOS VISUAL ENGINE v2.2
# ============================================================

# Colors
C_PURPLE=$'\033[38;5;93m'
C_NEON=$'\033[38;5;51m'
C_GREEN=$'\033[38;5;46m'
C_GREY=$'\033[38;5;240m'
C_WHITE=$'\033[38;5;255m'
C_RED=$'\033[38;5;196m'
C_YELLOW=$'\033[38;5;226m'
C_ORANGE=$'\033[38;5;208m'
NC=$'\033[0m'

# Box dimensions
BOX_WIDTH=70
INDENT="  "

# ============================================================
# BOX DRAWING FUNCTIONS
# ============================================================

function draw_box_top() {
    echo -e "${INDENT}${C_PURPLE}╔${C_PURPLE}$(printf '═%.0s' $(seq 1 $BOX_WIDTH))${C_PURPLE}╗${NC}"
}

function draw_box_mid() {
    echo -e "${INDENT}${C_PURPLE}╠${C_PURPLE}$(printf '═%.0s' $(seq 1 $BOX_WIDTH))${C_PURPLE}╣${NC}"
}

function draw_box_bot() {
    echo -e "${INDENT}${C_PURPLE}╚${C_PURPLE}$(printf '═%.0s' $(seq 1 $BOX_WIDTH))${C_PURPLE}╝${NC}"
}

function draw_sub_top() {
    echo -e "${INDENT}${C_PURPLE}╔${C_PURPLE}$(printf '═%.0s' $(seq 1 $BOX_WIDTH))${C_PURPLE}╗${NC}"
}

function draw_sub_mid() {
    echo -e "${INDENT}${C_PURPLE}╠${C_PURPLE}$(printf '═%.0s' $(seq 1 $BOX_WIDTH))${C_PURPLE}╣${NC}"
}

function draw_sub_bot() {
    echo -e "${INDENT}${C_PURPLE}╚${C_PURPLE}$(printf '═%.0s' $(seq 1 $BOX_WIDTH))${C_PURPLE}╝${NC}"
}

function draw_warn_top() {
    echo -e "${INDENT}${C_ORANGE}╔${C_ORANGE}$(printf '═%.0s' $(seq 1 $BOX_WIDTH))${C_ORANGE}╗${NC}"
}

function draw_warn_mid() {
    echo -e "${INDENT}${C_ORANGE}╠${C_ORANGE}$(printf '═%.0s' $(seq 1 $BOX_WIDTH))${C_ORANGE}╣${NC}"
}

function draw_warn_bot() {
    echo -e "${INDENT}${C_ORANGE}╚${C_ORANGE}$(printf '═%.0s' $(seq 1 $BOX_WIDTH))${C_ORANGE}╝${NC}"
}

# ============================================================
# LINE DRAWING FUNCTIONS
# ============================================================

function box_row() {
    local content="$1"
    local len=${#content}
    local pad=$((BOX_WIDTH - len - 2))
    [ $pad -lt 0 ] && pad=0
    echo -e "${INDENT}${C_PURPLE}║${NC} ${content}$(printf ' %.0s' $(seq 1 $pad))${C_PURPLE}║${NC}"
}

function box_row_left() {
    local content="$1"
    local len=$(visible_len "$content")
    local pad=$((BOX_WIDTH - len - 2))
    [ $pad -lt 0 ] && pad=0
    echo -e "${INDENT}${C_PURPLE}║${NC}${content}$(printf ' %.0s' $(seq 1 $pad))${C_PURPLE}║${NC}"
}

function sub_row() {
    local content="$1"
    local len=${#content}
    local pad=$((BOX_WIDTH - len - 2))
    [ $pad -lt 0 ] && pad=0
    echo -e "${INDENT}${C_PURPLE}║${NC} ${content}$(printf ' %.0s' $(seq 1 $pad))${C_PURPLE}║${NC}"
}

function warn_row() {
    local content="$1"
    local len=${#content}
    local pad=$((BOX_WIDTH - len - 2))
    [ $pad -lt 0 ] && pad=0
    echo -e "${INDENT}${C_ORANGE}║${NC} ${content}$(printf ' %.0s' $(seq 1 $pad))${C_ORANGE}║${NC}"
}

function visible_len() {
    local str="$1"
    local len=0
    local i
    local in_ansi=0
    for ((i=0; i<${#str}; i++)); do
        local c="${str:$i:1}"
        if [[ "$c" == $'\033' || "$in_ansi" == "1" ]]; then
            if [[ "$in_ansi" == "0" ]]; then
                in_ansi=1
            elif [[ "$c" == "m" ]]; then
                in_ansi=0
            fi
        else
            ((len++))
        fi
    done
    echo $len
}

function box_row() {
    local content="$1"
    local len=$(visible_len "$content")
    local pad=$((BOX_WIDTH - len - 2))
    [ $pad -lt 0 ] && pad=0
    echo -e "${INDENT}${C_PURPLE}║${NC} ${content}$(printf ' %.0s' $(seq 1 $pad))${C_PURPLE}║${NC}"
}

function box_row_left() {
    local content="$1"
    local len=$(visible_len "$content")
    local pad=$((BOX_WIDTH - len - 2))
    [ $pad -lt 0 ] && pad=0
    echo -e "${INDENT}${C_PURPLE}║${NC} ${content}$(printf ' %.0s' $(seq 1 $pad))${C_PURPLE}║${NC}"
}

function box_row_center() {
    local content="$1"
    local len=$(visible_len "$content")
    local left=$(( (BOX_WIDTH - len - 2) / 2 ))
    local right=$((BOX_WIDTH - len - 2 - left))
    echo -e "${INDENT}${C_PURPLE}║${NC}$(printf ' %.0s' $(seq 1 $left))${content}$(printf ' %.0s' $(seq 1 $right))${C_PURPLE}║${NC}"
}

function sub_row() {
    local content="$1"
    local len=$(visible_len "$content")
    local pad=$((BOX_WIDTH - len - 2))
    [ $pad -lt 0 ] && pad=0
    echo -e "${INDENT}${C_PURPLE}║${NC} ${content}$(printf ' %.0s' $(seq 1 $pad))${C_PURPLE}║${NC}"
}

function warn_row() {
    local content="$1"
    local len=$(visible_len "$content")
    local pad=$((BOX_WIDTH - len - 2))
    [ $pad -lt 0 ] && pad=0
    echo -e "${INDENT}${C_ORANGE}║${NC} ${content}$(printf ' %.0s' $(seq 1 $pad))${C_ORANGE}║${NC}"
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
    if systemctl is-active --quiet "${service}.service" 2>/dev/null; then
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

function get_status_icon() {
    local status="$1"
    if [ "$status" = "INSTALLED" ]; then
        echo -e "${C_GREEN}●${NC}"
    else
        echo -e "${C_GREY}○${NC}"
    fi
}

function box_status() {
    local name="$1"
    local status="$2"
    local icon
    local status_text
    
    if [ "$status" = "INSTALLED" ]; then
        icon="${C_GREEN}●${NC}"
        status_text="${C_GREEN}INSTALLED${NC}"
    else
        icon="${C_GREY}○${NC}"
        status_text="${C_GREY}NOT INSTALLED${NC}"
    fi
    
    box_row_left "$icon $name $status_text"
}

function box_row_pair() {
    local left="$1"
    local right="$2"
    box_row "$left $right"
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

function check_bed_distance_sensor_status() {
    if [ -d "$HOME/printer_data/config/bed_distance_sensor" ] || [ -d "$HOME/bed_distance_sensor" ]; then
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
    echo -e "                                                    ${C_PURPLE}v2.2${C_PURPLE}"
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
    box_row_left "${C_WHITE}SYSTEM STATUS${NC}"
    draw_box_mid
    
    local klipper_status=$(check_service_status "klipper")
    local moonraker_status=$(check_service_status "moonraker")
    local engine=$(get_current_engine_short)
    
    if [ "$engine" != "NONE" ]; then
        if [ "$klipper_status" = "ONLINE" ]; then
            box_row_left "${C_GREEN}●${NC} Engine        : ${C_NEON}$engine${NC}    ${C_GREEN}ONLINE${NC}   3D Printer Firmware"
        else
            box_row_left "${C_GREY}○${NC} Engine        : ${C_NEON}$engine${NC}    ${C_GREY}OFFLINE${NC}  3D Printer Firmware"
        fi
    else
        box_row_left "${C_GREY}○${NC} Engine        : ${C_GREY}NOT INSTALLED${NC}"
    fi
    
    if [ "$moonraker_status" = "ONLINE" ]; then
        box_row_left "${C_GREEN}●${NC} Moonraker     : ${C_GREEN}ONLINE ${NC}   API Server"
    else
        box_row_left "${C_GREY}○${NC} Moonraker     : ${C_GREY}OFFLINE${NC}   API Server"
    fi
    
    draw_box_bot
    
    # === INSTALLED COMPONENTS ===
    local mainsail_status=$(check_dir_status "$HOME/mainsail")
    local fluidd_status=$(check_dir_status "$HOME/fluidd")
    local crowsnest_status=$(check_dir_status "$HOME/crowsnest")
    local klipperscreen_status=$(check_dir_status "$HOME/KlipperScreen")
    local happuhare_status=$(check_dir_status "$HOME/happy_hare")
    local katanaflow_status=$(check_katanaflow_status)
    
    draw_sub_top
    sub_row "${C_PURPLE}>> INSTALLED${NC}"
    draw_sub_mid
    
    local has_installed=0
    
    if [ "$mainsail_status" = "INSTALLED" ] || [ "$fluidd_status" = "INSTALLED" ]; then
        box_row "${C_GREEN}●${NC} Web UI"
        has_installed=1
    fi
    if [ "$crowsnest_status" = "INSTALLED" ] || [ "$klipperscreen_status" = "INSTALLED" ]; then
        box_row "${C_GREEN}●${NC} Vision"
        has_installed=1
    fi
    if [ "$happuhare_status" = "INSTALLED" ]; then
        box_row "${C_GREEN}●${NC} Toolchanger"
        has_installed=1
    fi
    if [ "$katanaflow_status" = "INSTALLED" ]; then
        box_row "${C_GREEN}●${NC} KATANA Flow"
        has_installed=1
    fi
    
    if [ $has_installed -eq 0 ]; then
        box_row "${C_GREY}○ No extras installed${NC}"
    fi
    
    draw_sub_bot
    
    # === MAIN MENU ===
    draw_box_mid
    box_row_left "${C_WHITE}⚡ MAIN MENU${NC}"
    draw_box_mid
    box_row_left "${C_GREEN}[1]${NC}  ⚡ QUICK START     Full Install Wizard"
    box_row_left "${C_NEON}[2]${NC}  🔄 UPDATE         Alle Komponenten updaten"
    box_row_left "${C_NEON}[3]${NC}  📦 EXTRAS         Erweiterungen installieren"
    box_row_left "${C_NEON}[4]${NC}  🔧 FORGE          MCU / Firmware / CAN-Bus"
    box_row_left "${C_NEON}[5]${NC}  🩺 DIAGNOSE       Service / Logs / Reparatur"
    box_row_left "${C_NEON}[6]${NC}  ⚙️  EINSTELLUNGEN  Profil / Theme / Netzwerk"
    
    draw_box_mid
    box_row_left "${C_RED}[X]${NC}  Exit             Close KATANAOS"
    draw_box_bot
    echo ""
}

# ============================================================
# MENU 1: QUICK START
# ============================================================

function run_quick_start() {
    while true; do
        draw_header "⚡ QUICK START - INSTALLATION WIZARD"
        
        echo "  ${C_GREEN}[1]${NC}  Komplette Installation   Klipper + Moonraker + UI"
        echo "  ${C_NEON}[2]${NC}  Nur Firmware            Klipper Only"
        echo "  ${C_NEON}[3]${NC}  UI hinzufügen           Mainsail / Fluidd"
        echo "  ${C_NEON}[4]${NC}  Config importieren      Bestehende printer.cfg"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " ch
        
        case $ch in
            1) run_autopilot ;;
            2) run_installer_menu ;;
            3) run_ui_installer ;;
            4) run_printer_config_wizard ;;
            b|B) return ;;
            *) log_error "Invalid Selection" ;;
        esac
    done
}

# ============================================================
# MENU 2: UPDATE
# ============================================================

function run_update_menu() {
    while true; do
        draw_header "🔄 UPDATE MANAGER"
        
        echo "  ${C_GREEN}[1]${NC}  Alles updaten           Klipper + Moonraker + alle Extras"
        echo "  ${C_NEON}[2]${NC}  Nur Klipper             Firmware"
        echo "  ${C_NEON}[3]${NC}  Nur Moonraker           API Server"
        echo "  ${C_NEON}[4]${NC}  Nur UI                  Mainsail / Fluidd"
        echo "  ${C_NEON}[5]${NC}  Nur Extras              Alle installierten Erweiterungen"
        echo "  ${C_NEON}[6]${NC}  Nur prüfen              Nicht installieren"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " ch
        
        case $ch in
            1) update_core_stack ;;
            2) update_klipper_only ;;
            3) update_moonraker_only ;;
            4) update_ui_only ;;
            5) update_extras_only ;;
            6) check_updates_only ;;
            b|B) return ;;
            *) log_error "Invalid Selection" ;;
        esac
    done
}

function update_klipper_only() {
    draw_header "UPDATE - KLIPPER"
    cd "$HOME/klipper"
    git pull
    make clean
    make olddefconfig
    make -j$(nproc)
    sudo make flash
    read -p "  Enter..."
}

function update_moonraker_only() {
    draw_header "UPDATE - MOONRAKER"
    cd "$HOME/moonraker"
    git pull
    ./scripts/install.sh
    sudo systemctl restart moonraker
    read -p "  Enter..."
}

function update_ui_only() {
    draw_header "UPDATE - WEB UI"
    echo "  Wähle UI:"
    echo "  [1] Mainsail"
    echo "  [2] Fluidd"
    read -p "  >> " ch
    case $ch in
        1) cd "$HOME/mainsail" && git pull ;;
        2) cd "$HOME/fluidd" && git pull ;;
    esac
    read -p "  Enter..."
}

function update_extras_only() {
    draw_header "UPDATE - EXTRAS"
    echo "  Updating all extras..."
    # TODO: Implement
    read -p "  Enter..."
}

function check_updates_only() {
    draw_header "CHECK FOR UPDATES"
    echo "  Checking for updates..."
    # TODO: Implement
    read -p "  Enter..."
}

# ============================================================
# MENU 3: EXTRAS (KATALOG)
# ============================================================

function run_extras_menu() {
    while true; do
        draw_header "📦 EXTRAS - ERWEITERUNGEN"
        
        echo "  ${C_GREEN}[1]${NC}  🎨 WEB UI              Mainsail / Fluidd"
        echo "  ${C_NEON}[2]${NC}  📷 VISION              Crowsnest / KlipperScreen"
        echo "  ${C_NEON}[3]${NC}  🔌 SMART PROBES        Smart Probe / Carto / Beacon / Eddy"
        echo "  ${C_NEON}[4]${NC}  📏 BED DISTANCE        Bed Distance Sensor"
        echo "  ${C_NEON}[5]${NC}  🛠️  TOOLCHANGER         Happy Hare / StealthChanger / MADMAX"
        echo "  ${C_NEON}[6]${NC}  🔬 TUNING               KATANA Flow / ShakeTune / OctoPrint"
        echo "  ${C_NEON}[7]${NC}  💾 SYSTEM               Log2Ram / Backup / Restore"
        echo "  ${C_NEON}[8]${NC}  🔒 SECURITY             Firewall / SSH / PolKit"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " ch
        
        case $ch in
            1) run_extras_webui ;;
            2) run_extras_vision ;;
            3) run_extras_smartprobes ;;
            4) run_extras_beddistance ;;
            5) run_extras_toolchanger ;;
            6) run_extras_tuning ;;
            7) run_extras_system ;;
            8) run_extras_security ;;
            b|B) return ;;
            *) log_error "Invalid Selection" ;;
        esac
    done
}

function run_extras_webui() {
    while true; do
        draw_header "🎨 WEB UI"
        
        local mainsail=$(check_dir_status "$HOME/mainsail")
        local fluidd=$(check_dir_status "$HOME/fluidd")
        
        echo "  ${C_GREEN}[1]${NC}  Mainsail installieren    [$mainsail]"
        echo "  ${C_NEON}[2]${NC}  Fluidd installieren       [$fluidd]"
        echo "  ${C_NEON}[3]${NC}  Zwischen UI wechseln"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " ch
        
        case $ch in
            1) run_ui_installer ;;
            2) install_fluidd ;;
            3) switch_ui ;;
            b|B) return ;;
        esac
    done
}

function install_fluidd() {
    draw_header "INSTALL FLUIDD"
    echo "  Installing Fluidd..."
    # TODO: Implement
    read -p "  Enter..."
}

function switch_ui() {
    draw_header "SWITCH UI"
    echo "  Which UI do you want to use?"
    echo "  [1] Mainsail"
    echo "  [2] Fluidd"
    read -p "  >> " ch
    # TODO: Implement
    read -p "  Enter..."
}

function run_extras_vision() {
    while true; do
        draw_header "📷 VISION"
        
        local crowsnest=$(check_dir_status "$HOME/crowsnest")
        local klipperscreen=$(check_dir_status "$HOME/KlipperScreen")
        
        echo "  ${C_GREEN}[1]${NC}  Crowsnest (Camera)     [$crowsnest]"
        echo "  ${C_NEON}[2]${NC}  KlipperScreen          [$klipperscreen]"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " ch
        
        case $ch in
            1) install_crowsnest ;;
            2) install_klipperscreen ;;
            b|B) return ;;
        esac
    done
}

function install_crowsnest() {
    draw_header "INSTALL CROWSNEST"
    echo "  Installing Crowsnest..."
    # TODO: Implement
    read -p "  Enter..."
}

function install_klipperscreen() {
    draw_header "INSTALL KLIPPERSCREEN"
    echo "  Installing KlipperScreen..."
    # TODO: Implement
    read -p "  Enter..."
}

function run_extras_smartprobes() {
    while true; do
        draw_header "🔌 SMART PROBES"
        
        local smartprobe=$(check_dir_status "$HOME/smart_probe")
        local carto=$(check_cartographer_status)
        local beacon=$(check_beacon_status)
        local eddy=$(check_btt_eddy_status)
        
        echo "  ${C_GREEN}[1]${NC}  Smart Probe            [$smartprobe]"
        echo "  ${C_NEON}[2]${NC}  Cartographer           [$carto]"
        echo "  ${C_NEON}[3]${NC}  Beacon Probe          [$beacon]"
        echo "  ${C_NEON}[4]${NC}  BTT Eddy               [$eddy]"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " ch
        
        case $ch in
            1) install_smartprobe ;;
            2) install_cartographer ;;
            3) install_beacon ;;
            4) install_btt_eddy ;;
            b|B) return ;;
        esac
    done
}

function install_smartprobe() { draw_header "SMART PROBE"; read -p "  Enter..."; }
function install_cartographer() { draw_header "CARTOGRAPHER"; read -p "  Enter..."; }
function install_beacon() { draw_header "BEACON PROBE"; read -p "  Enter..."; }
function install_btt_eddy() { draw_header "BTT EDDY"; read -p "  Enter..."; }

function run_extras_beddistance() {
    draw_header "📏 BED DISTANCE SENSOR"
    local status=$(check_bed_distance_sensor_status)
    echo "  Status: $status"
    echo "  [1] Installieren"
    echo "  [2] Entfernen"
    read -p "  >> " ch
    read -p "  Enter..."
}

function run_extras_toolchanger() {
    while true; do
        draw_header "🛠️ TOOLCHANGER"
        
        local happyhare=$(check_dir_status "$HOME/happy_hare")
        local stealth=$(check_stealthchanger_status)
        local madmax=$(check_madmax_status)
        
        echo "  ${C_GREEN}[1]${NC}  Happy Hare             [$happyhare]"
        echo "  ${C_NEON}[2]${NC}  StealthChanger         [$stealth]"
        echo "  ${C_NEON}[3]${NC}  MADMAX                 [$madmax]"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " ch
        
        case $ch in
            1) install_happyhare ;;
            2) install_stealthchanger ;;
            3) install_madmax ;;
            b|B) return ;;
        esac
    done
}

function install_happyhare() { draw_header "HAPPY HARE"; read -p "  Enter..."; }
function install_stealthchanger() { draw_header "STEALTHCHANGER"; read -p "  Enter..."; }
function install_madmax() { draw_header "MADMAX"; read -p "  Enter..."; }

function run_extras_tuning() {
    while true; do
        draw_header "🔬 TUNING"
        
        local katanaflow=$(check_katanaflow_status)
        local shaketune=$(check_shaketune_status)
        local octoprint=$(check_octoprint_status)
        
        echo "  ${C_GREEN}[1]${NC}  KATANA Flow            [$katanaflow]"
        echo "  ${C_NEON}[2]${NC}  ShakeTune              [$shaketune]"
        echo "  ${C_NEON}[3]${NC}  OctoPrint              [$octoprint]"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " ch
        
        case $ch in
            1) run_katana_flow ;;
            2) install_shaketune ;;
            3) install_octoprint ;;
            b|B) return ;;
        esac
    done
}

function install_shaketune() { draw_header "SHAKETUNE"; read -p "  Enter..."; }
function install_octoprint() { run_octoprint_install; }

function run_extras_system() {
    while true; do
        draw_header "💾 SYSTEM"
        
        local log2ram=$(check_log2ram_status)
        
        echo "  ${C_GREEN}[1]${NC}  Log2Ram                [$log2ram]"
        echo "  ${C_NEON}[2]${NC}  Backup erstellen"
        echo "  ${C_NEON}[3]${NC}  Backup wiederherstellen"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " ch
        
        case $ch in
            1) install_log2ram ;;
            2) run_backup_restore ;;
            3) run_backup_restore ;;
            b|B) return ;;
        esac
    done
}

function install_log2ram() { draw_header "LOG2RAM"; read -p "  Enter..."; }

function run_extras_security() {
    run_security_menu
}

# ============================================================
# MENU 4: FORGE
# ============================================================

function run_forge_menu() {
    source "$MODULES_DIR/hardware/flash_registry.sh"
    run_flash_menu
}

# ============================================================
# MENU 5: DIAGNOSE
# ============================================================

function run_diagnose_menu() {
    while true; do
        draw_header "🩺 DIAGNOSE"
        
        echo "  ${C_GREEN}[1]${NC}  Service Status        Alle Services prüfen"
        echo "  ${C_NEON}[2]${NC}  Logs                  Klipper / Moonraker"
        echo "  ${C_NEON}[3]${NC}  Reparatur"
        echo "        ├── Klipper neustarten"
        echo "        ├── Moonraker neustarten"
        echo "        ├── Auto-Restart konfigurieren"
        echo "        └── printer.cfg validieren"
        echo "  ${C_NEON}[4]${NC}  Notfall"
        echo "        ├── Komplette Neuinstallation"
        echo "        └── Vollständige Deinstallation"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " ch
        
        case $ch in
            1) check_all_services ;;
            2) show_logs_menu ;;
            3) run_repair_menu ;;
            4) run_emergency_menu ;;
            b|B) return ;;
            *) log_error "Invalid Selection" ;;
        esac
    done
}

function check_all_services() {
    draw_header "SERVICE STATUS"
    systemctl status klipper --no-pager || true
    systemctl status moonraker --no-pager || true
    read -p "  Enter..."
}

function show_logs_menu() {
    while true; do
        draw_header "LOGS"
        echo "  [1] Klipper Logs"
        echo "  [2] Moonraker Logs"
        echo "  [3] Dmesg (USB)"
        echo "  [B] Back"
        read -p "  >> " ch
        case $ch in
            1) sudo journalctl -u klipper -n 50 ;;
            2) sudo journalctl -u moonraker -n 50 ;;
            3) dmesg | tail -30 ;;
            b|B) return ;;
        esac
        read -p "  Enter..."
    done
}

function run_repair_menu() {
    while true; do
        draw_header "REPARATUR"
        echo "  [1] Klipper neustarten"
        echo "  [2] Moonraker neustarten"
        echo "  [3] Auto-Restart konfigurieren"
        echo "  [B] Back"
        read -p "  >> " ch
        case $ch in
            1) sudo systemctl restart klipper ;;
            2) sudo systemctl restart moonraker ;;
            3) run_auto_restart ;;
            b|B) return ;;
        esac
    done
}

function run_emergency_menu() {
    while true; do
        draw_header "NOTFALL"
        echo "  [1] Komplette Neuinstallation"
        echo "  [2] Vollständige Deinstallation"
        echo "  [B] Back"
        read -p "  >> " ch
        case $ch in
            1) run_autopilot ;;
            2) run_uninstaller ;;
            b|B) return ;;
        esac
    done
}

# ============================================================
# MENU 6: EINSTELLUNGEN
# ============================================================

function run_settings_menu() {
    while true; do
        draw_header "⚙️ EINSTELLUNGEN"
        
        echo "  ${C_GREEN}[1]${NC}  Profil                (minimal / standard / power)"
        echo "  ${C_NEON}[2]${NC}  Terminal               (Farben / Theme)"
        echo "  ${C_NEON}[3]${NC}  CAN-Bus                (Netzwerk Konfiguration)"
        echo "  ${C_NEON}[4]${NC}  Engine Switch          (Klipper / Kalico / RatOS)"
        echo "  ${C_NEON}[5]${NC}  Uninstall              (Alles entfernen)"
        echo "  ${C_NEON}[6]${NC}  Info                   (Version / Credits)"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " ch
        
        case $ch in
            1) change_profile ;;
            2) change_theme ;;
            3) setup_can_network ;;
            4) run_engine_manager ;;
            5) run_uninstaller ;;
            6) show_info ;;
            b|B) return ;;
            *) log_error "Invalid Selection" ;;
        esac
    done
}

function change_profile() {
    draw_header "PROFIL ÄNDERN"
    echo "  Aktuell: $INSTALL_PROFILE"
    echo "  [1] minimal   - Only Klipper + Moonraker"
    echo "  [2] standard  - Core + Mainsail (default)"
    echo "  [3] power     - Everything"
    read -p "  >> " ch
    case $ch in
        1) INSTALL_PROFILE="minimal" ;;
        2) INSTALL_PROFILE="standard" ;;
        3) INSTALL_PROFILE="power" ;;
    esac
    read -p "  Enter..."
}

function change_theme() {
    draw_header "THEME"
    echo "  Theme-Funktion coming soon..."
    read -p "  Enter..."
}

function show_info() {
    draw_header "KATANAOS INFO"
    echo "  Version: $VERSION"
    echo "  Build: $BUILD"
    echo "  Profile: $INSTALL_PROFILE"
    read -p "  Enter..."
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
