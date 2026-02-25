# ============================================================
# KATANAOS VISUAL ENGINE v2.6 — FIXED
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

# Legacy colors (if used by other modules)
C_TXT="$C_WHITE"
C_OK="$C_GREEN"
C_ERR="$C_RED"
C_WARN="$C_YELLOW"

# ============================================================
# CORE UTILITY: VISIBLE LENGTH
# ============================================================
# Strips ALL ANSI escape sequences, then measures display width.
# Uses wc -L which respects double-width chars (Emojis, CJK).

function visible_len() {
    local str="$1"
    # 1) Strip ANSI escape codes
    local clean
    clean=$(printf '%b' "$str" | sed 's/\x1b\[[0-9;]*m//g')
    # 2) wc -L returns display width (handles wide chars/emojis)
    local width
    width=$(printf '%s' "$clean" | wc -L)
    echo "$width"
}

# Safe padding: returns N spaces, or empty string if N <= 0
function make_pad() {
    local n="$1"
    if [ "$n" -gt 0 ] 2>/dev/null; then
        printf '%*s' "$n" ''
    fi
}

# ============================================================
# BOX DRAWING FUNCTIONS
# ============================================================

function draw_box_top() {
    echo -e "${INDENT}${C_PURPLE}╔$(printf '═%.0s' $(seq 1 $BOX_WIDTH))╗${NC}"
}

function draw_box_mid() {
    echo -e "${INDENT}${C_PURPLE}╠$(printf '═%.0s' $(seq 1 $BOX_WIDTH))╣${NC}"
}

function draw_box_bot() {
    echo -e "${INDENT}${C_PURPLE}╚$(printf '═%.0s' $(seq 1 $BOX_WIDTH))╝${NC}"
}

function draw_warn_top() {
    echo -e "${INDENT}${C_ORANGE}╔$(printf '═%.0s' $(seq 1 $BOX_WIDTH))╗${NC}"
}

function draw_warn_mid() {
    echo -e "${INDENT}${C_ORANGE}╠$(printf '═%.0s' $(seq 1 $BOX_WIDTH))╣${NC}"
}

function draw_warn_bot() {
    echo -e "${INDENT}${C_ORANGE}╚$(printf '═%.0s' $(seq 1 $BOX_WIDTH))╝${NC}"
}

# ============================================================
# LINE DRAWING FUNCTIONS (each defined ONCE)
# ============================================================


function box_row() {
    local content="$1"
    local len
    len=$(visible_len "$content")
    local pad=$((BOX_WIDTH - len - 1))
    local spaces
    spaces=$(make_pad "$pad")
    echo -e "${INDENT}${C_PURPLE}║${NC} ${content}${spaces}${C_PURPLE}║${NC}"
}

function box_row_left() {
    local content="$1"
    local len
    len=$(visible_len "$content")
    local pad=$((BOX_WIDTH - len - 1))
    local spaces
    spaces=$(make_pad "$pad")
    echo -e "${INDENT}${C_PURPLE}║${NC} ${content}${spaces}${C_PURPLE}║${NC}"
}

function box_row_center() {
    local content="$1"
    local len
    len=$(visible_len "$content")
    local total=$((BOX_WIDTH - 1))
    local left_pad=$(( (total - len) / 2 ))
    local right_pad=$((total - len - left_pad))
    local lspaces
    lspaces=$(make_pad "$left_pad")
    local rspaces
    rspaces=$(make_pad "$right_pad")
    echo -e "${INDENT}${C_PURPLE}║${NC}${lspaces} ${content}${rspaces}${C_PURPLE}║${NC}"
}

function sub_row() {
    local content="$1"
    local len
    len=$(visible_len "$content")
    local pad=$((BOX_WIDTH - len - 1))
    local spaces
    spaces=$(make_pad "$pad")
    echo -e "${INDENT}${C_PURPLE}║${NC} ${content}${spaces}${C_PURPLE}║${NC}"
}

function warn_row() {
    local content="$1"
    local len
    len=$(visible_len "$content")
    local pad=$((BOX_WIDTH - len - 1))
    local spaces
    spaces=$(make_pad "$pad")
    echo -e "${INDENT}${C_ORANGE}║${NC} ${content}${spaces}${C_ORANGE}║${NC}"
}

function warn_row_center() {
    local content="$1"
    local len
    len=$(visible_len "$content")
    local total=$((BOX_WIDTH - 1))
    local left_pad=$(( (total - len) / 2 ))
    local right_pad=$((total - len - left_pad))
    local lspaces
    lspaces=$(make_pad "$left_pad")
    local rspaces
    rspaces=$(make_pad "$right_pad")
    echo -e "${INDENT}${C_ORANGE}║${NC}${lspaces} ${content}${rspaces}${C_ORANGE}║${NC}"
}

# ============================================================
# STATUS FUNCTIONS
# ============================================================

function get_current_engine_short() {
    if [ -L "$HOME/klipper" ]; then
        local target
        target=$(readlink "$HOME/klipper")
        if [[ "$target" == *"kalico"* ]]; then echo "KALICO";
        elif [[ "$target" == *"ratos"* ]]; then echo "RatOS";
        else echo "KLIPPER"; fi
    elif [ -d "$HOME/klipper" ]; then
        echo "KLIPPER"
    else
        echo "NONE"
    fi
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
    echo -e "                                                              ${C_PURPLE}${KATANA_VERSION}${C_PURPLE}"
    echo -e "      ${C_NEON}>> KATANAOS // SYSTEM COMMAND INTERFACE${NC}"
    echo ""
}

function draw_header() {
    local title="$1"
    draw_header_main
    box_row_center "${C_NEON}:: $title ::${NC}"
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

    local klipper_status
    klipper_status=$(check_service_status "klipper")
    local moonraker_status
    moonraker_status=$(check_service_status "moonraker")
    local engine
    engine=$(get_current_engine_short)

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
    draw_box_top
    sub_row "${C_PURPLE}>> INSTALLED COMPONENTS${NC}"
    draw_box_mid

    local has_installed=0

    # Web UI
    if [ -d "$HOME/mainsail" ]; then
        box_row "${C_GREEN}●${NC} Mainsail"
        has_installed=1
    fi
    if [ -d "$HOME/fluidd" ]; then
        box_row "${C_GREEN}●${NC} Fluidd"
        has_installed=1
    fi

    # Vision
    if [ -d "$HOME/crowsnest" ]; then
        box_row "${C_GREEN}●${NC} Crowsnest"
        has_installed=1
    fi
    if [ -d "$HOME/KlipperScreen" ]; then
        box_row "${C_GREEN}●${NC} KlipperScreen"
        has_installed=1
    fi

    # Multi-Material / Toolchanger
    if [ -d "$HOME/happy_hare" ]; then
        box_row "${C_GREEN}●${NC} Happy Hare (MMU)"
        has_installed=1
    fi
    if [ -d "$HOME/printer_data/config/stealthchanger" ]; then
        box_row "${C_GREEN}●${NC} StealthChanger"
        has_installed=1
    fi
    if [ -d "$HOME/printer_data/config/madmax" ]; then
        box_row "${C_GREEN}●${NC} MADMAX Toolchanger"
        has_installed=1
    fi

    # Probes
    if [ -d "$HOME/cartographer-klipper" ]; then
        box_row "${C_GREEN}●${NC} Cartographer Probe"
        has_installed=1
    fi
    if [ -d "$HOME/beacon_klipper" ]; then
        box_row "${C_GREEN}●${NC} Beacon Probe"
        has_installed=1
    fi
    if [ -d "$HOME/btt_eddy" ]; then
        box_row "${C_GREEN}●${NC} BTT Eddy"
        has_installed=1
    fi

    # Tuning & Extras
    if [ -d "$HOME/printer_data/config/katana_flow" ]; then
        box_row "${C_GREEN}●${NC} KATANA Flow"
        has_installed=1
    fi
    if [ -d "$HOME/klippain_shaketune" ]; then
        box_row "${C_GREEN}●${NC} ShakeTune"
        has_installed=1
    fi

    # System
    if dpkg -s log2ram >/dev/null 2>&1; then
        box_row "${C_GREEN}●${NC} Log2Ram"
        has_installed=1
    fi

    if [ $has_installed -eq 0 ]; then
        box_row "${C_GREY}○ No extras installed${NC}"
    fi

    draw_box_bot

    # === MAIN MENU ===
    draw_box_top
    box_row_left "${C_WHITE}MAIN MENU${NC}"
    draw_box_mid
    box_row_left "${C_GREEN}[1]${NC}  QUICK START     Full Install Wizard"
    box_row_left "${C_NEON}[2]${NC}  FORGE           Build & Flash Firmware"
    box_row_left "${C_NEON}[3]${NC}  EXTRAS          Install Extensions"
    box_row_left "${C_NEON}[4]${NC}  UPDATE          Update All Components"
    box_row_left "${C_NEON}[5]${NC}  DIAGNOSE        Service / Logs / Repair"
    box_row_left "${C_NEON}[6]${NC}  SETTINGS        Profile / Theme / Network"
    draw_box_mid
    box_row_left "${C_RED}[X]${NC}  Exit            Close KATANAOS"
    draw_box_bot
    echo ""
}

# ============================================================
# MENU 1: QUICK START
# ============================================================

function run_quick_start() {
    while true; do
        draw_header "QUICK START - INSTALLATION WIZARD"

        echo "  ${C_GREEN}[1]${NC}  Full Installation      Klipper + Moonraker + UI"
        echo "  ${C_NEON}[2]${NC}  Firmware Only         Klipper Only"
        echo "  ${C_NEON}[3]${NC}  Add UI                Mainsail / Fluidd"
        echo "  ${C_NEON}[4]${NC}  Import Config         Existing printer.cfg"
        echo ""
        echo "  [B] Back"
        echo ""
        if ! read -r -p "  >> COMMAND: " ch; then return; fi

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
    if declare -f dispatch_update_menu > /dev/null; then
        dispatch_update_menu
    else
        log_error "Dispatcher 'dispatch_update_menu' nicht gefunden."
        sleep 2
    fi
}

# ============================================================
# MENU 3: EXTRAS (KATALOG)
# ============================================================

function run_extras_menu() {
    while true; do
        draw_header "EXTRAS - EXTENSIONS"

        echo "  ${C_GREEN}[1]${NC}  WEB UI              Mainsail / Fluidd"
        echo "  ${C_NEON}[2]${NC}  VISION              Crowsnest / KlipperScreen"
        echo "  ${C_NEON}[3]${NC}  SMART PROBES        Smart Probe / Carto / Beacon / Eddy"
        echo "  ${C_NEON}[4]${NC}  BED DISTANCE        Bed Distance Sensor"
        echo "  ${C_NEON}[5]${NC}  TOOLCHANGER         Happy Hare / StealthChanger / MADMAX"
        echo "  ${C_NEON}[6]${NC}  TUNING              KATANA Flow / ShakeTune / OctoPrint"
        echo "  ${C_NEON}[7]${NC}  SYSTEM              Log2Ram / Backup / Restore"
        echo "  ${C_NEON}[8]${NC}  SECURITY            Firewall / SSH / PolKit"
        echo ""
        echo "  [B] Back"
        echo ""
        if ! read -r -p "  >> COMMAND: " ch; then return; fi

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
        draw_header "WEB UI"

        local mainsail
        mainsail=$(check_dir_status "$HOME/mainsail")
        local fluidd
        fluidd=$(check_dir_status "$HOME/fluidd")

        echo "  ${C_GREEN}[1]${NC}  Mainsail installieren    [$mainsail]"
        echo "  ${C_NEON}[2]${NC}  Fluidd installieren       [$fluidd]"
        echo "  ${C_NEON}[3]${NC}  Zwischen UI wechseln"
        echo ""
        echo "  [B] Back"
        echo ""
        if ! read -r -p "  >> COMMAND: " ch; then return; fi

        case $ch in
            1) run_ui_installer ;;
            2) install_fluidd ;;
            3) switch_ui ;;
            b|B) return ;;
        esac
    done
}

function install_fluidd() {
    if [ -f "$MODULES_DIR/ui/install_ui.sh" ]; then
        source "$MODULES_DIR/ui/install_ui.sh"
        do_install_fluidd
    else
        log_error "Module missing: ui/install_ui.sh"
    fi
}

function switch_ui() {
    if [ -f "$MODULES_DIR/ui/install_ui.sh" ]; then
        source "$MODULES_DIR/ui/install_ui.sh"
        install_ui_stack
    else
        log_error "Module missing: ui/install_ui.sh"
    fi
}

function run_extras_vision() {
    while true; do
        draw_header "VISION"

        local crowsnest
        crowsnest=$(check_dir_status "$HOME/crowsnest")
        local klipperscreen
        klipperscreen=$(check_dir_status "$HOME/KlipperScreen")

        echo "  ${C_GREEN}[1]${NC}  Crowsnest (Camera)     [$crowsnest]"
        echo "  ${C_NEON}[2]${NC}  KlipperScreen          [$klipperscreen]"
        echo ""
        echo "  [B] Back"
        echo ""
        if ! read -r -p "  >> COMMAND: " ch; then return; fi

        case $ch in
            1) install_crowsnest ;;
            2) dispatch_klipperscreen ;;
            b|B) return ;;
        esac
    done
}

function install_crowsnest() {
    if [ -f "$MODULES_DIR/vision/install_crowsnest.sh" ]; then
        source "$MODULES_DIR/vision/install_crowsnest.sh"
        do_install_crowsnest
    else
        log_error "Module missing: vision/install_crowsnest.sh"
    fi
}

function dispatch_klipperscreen() {
    draw_header "KLIPPERSCREEN"
    echo "  KlipperScreen is a touchscreen UI for Klipper."
    echo ""
    read -r -p "  Install KlipperScreen? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    
    if [ -d "$HOME/KlipperScreen" ]; then
        log_warn "KlipperScreen already installed."
        return
    fi
    
    log_info "Cloning KlipperScreen..."
    cd "$HOME" || return
    git clone https://github.com/KlipperScreen/KlipperScreen.git || {
        log_error "Failed to clone KlipperScreen."
        return 1
    }
    cd KlipperScreen
    ./scripts/KlipperScreen-install.sh
    log_success "KlipperScreen installed."
    read -r -p "  Press Enter..."
}

function run_extras_smartprobes() {
    while true; do
        draw_header "SMART PROBES"

        local smartprobe
        smartprobe=$(check_dir_status "$HOME/smart_probe")
        local carto
        carto=$(check_cartographer_status)
        local beacon
        beacon=$(check_beacon_status)
        local eddy
        eddy=$(check_btt_eddy_status)

        echo "  ${C_GREEN}[1]${NC}  Smart Probe            [$smartprobe]"
        echo "  ${C_NEON}[2]${NC}  Cartographer           [$carto]"
        echo "  ${C_NEON}[3]${NC}  Beacon Probe          [$beacon]"
        echo "  ${C_NEON}[4]${NC}  BTT Eddy               [$eddy]"
        echo ""
        echo "  [B] Back"
        echo ""
        if ! read -r -p "  >> COMMAND: " ch; then return; fi

        case $ch in
            1) run_smartprobe_menu ;;
            2) run_smartprobe_menu ;;
            3) run_smartprobe_menu ;;
            4) run_smartprobe_menu ;;
            b|B) return ;;
        esac
    done
}

function run_extras_beddistance() {
    draw_header "BED DISTANCE SENSOR"
    local status
    status=$(check_bed_distance_sensor_status)
    echo "  Status: $status"
    echo "  [1] Install"
    echo "  [2] Remove"
    if ! read -r -p "  >> " ch; then return; fi
    read -r -p "  Enter..." || return
}

function run_extras_toolchanger() {
    while true; do
        draw_header "TOOLCHANGER"

        local happyhare
        happyhare=$(check_dir_status "$HOME/happy_hare")
        local stealth
        stealth=$(check_stealthchanger_status)
        local madmax
        madmax=$(check_madmax_status)

        echo "  ${C_GREEN}[1]${NC}  Happy Hare             [$happyhare]"
        echo "  ${C_NEON}[2]${NC}  StealthChanger         [$stealth]"
        echo "  ${C_NEON}[3]${NC}  MADMAX                 [$madmax]"
        echo ""
        echo "  [B] Back"
        echo ""
        if ! read -r -p "  >> COMMAND: " ch; then return; fi

        case $ch in
            1) run_multimaterial_menu ;;
            2) run_multimaterial_menu ;;
            3) run_multimaterial_menu ;;
            b|B) return ;;
        esac
    done
}

function run_extras_tuning() {
    while true; do
        draw_header "TUNING"

        local katanaflow
        katanaflow=$(check_katanaflow_status)
        local shaketune
        shaketune=$(check_shaketune_status)
        local octoprint
        octoprint=$(check_octoprint_status)

        echo "  ${C_GREEN}[1]${NC}  KATANA Flow            [$katanaflow]"
        echo "  ${C_NEON}[2]${NC}  ShakeTune              [$shaketune]"
        echo "  ${C_NEON}[3]${NC}  OctoPrint              [$octoprint]"
        echo ""
        echo "  [B] Back"
        echo ""
        if ! read -r -p "  >> COMMAND: " ch; then return; fi

        case $ch in
            1) run_katana_flow ;;
            2) run_tuning_tools ;;
            3) run_tuning_tools ;;
            b|B) return ;;
        esac
    done
}

function install_octoprint() { run_octoprint_install; }

function run_extras_system() {
    while true; do
        draw_header "SYSTEM"

        local log2ram
        log2ram=$(check_log2ram_status)

        echo "  ${C_GREEN}[1]${NC}  Log2Ram                [$log2ram]"
        echo "  ${C_NEON}[2]${NC}  Create Backup"
        echo "  ${C_NEON}[3]${NC}  Restore Backup"
        echo ""
        echo "  [B] Back"
        echo ""
        if ! read -r -p "  >> COMMAND: " ch; then return; fi

        case $ch in
            1)
                if declare -f install_log2ram > /dev/null; then
                    install_log2ram
                else
                    source "$MODULES_DIR/extras/tuning.sh"
                    install_log2ram
                fi
                ;;
            2) run_backup_menu ;;
            3) restore_backup ;;
            b|B) return ;;
        esac
    done
}

function run_extras_security() {
    run_security_menu
}

# ============================================================
# MENU 4: FORGE
# ============================================================

function run_forge_menu() {
    if [ -f "$MODULES_DIR/hardware/flash_engine.sh" ]; then
        source "$MODULES_DIR/hardware/flash_engine.sh"
        run_hal_flasher
    else
        log_error "Module missing: hardware/flash_engine.sh"
    fi
}

# ============================================================
# MENU 5: DIAGNOSE
# ============================================================

function run_diagnose_menu() {
    if declare -f dispatch_diagnose_menu > /dev/null; then
        dispatch_diagnose_menu
    else
        log_error "Dispatcher 'dispatch_diagnose_menu' nicht gefunden."
        sleep 2
    fi
}

# ============================================================
# MENU 6: SETTINGS
# ============================================================

function run_settings_menu() {
    if declare -f dispatch_settings_menu > /dev/null; then
        dispatch_settings_menu
    else
        log_error "Dispatcher 'dispatch_settings_menu' nicht gefunden."
        sleep 2
    fi
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
    box_row_center "${C_GREEN}SUCCESS${NC}"
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
    warn_row_center "${C_RED}ERROR${NC}"
    draw_warn_mid
    warn_row " "
    warn_row " ${C_WHITE}$message${NC}"
    warn_row " "
    draw_warn_bot
    echo ""
}

# ============================================================
# BACKWARD COMPATIBILITY ALIASES
# ============================================================

# Legacy function aliases for other modules
function draw_top() { draw_box_top; }
function draw_mid() { draw_box_mid; }
function draw_bot() { draw_box_bot; }
function draw_line() { draw_box_mid; }

# Alias: draw_sub_* -> draw_box_* (identical behavior)
function draw_sub_top() { draw_box_top; }
function draw_sub_mid() { draw_box_mid; }
function draw_sub_bot() { draw_box_bot; }

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
    local line
    line=$(printf "%-5s %-20s %s" "$num" "$title" "$desc")
    box_row "$line"
}

# ============================================================
# PIXEL-PERFECT ALIGNMENT
# ============================================================

function print_status_line() {
    local label="$1"
    local status="$2"
    local color="${3:-$C_NEON}"
    printf "  ${C_PURPLE}║${NC} %-25s | %b%-40s\e[0m ${C_PURPLE}║${NC}\n" "$label" "$color" "$status"
}
