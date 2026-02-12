#!/bin/bash
################################################################################
#  ⚔️  KATANAOS - THE KLIPPER BLADE v1.5
# ------------------------------------------------------------------------------
#  PRO-GRADE KLIPPER INSTALLATION & MANAGEMENT SUITE
################################################################################

# --- [ 0. CORE SETUP ] ---
if [ "$EUID" -eq 0 ]; then echo "STOP. RUN AS USER."; exit 1; fi

# OS Compatibility Check
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" != "debian" && "$ID" != "raspbian" && "$ID_LIKE" != *"debian"* ]]; then
        echo -e "\033[38;5;196m[!!] UNSUPPORTED OS. KATANAOS requires Debian-based systems.\033[0m"
        exit 1
    fi
fi

USER_NAME=$USER
HOME_DIR=$HOME
PRINTER_DATA="$HOME_DIR/printer_data"
CONFIG_DIR="$PRINTER_DATA/config"
LOG_DIR="$PRINTER_DATA/logs"
WIDTH=72  # Gesamtbreite der Box

# --- [ 1. VISUAL ENGINE ] ---
C_PURPLE=$'\033[38;5;93m'
C_PINK=$'\033[38;5;201m'
C_CYAN=$'\033[38;5;51m'
C_NEON=$'\033[38;5;87m'
C_GREEN=$'\033[38;5;46m'
C_RED=$'\033[38;5;196m'
C_GREY=$'\033[38;5;238m'
C_TXT=$'\033[38;5;255m'
C_WARN=$'\033[38;5;226m'
NC=$'\033[0m'

# --- PIXEL PERFECT HELPER ---
# Diese Funktion erzwingt gerade Linien, egal wie viele Farbcodes im Text sind.
print_box_line() {
    local content="$1"
    
    # 1. Entferne alle Farbcodes, um die ECHTE Textlänge zu messen
    local clean_content=$(echo -e "$content" | sed "s/\x1B\[[0-9;]*[a-zA-Z]//g")
    
    # 2. Berechne die Länge
    local len=${#clean_content}
    
    # 3. Berechne die nötigen Leerzeichen (Breite - Rahmen links/rechts - Textlänge)
    local pad_len=$((WIDTH - 2 - len))
    
    # 4. Erzeuge die Leerzeichen
    if [ $pad_len -lt 0 ]; then pad_len=0; fi
    local padding=$(printf '%*s' "$pad_len")
    
    # 5. Drucke die Zeile: Rahmen + Farbiger Inhalt + Padding + Rahmen
    echo -e "${C_PURPLE}║${NC}${content}${padding}${C_PURPLE}║${NC}"
}

draw_line() { printf "${C_PURPLE}╠═$(printf '═%.0s' $(seq 1 $((WIDTH-2))))═╣${NC}\n"; }
draw_top()  { printf "${C_PURPLE}╔═$(printf '═%.0s' $(seq 1 $((WIDTH-2))))═╗${NC}\n"; }
draw_bot()  { printf "${C_PURPLE}╚═$(printf '═%.0s' $(seq 1 $((WIDTH-2))))═╝${NC}\n"; }

status_row() {
    local name=$1 check_cmd=$2 desc=$3 
    local state_txt="OFFLINE"
    local state_col=$C_GREY
    local icon_sym="○"

    if eval "$check_cmd"; then 
        state_txt="ONLINE "
        state_col=$C_GREEN
        icon_sym="●"
    fi
    
    # Baue den String zusammen. WICHTIG: Die Formatierung %-Xs hier ist nur für Abstände im Text, nicht für die Box!
    # Wir übergeben den GANZEN String an print_box_line, die kümmert sich um den rechten Rand.
    local row_content="  ${state_col}${icon_sym}${NC} ${C_NEON}$(printf "%-15s" "$name")${NC} : ${state_col}$(printf "%-8s" "$state_txt")${NC} ${C_GREY}▒ ${desc}${NC}"
    
    print_box_line "$row_content"
}

menu_item() {
    local id=$1 title=$2 desc=$3
    # Auch hier: Wir bauen erst den Inhalt, die Box-Funktion macht den Rest.
    local row_content=" ${C_PINK}[${id}]${NC} ${C_CYAN}$(printf "%-25s" "$title")${NC} ${C_GREY}${desc}${NC}"
    print_box_line "$row_content"
}

# --- [ 2. INTERFACE RENDERER ] ---
draw_gui() {
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
    echo -e "${C_NEON}    >> SYSTEM OVERLORD // COMMAND INTERFACE${NC}"
    
    draw_top
    print_box_line " ${C_TXT}SYSTEM STATUS MATRIX${NC}"
    draw_line
    status_row "Klipper" "[ -d ~/klipper ]" "3D Printer Firmware"
    status_row "Kalico" "[ -d ~/kalico ]" "Alternative Firmware"
    status_row "Moonraker" "[ -d ~/moonraker ]" "API Server"
    status_row "Mainsail/Fluidd" "[ -d ~/mainsail ] || [ -d ~/fluidd ]" "Web Interface"
    status_row "Crowsnest" "[ -d ~/crowsnest ]" "Webcam Daemon"
    status_row "KlipperScreen" "[ -d ~/KlipperScreen ]" "Touch Interface"
    draw_line
    status_row "KAMP" "[ -d ~/Klipper-Adaptive-Meshing-Purging ]" "Adaptive Meshing"
    status_row "ShakeTune" "[ -d ~/klippain_shaketune ]" "Input Shaper Tools"
    status_row "Beacon3D" "[ -d ~/beacon_klipper ]" "Eddy Current Probe"
    status_row "Cartographer" "[ -d ~/cartographer-klipper ]" "Eddy Current Probe"
    status_row "System Sec" "command -v ufw >/dev/null" "Firewall & Log2Ram"
    draw_bot
    
    echo ""
    draw_top
    print_box_line " ${C_TXT}COMMAND DECK${NC}"
    draw_line
    print_box_line " ${C_TXT}[ INSTALLATION ]${NC}"
    menu_item "1" "AUTO-PILOT" "Full Stack Install (God Mode)"
    menu_item "2" "CORE ENGINE" "Klipper, Moonraker & Nginx"
    menu_item "3" "WEB INTERFACE" "Mainsail / Fluidd"
    menu_item "4" "HMI & VISION" "Crowsnest & KlipperScreen"
    draw_line
    print_box_line " ${C_TXT}[ CONFIGURATION ]${NC}"
    menu_item "5" "THE FORGE" "Flash & CAN-Bus Automator"
    menu_item "6" "EXTENSIONS" "KAMP, ShakeTune, Probes"
    menu_item "7" "GET CONFIG" "Copy Example Printer Config"
    draw_line
    print_box_line " ${C_TXT}[ MAINTENANCE ]${NC}"
    menu_item "8" "SYSTEM PREP" "Updates & Dependencies"
    menu_item "9" "SEC & BACKUP" "Firewall, Log2Ram & Zip Backup"
    menu_item "E" "ENGINE MANAGER" "Klipper <-> Kalico Switch"
    draw_line
    menu_item "X" "EXIT" "Close KATANAOS"
    draw_bot
    echo ""
    echo -e "${C_GREY}  USER: $USER_NAME  |  IP: $(hostname -I | cut -d' ' -f1)  |  SYSTEM: READY${NC}"
    echo -e "${C_GREY}  [ TIP: Select (1-E) | 'X' Exit ]${NC}"
}

# --- [ 3. LOGIC ENGINES ] ---
exec_silent() {
    echo -e "\n${C_CYAN}  [..] EXECUTING: $1...${NC}"
    echo -e "${C_GREY}  >> ------------------------------------------${NC}"
    eval "$2"
    local status=$?
    echo -e "${C_GREY}  << ------------------------------------------${NC}"
    if [ $status -eq 0 ]; then echo -e "${C_GREEN}  [OK] $1 COMPLETE${NC}"; else echo -e "${C_RED}  [!!] $1 FAILED${NC}"; fi
}

do_prep() {
    exec_silent "Update Apt" "sudo apt update"
    exec_silent "Install Tools" "sudo apt install -y git zip unzip mc htop nano usbutils ranger ncdu can-utils fd-find build-essential gcc-arm-none-eabi libnewlib-arm-none-eabi python3-pip python3-venv virtualenv python3-virtualenv dfu-util nginx libsodium-dev libffi-dev iptraf-ng tcpdump"
    exec_silent "Purge Bloat" "sudo apt autoremove -y modem* cups* pulse* avahi* triggerhappy*"
    read -p "  Press Enter..."
}

do_core() {
    mkdir -p "$CONFIG_DIR" "$LOG_DIR" "$PRINTER_DATA/comms"
    exec_silent "Clone Klipper" "[ -d ~/klipper ] || git clone https://github.com/Klipper3d/klipper.git ~/klipper"
    exec_silent "Build Env" "rm -rf ~/klipper-env && virtualenv -p python3 ~/klipper-env && ~/klipper-env/bin/pip install -U pip && ~/klipper-env/bin/pip install -r ~/klipper/scripts/klippy-requirements.txt"
    
    sudo tee /etc/systemd/system/klipper.service > /dev/null << EOF
[Unit]
Description=Klipper
After=network.target
[Service]
Type=simple
User=$USER_NAME
RemainAfterExit=yes
ExecStart=$HOME_DIR/klipper-env/bin/python $HOME_DIR/klipper/klippy/klippy.py $CONFIG_DIR/printer.cfg -l $LOG_DIR/klippy.log -a $PRINTER_DATA/comms/klippy.sock
Restart=always
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable klipper.service >/dev/null 2>&1
    
    exec_silent "Clone Moonraker" "[ -d ~/moonraker ] || git clone https://github.com/Arksine/moonraker.git ~/moonraker"
    
    cat > "$CONFIG_DIR/moonraker.conf" << EOF
[server]
host: 0.0.0.0
port: 7125
klippy_uds_address: $PRINTER_DATA/comms/klippy.sock
[authorization]
force_logins: False
cors_domains:
    *
    *.local
    *.lan
    *://app.fluidd.xyz
    *://my.mainsail.xyz
trusted_clients:
    10.0.0.0/8
    127.0.0.0/8
    169.254.0.0/16
    172.16.0.0/12
    192.168.0.0/16
    FE80::/10
    ::1/128
[file_manager]
enable_object_processing: True
[update_manager]
channel: dev
refresh_interval: 168
[update_manager mainsail]
type: web
channel: stable
repo: mainsail-crew/mainsail
path: ~/mainsail
[update_manager fluidd]
type: web
channel: stable
repo: fluidd-core/fluidd
path: ~/fluidd
EOF
    exec_silent "Install Moonraker" "~/moonraker/scripts/install-moonraker.sh -f -c $CONFIG_DIR/moonraker.conf"
    
    if [ ! -f "$CONFIG_DIR/printer.cfg" ]; then
        echo -e "${C_PINK}  >> No printer.cfg found.${NC}"
        echo -e "  1) Create Minimal (Virtual)  2) Copy from Klipper Examples"
        read -p "  >> " cfgo
        if [ "$cfgo" == "2" ]; then
             do_get_config
        else
             echo -e "[include mainsail.cfg]\n[mcu]\nserial: /dev/null\n[printer]\nkinematics: none\nmax_velocity: 100\nmax_accel: 100" > "$CONFIG_DIR/printer.cfg"
        fi
        touch "$CONFIG_DIR/mainsail.cfg"
    fi

    sudo systemctl restart moonraker
    read -p "  Press Enter..."
}

do_ui() {
    echo -e "  1) Mainsail  2) Fluidd"
    read -p "  >> " uich
    local UI="mainsail"
    [ "$uich" == "2" ] && UI="fluidd"
    exec_silent "Install $UI" "rm -rf ~/$UI && mkdir -p ~/$UI && cd ~/$UI && wget -q -O ui.zip https://github.com/${UI}-crew/${UI}/releases/latest/download/${UI}.zip || wget -q -O ui.zip https://github.com/${UI}-core/${UI}/releases/latest/download/${UI}.zip && unzip -o ui.zip && rm ui.zip"
    
    # NGINX Configuration
    sudo tee /etc/nginx/sites-available/klipper > /dev/null << EOF
server {
    listen 80;
    server_name _;
    client_max_body_size 500M;
    location / { root $HOME_DIR/$UI; index index.html; try_files \$uri \$uri/ /index.html; }
    location /server { proxy_pass http://127.0.0.1:7125; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade"; }
    location /websocket { proxy_pass http://127.0.0.1:7125/websocket; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade"; }
}
EOF
    sudo rm -f /etc/nginx/sites-enabled/default
    sudo ln -sf /etc/nginx/sites-available/klipper /etc/nginx/sites-enabled/
    sudo systemctl restart nginx
    # Fix: Ensure Nginx can access the home directory immediately
    chmod 755 "$HOME_DIR"
    read -p "  Press Enter..."
}

do_hmi() {
    echo -e "  Selection: 1) Crowsnest  2) KlipperScreen  3) FULL HMI SUITE  B) < BACK"
    read -p "  >> " mch
    if [[ "$mch" == "b" || "$mch" == "B" ]]; then return; fi
    
    if [[ "$mch" == "1" || "$mch" == "3" ]]; then
        exec_silent "Install Crowsnest" "rm -rf ~/crowsnest && git clone https://github.com/mainsail-crew/crowsnest.git ~/crowsnest && cd ~/crowsnest && sudo make install"
    fi
    if [[ "$mch" == "2" || "$mch" == "3" ]]; then
        exec_silent "Install KlipperScreen" "rm -rf ~/KlipperScreen && git clone https://github.com/KlipperScreen/KlipperScreen.git ~/KlipperScreen && ~/KlipperScreen/scripts/KlipperScreen-install.sh"
    fi
    read -p "  Press Enter..."
}

do_can_setup() {
    echo -e "${C_CYAN}  >> Automating CAN-Bus & Network Interfaces...${NC}"
    
    # Ensure dependencies for network management
    exec_silent "Install Network Tools" "sudo apt install -y ifupdown can-utils"

    # Ensure main interfaces file sources the .d directory
    if ! grep -q "source /etc/network/interfaces.d/*" /etc/network/interfaces; then
        echo -e "\nsource /etc/network/interfaces.d/*" | sudo tee -a /etc/network/interfaces > /dev/null
    fi

    # Configure ETH0 (Standard DHCP)
    sudo tee /etc/network/interfaces.d/eth0 > /dev/null << EOF
auto eth0
allow-hotplug eth0
iface eth0 inet dhcp
EOF

    # Configure CAN0 (1M Bitrate, 1024 Queue)
    sudo tee /etc/network/interfaces.d/can0 > /dev/null << EOF
allow-hotplug can0
iface can0 can static
    bitrate 1000000
    up ip link set \$IFACE txqueuelen 1024
EOF
    exec_silent "Bring up CAN0" "sudo ip link set can0 up type can bitrate 1000000 txqueuelen 1024 2>/dev/null || true"
    echo -e "${C_GREEN}  [OK] Network configuration updated (eth0 + can0). Reboot recommended.${NC}"
}

do_forge() {
    if [ ! -d ~/klipper ]; then
        echo -e "${C_RED}  [!!] Klipper repository not found. Please install Core Engine (Option 2) first.${NC}"
        read -p "  Press Enter..."
        return
    fi
    cd ~/klipper
    echo -e "${C_CYAN}  === THE FORGE: MCU FLASHING ENGINE ===${NC}"
    echo -e "  1) Build & Flash via USB/Serial"
    echo -e "  2) Build & Flash Host MCU (Pi)"
    echo -e "  3) Setup CAN-Bus Network"
    echo -e "  4) Scan for Serial Devices"
    echo -e "  B) < BACK"
    read -p "  >> " f_choice

    case $f_choice in
        [Bb]) return ;;
        1)
            DEVICES=$(ls /dev/serial/by-id/* 2>/dev/null)
            if [ -z "$DEVICES" ]; then
                echo -e "${C_RED}  [!!] NO DEVICES FOUND! Connect MCU or check permissions.${NC}"
            else
                echo -e "${C_NEON}  Found Devices:${NC}"
                PS3="  Select MCU to flash: "
                select dev in $DEVICES; do
                    if [ -n "$dev" ]; then
                        echo -e "  Targeting: $dev"
                        exec_silent "Configuring Firmware" "make menuconfig"
                        exec_silent "Building Firmware" "make clean && make -j4"
                        exec_silent "Flashing MCU" "make flash FLASH_DEVICE=$dev"
                        echo -e "${C_CYAN}  >> Firmware binary: ~/klipper/out/klipper.bin${NC}"
                        echo -e "${C_GREY}  (If USB flash failed, copy this file to an SD card and rename it if needed)${NC}"
                        break
                    fi
                done
            fi
            ;;
        2)
            exec_silent "Building Host MCU" "make clean && make menuconfig && make flash"
            sudo cp ./scripts/klipper-mcu.service /etc/systemd/system/
            sudo systemctl daemon-reload && sudo systemctl enable klipper-mcu.service
            ;;
        3) do_can_setup ;;
        4)
            DEVICES=$(ls /dev/serial/by-id/* 2>/dev/null)
            if [ -z "$DEVICES" ]; then
                echo -e "${C_RED}  [!!] NO SERIAL DEVICES FOUND in /dev/serial/by-id/.${NC}"
            else
                ls -l /dev/serial/by-id/*
            fi
            ;;
    esac
    read -p "  Press Enter..."
}

do_extras() {
    [ -d ~/klipper-env ] && [ ! -d ~/klippy-env ] && ln -sf ~/klipper-env ~/klippy-env
    echo -e "  1) Install All (KAMP, ShakeTune + Probe Selector)"
    echo -e "  2) Custom Selection"
    echo -e "  3) Install RatOS (Clone Repository)"
    echo -e "  B) < BACK"
    read -p "  >> " exch
    
    if [[ "$exch" == "b" || "$exch" == "B" ]]; then return; fi

    is_yes() {
        [[ "$1" =~ ^([YyJj]|[Yy][Ee][Ss]|[Jj][Aa])$ ]]
    }

    # Logik für Option 1 (ALLES installieren)
    if [[ "$exch" == "1" ]]; then
        exec_silent "KAMP" "rm -rf ~/Klipper-Adaptive-Meshing-Purging && git clone https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging.git ~/Klipper-Adaptive-Meshing-Purging && cp ~/Klipper-Adaptive-Meshing-Purging/Configuration/KAMP_Settings.cfg $CONFIG_DIR/"
        exec_silent "ShakeTune" "rm -rf ~/klippain_shaketune && git clone https://github.com/Frix-x/klippain-shaketune.git ~/klippain_shaketune && ~/klippain_shaketune/install.sh"
        
        echo -e "${C_WARN}  >> Which Probe/Scanner are you using?${NC}"
        echo -e "  1) Beacon3D  2) Cartographer  3) None"
        read -p "  >> " probech
        if [ "$probech" == "1" ]; then
             exec_silent "Beacon3D" "rm -rf ~/beacon_klipper && git clone https://github.com/beacon3d/beacon_klipper.git ~/beacon_klipper && ~/beacon_klipper/install.sh"
        elif [ "$probech" == "2" ]; then
             exec_silent "Cartographer3D" "rm -rf ~/cartographer-klipper && git clone https://github.com/Cartographer3D/cartographer-klipper.git ~/cartographer-klipper && ~/cartographer-klipper/install.sh"
        fi

    elif [[ "$exch" == "3" ]]; then
        exec_silent "RatOS" "rm -rf ~/RatOS && git clone https://github.com/Rat-OS/RatOS.git ~/RatOS"
        echo -e "${C_GREEN}  [OK] RatOS Repository cloned to ~/RatOS${NC}"

    # FEHLENDER BLOCK für Option 2 (Einzelabfrage)
    elif [[ "$exch" == "2" ]]; then
        echo -e "${C_CYAN}  >> Custom Selection Mode${NC}"
        
        # 1. KAMP Abfrage
        read -p "  Install KAMP (Adaptive Meshing)? (y/n, j/n): " kamp_choice
        if is_yes "$kamp_choice"; then
            exec_silent "KAMP" "rm -rf ~/Klipper-Adaptive-Meshing-Purging && git clone https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging.git ~/Klipper-Adaptive-Meshing-Purging && cp ~/Klipper-Adaptive-Meshing-Purging/Configuration/KAMP_Settings.cfg $CONFIG_DIR/"
        fi

        # 2. ShakeTune Abfrage
        read -p "  Install ShakeTune (Input Shaper Tools)? (y/n, j/n): " st_choice
        if is_yes "$st_choice"; then
            exec_silent "ShakeTune" "rm -rf ~/klippain_shaketune && git clone https://github.com/Frix-x/klippain-shaketune.git ~/klippain_shaketune && ~/klippain_shaketune/install.sh"
        fi

        # 3. Probe Abfrage
        echo -e "${C_WARN}  >> Install Probe/Scanner?${NC}"
        echo -e "  1) Beacon3D  2) Cartographer  3) None"
        read -p "  >> " probech
        if [ "$probech" == "1" ]; then
             exec_silent "Beacon3D" "rm -rf ~/beacon_klipper && git clone https://github.com/beacon3d/beacon_klipper.git ~/beacon_klipper && ~/beacon_klipper/install.sh"
        elif [ "$probech" == "2" ]; then
             exec_silent "Cartographer3D" "rm -rf ~/cartographer-klipper && git clone https://github.com/Cartographer3D/cartographer-klipper.git ~/cartographer-klipper && ~/cartographer-klipper/install.sh"
        fi

        # 4. RatOS Abfrage
        read -p "  Install RatOS (Clone Repo)? (y/n, j/n): " rat_choice
        if is_yes "$rat_choice"; then
             exec_silent "RatOS" "rm -rf ~/RatOS && git clone https://github.com/Rat-OS/RatOS.git ~/RatOS"
        fi
    else
        echo -e "${C_RED}  Invalid selection.${NC}"
    fi

    if systemctl list-unit-files | grep -q '^moonraker\.service'; then
        sudo systemctl restart moonraker
    fi
    read -p "  Press Enter..."
}

do_get_config() {
    if [ ! -d ~/klipper/config ]; then 
        echo -e "${C_RED}  [!!] Klipper configs not found. Install Core Engine (Option 2) first.${NC}"
        read -p "  Press Enter..."
        return 
    fi

    mapfile -t generic_cfgs < <(find ~/klipper/config -maxdepth 1 -type f -name 'generic-*.cfg' -printf '%f\n' | sort)
    if [ ${#generic_cfgs[@]} -eq 0 ]; then
        echo -e "${C_RED}  [!!] No generic config templates found in ~/klipper/config.${NC}"
        read -p "  Press Enter..."
        return
    fi

    echo -e "${C_CYAN}  >> Select a config template to copy to printer.cfg:${NC}"
    PS3="  Enter number (q to quit): "
    select filename in "${generic_cfgs[@]}"; do
        if [ -n "$filename" ]; then
            mkdir -p "$CONFIG_DIR"
            cp ~/klipper/config/$filename "$CONFIG_DIR/printer.cfg"
            echo -e "${C_GREEN}  [OK] Copied $filename to $CONFIG_DIR/printer.cfg${NC}"
            break
        elif [ "$REPLY" == "q" ]; then
            break
        else
            echo "Invalid selection."
        fi
    done
}

do_maint() {
    echo -e "  1) Security (Firewall/Log2Ram)  2) Backup Config"
    read -p "  >> " mch
    if [ "$mch" == "1" ]; then
        exec_silent "Log2Ram" "echo 'deb [signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian/ bookworm main' | sudo tee /etc/apt/sources.list.d/azlux.list && sudo wget -O /usr/share/keyrings/azlux-archive-keyring.gpg https://azlux.fr/repo.gpg && sudo apt update && sudo apt install -y log2ram"
        exec_silent "UFW Firewall" "sudo apt install -y ufw && sudo ufw default deny incoming && sudo ufw default allow outgoing && sudo ufw allow 22/tcp && sudo ufw allow 80/tcp && sudo ufw allow 7125/tcp && sudo ufw --force enable"
        sudo usermod -a -G tty,dialout,gpio,i2c $USER_NAME
        sudo chown -R $USER_NAME:$USER_NAME "$PRINTER_DATA"
        chmod 755 $HOME_DIR
        sudo systemctl restart klipper moonraker nginx
        echo -e "${C_WARN}  [!] IMPORTANT: REBOOT REQUIRED to apply group permissions (dialout/tty)!${NC}"
    fi
    if [ "$mch" == "2" ]; then
        TS=$(date +%Y%m%d_%H%M%S)
        BACKUP_FILE="$HOME_DIR/klipper_backup_$TS.zip"
        exec_silent "Backup Config" "zip -r $BACKUP_FILE $PRINTER_DATA/config"
        echo -e "${C_GREEN}  >> Backup created: $BACKUP_FILE${NC}"
    fi
    read -p "  Press Enter..."
}

do_engine_manager() {
    echo -e "${C_CYAN}  === ENGINE MANAGER ===${NC}"
    echo -e "  1) Deploy Kalico Environment (Download & Build)"
    echo -e "  2) Switch Active Engine (Klipper <-> Kalico)"
    echo -e "  B) < BACK"
    read -p "  >> " e_act

    if [[ "$e_act" == "b" || "$e_act" == "B" ]]; then return; fi

    if [ "$e_act" == "1" ]; then
        echo -e "${C_CYAN}  >> Deploying Kalico Environment...${NC}"
        exec_silent "Clone Kalico" "[ -d ~/kalico ] || git clone https://github.com/KalicoCrew/kalico.git ~/kalico"
        exec_silent "Build Env" "rm -rf ~/kalico-env && virtualenv -p python3 ~/kalico-env && ~/kalico-env/bin/pip install -U pip && ~/kalico-env/bin/pip install -r ~/kalico/scripts/klippy-requirements.txt"
        echo -e "${C_GREEN}  >> Kalico Deployed. You can now use option 2 to switch engines.${NC}"
        read -p "  Press Enter..."
    elif [ "$e_act" == "2" ]; then
        echo -e "  Select Active Engine:"
        echo "  1) Klipper (Standard)"
        echo "  2) Kalico (High-Performance)"
        read -p "  >> " eng_ch

        TARGET_DIR="$HOME_DIR/klipper"
        TARGET_ENV="$HOME_DIR/klipper-env"
        NAME="Klipper"

        if [ "$eng_ch" == "2" ]; then
            TARGET_DIR="$HOME_DIR/kalico"
            TARGET_ENV="$HOME_DIR/kalico-env"
            NAME="Kalico"
        fi

        if [ ! -d "$TARGET_DIR" ]; then
            echo -e "${C_RED}  [!!] $NAME is not deployed. Please deploy it first (Option 1).${NC}"
            read -p "  Press Enter..."
            return
        fi

        sudo tee /etc/systemd/system/klipper.service > /dev/null << EOF
[Unit]
Description=3D Printer Firmware Engine ($NAME)
After=network.target
[Service]
Type=simple
User=$USER_NAME
RemainAfterExit=yes
ExecStart=$TARGET_ENV/bin/python $TARGET_DIR/klippy/klippy.py $CONFIG_DIR/printer.cfg -l $LOG_DIR/klippy.log -a $PRINTER_DATA/comms/klippy.sock
Restart=always
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF
        exec_silent "Switching Engine to $NAME" "sudo systemctl daemon-reload && sudo systemctl restart klipper"
        echo -e "${C_GREEN}  >> System is now successfully running on $NAME!${NC}"
        read -p "  Press Enter..."
    else
        echo -e "${C_RED}  Invalid selection.${NC}"
        sleep 1
    fi
}

# --- [ 4. MAIN LOOP ] ---
while true; do
    draw_gui
    echo -ne "${C_PINK}  >> COMMAND:${NC} "
    read choice
    case $choice in
        1) do_prep; do_core; do_ui; do_hmi; do_extras; do_maint ;;
        2) do_core ;;
        3) do_ui ;;
        4) do_hmi ;;
        5) do_forge ;;
        6) do_extras ;;
        7) do_get_config ;;
        8) do_prep ;;
        9) do_maint ;;
        [Ee]) do_engine_manager ;;
        [Xx]) 
            clear
            echo -e "${C_PURPLE}"
            cat << "EOF"
          __________________
         |  _______________ |
         | |              | | 
         | |    ______    | |
         | |   /     /\   | |
         | |  /     /  \  | |
         | | /_____/    \ | |
         | | \     \    / | |
         | |  \     \  /  | |
         | |   \_____\/   | |
         | |______________| |
         |__________________|
                  ||
             _____||_____
           |    [DONE]    |
           |______________|
                 \  /
                  \/
EOF
            echo -e "${NC}"
            exit 0 ;;
        *) echo -e "${C_RED}  Invalid Option!${NC}"; sleep 1 ;;
    esac
done
