#!/bin/bash
# ==============================================================================
# KATANA MODULE: THE FORGE (Flash Engine)
# Usage: Firmware Build & Flash
# Rule: Flash method is determined by build artifact, NOT user choice
# ==============================================================================

# --- WORKFLOW STATE PERSISTENCE ---
KATANA_STATE_FILE="$HOME/.katana_workflow_state"

function save_workflow_state() {
    # Usage: save_workflow_state "STEP" "BOARD_NAME" "DETAILS"
    local step="$1"
    local board="${2:-unknown}"
    local details="${3:-}"
    cat > "$KATANA_STATE_FILE" <<EOF
WORKFLOW_STEP="$step"
WORKFLOW_BOARD="$board"
WORKFLOW_DETAILS="$details"
WORKFLOW_TIMESTAMP="$(date '+%Y-%m-%d %H:%M')"
EOF
}

function load_workflow_state() {
    if [ -f "$KATANA_STATE_FILE" ]; then
        source "$KATANA_STATE_FILE"
        return 0
    fi
    return 1
}

function clear_workflow_state() {
    rm -f "$KATANA_STATE_FILE"
    unset WORKFLOW_STEP WORKFLOW_BOARD WORKFLOW_DETAILS WORKFLOW_TIMESTAMP 2>/dev/null
}

# === MCU SCANNER — Alle angeschlossenen MCUs anzeigen ===
function run_mcu_scanner() {
    draw_header "MCU SCANNER"
    echo ""
    local found=0

    # --- CAN-Bus ---
    echo "  ${C_NEON}━━━ CAN-Bus ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if ip link show can0 &>/dev/null; then
        echo "  Interface: ${C_GREEN}can0 AKTIV${NC}"
        echo ""
        local can_out
        can_out=$(python3 ~/katapult/scripts/flashtool.py -i can0 -q 2>/dev/null || true)
        if [ -n "$can_out" ] && echo "$can_out" | grep -q "UUID:"; then
            echo "$can_out" | while IFS= read -r line; do
                if [[ "$line" == *"UUID:"* ]]; then
                    local uuid app
                    uuid=$(echo "$line" | grep -oP 'UUID: \K[0-9a-f]+')
                    app=$(echo "$line" | grep -oP 'Application: \K\w+')
                    echo "  ${C_GREEN}●${NC} UUID: ${C_GREEN}${uuid}${NC}  App: ${app}"
                    echo "    → printer.cfg: ${C_NEON}canbus_uuid: ${uuid}${NC}"
                    echo ""
                    found=1
                fi
            done
        else
            echo "  ${C_RED}●${NC} Keine CAN-Geräte gefunden"
            echo "    Tipps: Board eingesteckt? CAN-Bridge aktiv?"
        fi
    else
        echo "  ${C_RED}●${NC} can0 Interface nicht aktiv"
        echo "    → Nutze [5] CAN-Bus Einrichten"
    fi

    # --- USB Serial ---
    echo ""
    echo "  ${C_NEON}━━━ USB Serial ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if [ -d /dev/serial/by-id/ ] && [ "$(ls /dev/serial/by-id/ 2>/dev/null)" ]; then
        for serial in /dev/serial/by-id/*; do
            echo "  ${C_GREEN}●${NC} $(basename "$serial")"
            echo "    → printer.cfg: ${C_NEON}serial: ${serial}${NC}"
            echo ""
            found=1
        done
    else
        echo "  ${C_RED}●${NC} Keine USB-Serial Geräte gefunden"
    fi

    # --- USB DFU (Bootloader Mode) ---
    echo ""
    echo "  ${C_NEON}━━━ USB DFU / Bootloader ━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    local dfu_devices
    dfu_devices=$(lsusb 2>/dev/null | grep -iE "0483:df11|1d50:6177|2e8a:0003" || true)
    if [ -n "$dfu_devices" ]; then
        echo "$dfu_devices" | while IFS= read -r line; do
            echo "  ${C_ORANGE}●${NC} ${line}"
            found=1
        done
        echo "    → Board ist im Bootloader-Modus (bereit zum Flashen)"
    else
        echo "  (Keine Geräte im DFU/Bootloader-Modus)"
    fi

    # --- Zusammenfassung ---
    echo ""
    echo "  ────────────────────────────────────────────────────"
    if [ $found -eq 1 ]; then
        log_success "MCUs gefunden. Kopiere die Werte oben in deine printer.cfg."
    else
        log_warn "Keine MCUs erkannt."
        echo "  Mögliche Ursachen:"
        echo "  - USB-Kabel prüfen (Datenkabel, nicht nur Ladekabel)"
        echo "  - Board eingeschaltet?"
        echo "  - BOOT-Jumper entfernt nach Flash?"
        echo "  - Klipper Service läuft? → sudo systemctl start klipper"
    fi

    echo ""
    read -r -p "  Press Enter..."
}

function run_hal_flasher() {
    while true; do
        draw_header "🔧 THE FORGE - Build & Flash Firmware"

        # --- CHECK FOR PENDING WORKFLOW ---
        if load_workflow_state; then
            echo ""
            echo "  ${C_ORANGE}┌─── OFFENER WORKFLOW ────────────────────────────┐${NC}"
            echo "  ${C_ORANGE}│${NC}  Letzter Schritt: ${C_GREEN}${WORKFLOW_STEP}${NC}"
            echo "  ${C_ORANGE}│${NC}  Board: ${C_NEON}${WORKFLOW_BOARD}${NC}"
            echo "  ${C_ORANGE}│${NC}  Zeit: ${WORKFLOW_TIMESTAMP}"
            case "$WORKFLOW_STEP" in
                KATAPULT_FLASHED)
                    echo "  ${C_ORANGE}│${NC}"
                    echo "  ${C_ORANGE}│${NC}  ${C_GREEN}→ Nächster Schritt: KLIPPER BAUEN & FLASHEN${NC}"
                    echo "  ${C_ORANGE}└────────────────────────────────────────────────┘${NC}"
                    echo ""
                    read -r -p "  Klipper-Flash jetzt fortsetzen? [Y/n]: " resume
                    if [[ ! "$resume" =~ ^[nN] ]]; then
                        run_build_and_flash
                        continue
                    fi
                    ;;
                KLIPPER_BUILT)
                    echo "  ${C_ORANGE}│${NC}"
                    echo "  ${C_ORANGE}│${NC}  ${C_GREEN}→ Nächster Schritt: FIRMWARE FLASHEN${NC}"
                    echo "  ${C_ORANGE}└────────────────────────────────────────────────┘${NC}"
                    echo ""
                    read -r -p "  Flash-Vorgang jetzt fortsetzen? [Y/n]: " resume
                    if [[ ! "$resume" =~ ^[nN] ]]; then
                        run_build_and_flash
                        continue
                    fi
                    ;;
                *)
                    echo "  ${C_ORANGE}└────────────────────────────────────────────────┘${NC}"
                    ;;
            esac
            echo ""
        fi

        echo ""
        echo "  ${C_GREEN}[1]${NC}  Katapult (Bootloader)      (SCHRITT 1: Bootloader flashen)"
        echo "  ${C_NEON}[2]${NC}  Build Klipper Firmware     (SCHRITT 2: Firmware bauen & flashen)"
        echo "  ${C_NEON}[3]${NC}  Saved Boards Manager       (Gespeicherte Configs)"
        echo "  ${C_NEON}[4]${NC}  Linux Host MCU             (Raspberry Pi als MCU)"
        echo ""
        echo "  ${C_NEON}[5]${NC}  CAN-Bus Einrichten         (Netzwerk & Interface)"
        echo "  ${C_NEON}[6]${NC}  MCU Scanner                (Alle CAN/USB Geräte anzeigen)"
        echo ""
        echo "  ${C_RED}[C]${NC}  Clear Workflow State       (Neustart)"
        echo "  [B] Back"
        echo ""
        if ! read -r -p "  >> SELECT: " choice; then return; fi
        case $choice in
            1)
               if [ -f "$MODULES_DIR/hardware/katapult_manager.sh" ]; then
                   source "$MODULES_DIR/hardware/katapult_manager.sh"
                   run_katapult_menu
               else
                   log_error "Katapult module missing."
                   read -r -p "  Press Enter..." || return
               fi
               ;;
            2) run_build_and_flash ;;
            3) run_saved_boards_manager ;;
            4) run_linux_wizard ;;
            5)
               if [ -f "$MODULES_DIR/hardware/can_manager.sh" ]; then
                   source "$MODULES_DIR/hardware/can_manager.sh"
                   if declare -f setup_can_network > /dev/null 2>&1; then
                       setup_can_network
                   elif declare -f run_can_setup > /dev/null 2>&1; then
                       run_can_setup
                   else
                       log_error "CAN Modul geladen, aber keine Setup-Funktion gefunden."
                       read -r -p "  Press Enter..."
                   fi
               else
                   log_error "CAN Manager Modul nicht gefunden."
                   read -r -p "  Press Enter..." || return
               fi
               ;;
            6) run_mcu_scanner ;;
            c|C) clear_workflow_state; log_success "Workflow State gelöscht." ; sleep 1 ;;
            b|B) return ;;
        esac
    done
}

# === SAVED BOARDS MANAGER ===

function run_saved_boards_manager() {
    while true; do
        draw_header "SAVED BOARDS MANAGER"
        
        if [ ! -d "$BOARD_REGISTRY_DIR" ]; then
            mkdir -p "$BOARD_REGISTRY_DIR"
        fi

        local configs=("$BOARD_REGISTRY_DIR"/*.meta)
        if [ ! -e "${configs[0]}" ]; then
            echo "  No saved boards found."
            echo "  Build a new firmware [1] and save it to see it here."
            echo ""
            echo "  [B] Back"
            echo ""
            if ! read -r -p "  >> COMMAND: " ch; then return; fi
            return
        fi

        echo "  Select board to manage:"
        echo ""
        local i=1
        local board_list=()
        for meta in "${configs[@]}"; do
             source "$meta"
             echo "  [$i] $BOARD_NAME (${C_GREY}$ARCH${NC})"
             board_list+=("$meta")
             ((i++))
        done
        
        echo ""
        echo "  [A] Update All Boards"
        echo "  [B] Back"
        echo ""
        
        if ! read -r -p "  >> COMMAND: " ch; then return; fi
        
        if [[ "$ch" =~ ^[0-9]+$ ]] && [ "$ch" -lt "$i" ] && [ "$ch" -ge 1 ]; then
             local selected_meta="${board_list[$((ch-1))]}"
             manage_single_board "$selected_meta"
        elif [[ "$ch" =~ ^[aA]$ ]]; then
             run_mcu_update_all
        elif [[ "$ch" =~ ^[bB]$ ]]; then
             return
        else
             log_error "Invalid selection."
        fi
    done
}

function manage_single_board() {
    local meta="$1"
    # Re-source to be sure
    source "$meta"
    local config_file="$BOARD_REGISTRY_DIR/${BOARD_NAME}.config"

    while true; do
        draw_header "MANAGE: $BOARD_NAME"
        echo "  Arch:       $ARCH"
        echo "  Method:     $FLASH_METHOD"
        echo "  Last Built: $LAST_BUILT"
        echo "  Config:     $config_file"
        echo ""
        echo "  ${C_GREEN}[1]${NC} Build & Flash"
        echo "  ${C_NEON}[2]${NC} Edit Configuration (menuconfig)"
        echo "  ${C_RED}[3]${NC} Delete Board"
        echo ""
        echo "  [B] Back"
        echo ""
        
        if ! read -r -p "  >> COMMAND: " ch; then return; fi
        
        case $ch in
            1) build_and_flash_saved "$meta"; return ;;
            2) edit_saved_config "$meta" ;;
            3) delete_saved_board "$meta"; return ;;
            b|B) return ;;
        esac
    done
}

function build_and_flash_saved() {
    local meta="$1"
    source "$meta"
    local config_file="$BOARD_REGISTRY_DIR/${BOARD_NAME}.config"
    
    draw_header "BUILDING: $BOARD_NAME"
    
    if [ ! -f "$config_file" ]; then
        log_error "Config file missing!"
        read -r -p "  Press Enter..." || return
        return
    fi
    
    # Restore
    cp "$config_file" "$HOME/klipper/.config"
    cd "$HOME/klipper" || return
    
    # Confirmation
    echo "  Configuration loaded."
    echo "  Ready to build and flash using method: $FLASH_METHOD"
    echo ""
    if ! read -r -p "  Start Build? [Y/n]: " yn; then return; fi
    if [[ "$yn" =~ ^[nN] ]]; then return; fi
    
    # Build
    log_info "Building..."
    make olddefconfig > /dev/null
    make clean > /dev/null
    
    if make -j$(nproc); then
        log_success "Build complete."
        
        # Update timestamp
        local now
        now=$(date '+%Y-%m-%d %H:%M:%S')
        # Simple sed replacement for timestamp
        if [ "$(uname)" = "Darwin" ]; then
            sed -i '' "s|LAST_BUILT=.*|LAST_BUILT=\"$now\"|" "$meta"
        else
            sed -i "s|LAST_BUILT=.*|LAST_BUILT=\"$now\"|" "$meta"
        fi
    else
        log_error "Build failed."
        read -r -p "  Press Enter..." || return
        return
    fi
    
    # Flash
    case $FLASH_METHOD in
        can) flash_via_can ;;
        manual)
            echo "  Manual Flash required."
            echo "  Firmware is in $HOME/klipper/out/"
            read -r -p "  Press Enter..." || return
            ;;
        usb|*)
            if [ -f "out/klipper.uf2" ]; then flash_rp2040
            elif [ -f "out/klipper.bin" ]; then flash_bin_artifact
            elif [ -f "out/klipper.elf.hex" ]; then flash_avr_artifact
            fi
            ;;
    esac
    
    read -r -p "  Press Enter to return..." || return
}

function edit_saved_config() {
    local meta="$1"
    source "$meta"
    local config_file="$BOARD_REGISTRY_DIR/${BOARD_NAME}.config"
    
    cp "$config_file" "$HOME/klipper/.config"
    cd "$HOME/klipper" || return
    
    draw_header "EDIT CONFIG: $BOARD_NAME"
    echo "  Opening menuconfig..."
    sleep 1
    
    if make menuconfig; then
        # Save back
        cp .config "$config_file"
        log_success "Configuration updated and saved."
    else
        log_warn "Cancelled. Changes discarded."
    fi
    read -r -p "  Press Enter..." || return
}

function delete_saved_board() {
    local meta="$1"
    source "$meta"
    local config_file="$BOARD_REGISTRY_DIR/${BOARD_NAME}.config"
    
    echo ""
    echo -e "  ${C_RED}WARNING: This will delete '$BOARD_NAME' permanently.${NC}"
    if ! read -r -p "  Are you sure? [y/N]: " yn; then return; fi
    
    if [[ "$yn" =~ ^[yY] ]]; then
        rm "$meta" "$config_file" 2>/dev/null
        log_success "Board deleted."
        sleep 1
    fi
}

function run_build_and_flash() {
    draw_header "BUILD & FLASH KLIPPER FIRMWARE"

    # ╔══════════════════════════════════════════════════════════════╗
    # ║  PHASE 1: VORBEREITUNG                                      ║
    # ╚══════════════════════════════════════════════════════════════╝
    echo ""
    echo "  ${C_NEON}━━━ PHASE 1/3: VORBEREITUNG ━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    if [ ! -d "$HOME/klipper" ]; then
        log_error "Klipper ist nicht installiert!"
        echo "  Zuerst Quick Start [1] ausführen."
        echo ""
        read -r -p "  Press Enter..." || return
        return
    fi

    # B2B Standard: Klipper MUSS gestoppt werden
    log_info "Pre-Flight Check..."
    if systemctl is-active --quiet klipper 2>/dev/null; then
        log_warn "Klipper läuft. Muss gestoppt werden vor dem Flash."
        read -r -p "  Klipper jetzt stoppen? [Y/n]: " yn
        if [[ ! "$yn" =~ ^[nN] ]]; then
            sudo systemctl stop klipper
            log_success "Klipper gestoppt."
        else
            log_error "Abbruch: Klipper blockiert die MCU-Verbindung."
            sleep 2
            return
        fi
    else
        log_success "Klipper ist bereits gestoppt."
    fi

    cd ~/klipper || { log_error "Klipper Verzeichnis nicht gefunden"; return 1; }
    log_success "Phase 1 abgeschlossen."

    # ╔══════════════════════════════════════════════════════════════╗
    # ║  PHASE 2: KONFIGURATION & BUILD                             ║
    # ╚══════════════════════════════════════════════════════════════╝
    echo ""
    echo "  ${C_NEON}━━━ PHASE 2/3: KONFIGURATION & BUILD ━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  2a) MCU konfigurieren (menuconfig)"
    echo "      Wähle Architektur, Prozessor, Kommunikation."
    echo ""
    read -r -p "  Enter drücken für menuconfig..."

    if ! make menuconfig; then
        log_error "Menuconfig abgebrochen."
        read -r -p "  Press Enter..."
        return
    fi
    
    # Hardware-Validation
    echo ""
    echo "  2b) Hardware-Verbindung prüfen"
    echo "  ─────────────────────────────────────────"
    echo "  Board jetzt anschließen. Falls DFU nötig: BOOT-Button halten!"
    echo ""
    echo "  ${C_GREEN}[S]${NC} USB-Geräte scannen"
    echo "  ${C_NEON}[Enter]${NC} Überspringen"
    read -r -p "  >> " scan_ch
    if [[ "$scan_ch" =~ ^[sS] ]]; then
        echo ""
        lsusb
        echo ""
        echo "  (Suche nach: DFU Mode, STM32, RP2040, Klipper)"
        read -r -p "  Press Enter..."
    fi

    echo ""
    echo "  2c) Firmware kompilieren"
    echo "  ─────────────────────────────────────────"
    if ! read -r -p "  Kompilierung starten? [Y/n]: " yn; then return; fi
    if [[ "$yn" =~ ^[nN] ]]; then return; fi
    
    log_info "Alte Build-Dateien entfernen..."
    make clean > /dev/null
    
    log_info "Kompiliere (make -j$(nproc))..."
    if make -j$(nproc); then
        log_success "Firmware kompiliert!"
        save_workflow_state "KLIPPER_BUILT" "klipper" "Firmware kompiliert, bereit zum Flashen"
    else
        log_error "Build fehlgeschlagen."
        read -r -p "  Press Enter..." || return
        return
    fi

    log_success "Phase 2 abgeschlossen."

    # ╔══════════════════════════════════════════════════════════════╗
    # ║  PHASE 3: FINALISIERUNG & DEPLOYMENT                       ║
    # ╚══════════════════════════════════════════════════════════════╝
    echo ""
    echo "  ${C_NEON}━━━ PHASE 3/3: FINALISIERUNG & FLASH ━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # 3a) Config speichern
    echo "  3a) Board-Konfiguration speichern"
    echo "  ─────────────────────────────────────────"
    read -r -p "  Config für spätere Updates speichern? [y/N]: " save_yn
    if [[ "$save_yn" =~ ^[yY] ]]; then
        save_board_config
    fi

    # 3b) Flash
    echo ""
    echo "  3b) Firmware auf MCU übertragen"
    echo "  ─────────────────────────────────────────"

    # === ARTIFACT-BASED FLASH DETECTION ===
    local flash_status=1
    if [ -f "out/klipper.uf2" ]; then
        flash_rp2040
        flash_status=$?
    elif [ -f "out/klipper.bin" ]; then
        flash_bin_artifact
        flash_status=$?
    elif [ -f "out/klipper.elf.hex" ]; then
        flash_avr_artifact
        flash_status=$?
    else
        log_error "Kein Firmware-Artifact in out/ gefunden"
        echo "  Erwartet: klipper.bin, klipper.uf2, oder klipper.elf.hex"
        ls -la out/ 2>/dev/null
    fi
    
    # 3c) POST-FLASH VERIFICATION — Beweise dass es läuft!
    if [ $flash_status -eq 0 ]; then
        echo ""
        echo "  3c) MCU Verifizierung"
        echo "  ─────────────────────────────────────────"
        log_info "Warte 3 Sekunden bis MCU bootet..."
        sleep 3

        local found_mcu=0

        # --- CAN-Bus Scan ---
        if ip link show can0 &>/dev/null; then
            echo ""
            echo "  ${C_NEON}CAN-Bus Scan (can0):${NC}"
            local can_output
            can_output=$(python3 ~/katapult/scripts/flashtool.py -i can0 -q 2>/dev/null || true)
            if [ -n "$can_output" ]; then
                echo "$can_output" | while IFS= read -r line; do
                    if [[ "$line" == *"UUID:"* ]]; then
                        local uuid
                        uuid=$(echo "$line" | grep -oP 'UUID: \K[0-9a-f]+')
                        local app
                        app=$(echo "$line" | grep -oP 'Application: \K\w+')
                        echo ""
                        echo "  ${C_GREEN}● MCU gefunden!${NC}"
                        echo "  ├─ UUID: ${C_GREEN}${uuid}${NC}"
                        echo "  ├─ App:  ${app}"
                        echo "  └─ Status: ${C_GREEN}ONLINE${NC}"
                        echo ""
                        echo "  ${C_NEON}┌─── FÜR printer.cfg KOPIEREN: ──────────────────┐${NC}"
                        echo "  ${C_NEON}│${NC}                                                ${C_NEON}│${NC}"
                        echo "  ${C_NEON}│${NC}  ${C_GREEN}[mcu]${NC}                                          ${C_NEON}│${NC}"
                        echo "  ${C_NEON}│${NC}  ${C_GREEN}canbus_uuid: ${uuid}${NC}             ${C_NEON}│${NC}"
                        echo "  ${C_NEON}│${NC}                                                ${C_NEON}│${NC}"
                        echo "  ${C_NEON}└────────────────────────────────────────────────┘${NC}"
                        found_mcu=1
                    fi
                done
                # Re-check found_mcu since it was in a subshell
                if echo "$can_output" | grep -q "UUID:"; then
                    found_mcu=1
                fi
            else
                echo "  (Keine CAN-Nodes gefunden)"
            fi
        fi

        # --- USB Serial Scan ---
        echo ""
        echo "  ${C_NEON}USB Serial Scan:${NC}"
        if [ -d /dev/serial/by-id/ ] && [ "$(ls /dev/serial/by-id/ 2>/dev/null)" ]; then
            for serial in /dev/serial/by-id/*; do
                local serial_name
                serial_name=$(basename "$serial")
                echo ""
                echo "  ${C_GREEN}● USB MCU gefunden!${NC}"
                echo "  ├─ Serial: ${C_GREEN}${serial_name}${NC}"
                echo "  ├─ Pfad:   ${serial}"
                echo "  └─ Status: ${C_GREEN}ONLINE${NC}"
                echo ""
                echo "  ${C_NEON}┌─── FÜR printer.cfg KOPIEREN: ──────────────────┐${NC}"
                echo "  ${C_NEON}│${NC}                                                ${C_NEON}│${NC}"
                echo "  ${C_NEON}│${NC}  ${C_GREEN}[mcu]${NC}                                          ${C_NEON}│${NC}"
                echo "  ${C_NEON}│${NC}  ${C_GREEN}serial: ${serial}${NC}"
                echo "  ${C_NEON}│${NC}                                                ${C_NEON}│${NC}"
                echo "  ${C_NEON}└────────────────────────────────────────────────┘${NC}"
                found_mcu=1
            done
        else
            echo "  (Keine USB-Serial Devices gefunden)"
        fi

        # --- Klipper Service wiederherstellen ---
        echo ""
        echo "  3d) Klipper Service starten"
        echo "  ─────────────────────────────────────────"
        sudo systemctl start klipper || log_warn "Klipper Start fehlgeschlagen. Prüfe printer.cfg."
        clear_workflow_state

        if [ $found_mcu -eq 1 ]; then
            echo ""
            echo "  ${C_GREEN}╔═══════════════════════════════════════════════════╗${NC}"
            echo "  ${C_GREEN}║                                                   ║${NC}"
            echo "  ${C_GREEN}║   ✅  WORKFLOW ABGESCHLOSSEN                      ║${NC}"
            echo "  ${C_GREEN}║                                                   ║${NC}"
            echo "  ${C_GREEN}║   Phase 1: Vorbereitung     ✓                     ║${NC}"
            echo "  ${C_GREEN}║   Phase 2: Build            ✓                     ║${NC}"
            echo "  ${C_GREEN}║   Phase 3: Flash & Deploy   ✓                     ║${NC}"
            echo "  ${C_GREEN}║   MCU Verifiziert:          ✓                     ║${NC}"
            echo "  ${C_GREEN}║                                                   ║${NC}"
            echo "  ${C_GREEN}║   >> Kopiere die UUID/Serial oben in deine        ║${NC}"
            echo "  ${C_GREEN}║      printer.cfg und starte Klipper neu.          ║${NC}"
            echo "  ${C_GREEN}║                                                   ║${NC}"
            echo "  ${C_GREEN}╚═══════════════════════════════════════════════════╝${NC}"
        else
            echo ""
            log_warn "MCU noch nicht sichtbar. Das kann normal sein."
            echo "  Prüfe manuell:"
            echo "  - CAN:  ~/katapult/scripts/flashtool.py -i can0 -q"
            echo "  - USB:  ls /dev/serial/by-id/"
            echo "  - BOOT-Jumper entfernt? Reset gedrückt?"
        fi
    fi

    read -r -p "  Press Enter..."
}

# === BOARD REGISTRY (MCU Persistence) ===

BOARD_REGISTRY_DIR="$HOME/printer_data/config/katana_boards"

function save_board_config() {
    mkdir -p "$BOARD_REGISTRY_DIR"
    
    echo ""
    echo "  ${C_NEON}:: SAVE BOARD CONFIGURATION ::${NC}"
    echo "  Give this board a unique name (e.g. 'SHT36_Toolhead', 'U2C_Bridge')"
    read -r -p "  >> Name: " board_name
    
    # Sanitize name (alphanumeric + underscore only)
    board_name=$(echo "$board_name" | tr -cd '[:alnum:]_')
    
    if [ -z "$board_name" ]; then
        log_error "Invalid name. Config NOT saved."
        return
    fi
    
    local config_src="$HOME/klipper/.config"
    local config_dest="$BOARD_REGISTRY_DIR/${board_name}.config"
    local meta_dest="$BOARD_REGISTRY_DIR/${board_name}.meta"
    
    if [ -f "$config_src" ]; then
        cp "$config_src" "$config_dest"
        
        # Create Metadata
        echo "BOARD_NAME=\"$board_name\"" > "$meta_dest"
        echo "LAST_BUILT=\"$(date '+%Y-%m-%d %H:%M:%S')\"" >> "$meta_dest"
        
        # Extract Architecture from .config
        local arch="unknown"
        if grep -q "CONFIG_MACH_STM32=y" "$config_src"; then arch="stm32"; fi
        if grep -q "CONFIG_MACH_RP2040=y" "$config_src"; then arch="rp2040"; fi
        if grep -q "CONFIG_MACH_AVR=y" "$config_src"; then arch="avr"; fi
        if grep -q "CONFIG_MACH_LINUX=y" "$config_src"; then arch="linux"; fi
        echo "ARCH=\"$arch\"" >> "$meta_dest"
        
        echo ""
        echo "  How is this board connected? (for auto-update)"
        echo "  [1] USB (DFU/Serial) - Standard"
        echo "  [2] CAN Bus (Katapult) - Bridge required"
        echo "  [3] SD Card / Manual"
        read -r -p "  >> Method: " f_method
        
        case $f_method in
            2) echo "FLASH_METHOD=\"can\"" >> "$meta_dest" ;;
            3) echo "FLASH_METHOD=\"manual\"" >> "$meta_dest" ;;
            *) echo "FLASH_METHOD=\"usb\"" >> "$meta_dest" ;;
        esac
        
        log_success "Saved: $board_name"
        echo "  Location: $config_dest"
    else
        log_error ".config not found! Build first."
    fi
}


# === LINUX HOST MCU (Fully Automatic) ===

function run_linux_wizard() {
    draw_header "LINUX HOST MCU"

    if [ ! -d "$HOME/klipper" ]; then
        log_error "Klipper is not installed!"
        echo "  You need to install Klipper first via Quick Start [1]."
        echo ""
        read -r -p "  Press Enter..."
        return
    fi

    echo "  This will compile & install Klipper for the Raspberry Pi itself."
    echo "  No configuration needed - fully automatic."
    echo ""
    read -r -p "  Start? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi

    cd ~/klipper || { log_error "Klipper directory not found"; return 1; }

    # Auto-configure for Linux Process
    echo "CONFIG_LOW_LEVEL_OPTIONS=y" > .config
    echo "CONFIG_MACH_LINUX=y" >> .config

    make olddefconfig
    make clean > /dev/null

    log_info "Compiling..."
    if make -j$(nproc); then
        log_success "Build complete!"
    else
        log_error "Build failed."
        read -r -p "  Press Enter..."
        return
    fi

    log_info "Installing..."
    if make flash; then
        log_success "Installed!"

        # Setup systemd service
        if [ ! -f "/etc/systemd/system/klipper-mcu.service" ]; then
            log_info "Registering klipper-mcu service..."
            sudo cp ./scripts/klipper-mcu.service /etc/systemd/system/
            sudo systemctl enable klipper-mcu.service
            sudo systemctl daemon-reload
        fi

        sudo systemctl restart klipper-mcu.service
        log_success "Service klipper-mcu running."
    else
        log_error "Installation failed."
    fi
    read -r -p "  Press Enter..."
}

# === FLASH METHODS (Auto-Selected by Artifact) ===

function flash_rp2040() {
    echo ""
    echo "  ${C_GREEN}Detected: RP2040 (UF2)${NC}"
    echo "  ---------------------------------------------------"
    echo "  1. Hold BOOTSEL button on the board"
    echo "  2. Connect USB (or tap RESET while holding BOOTSEL)"
    echo "  3. A USB drive named 'RPI-RP2' should appear"
    echo ""

    local rp2_mount=""
    for mount_point in /media/*/RPI-RP2 /mnt/RPI-RP2 /media/RPI-RP2; do
        if [ -d "$mount_point" ]; then
            rp2_mount="$mount_point"
            break
        fi
    done

    if [ -n "$rp2_mount" ]; then
        log_success "Found RP2040 at: $rp2_mount"
        read -r -p "  Copy firmware now? [Y/n]: " yn
        if [[ ! "$yn" =~ ^[nN] ]]; then
            cp out/klipper.uf2 "$rp2_mount/" && log_success "Firmware copied! Board will reboot."
        fi
    else
        echo "  ${C_YELLOW}RP2040 not detected as USB drive.${NC}"
        echo "  Put board in BOOTSEL mode and try again,"
        echo "  or manually copy: out/klipper.uf2 → RPI-RP2 drive"
    fi
}

function flash_bin_artifact() {
    echo ""
    echo "  ${C_GREEN}Detected: .bin firmware${NC}"
    echo "  ---------------------------------------------------"
    echo ""

    # === USB DEVICE SCAN ===
    echo "  Scanning USB devices..."
    echo ""

    local dfu_found=0
    local serial_device=""
    local usb_devices=""

    # Check lsusb for STM32 DFU mode (0483:df11)
    if command -v lsusb &> /dev/null; then
        usb_devices=$(lsusb 2>/dev/null)

        if echo "$usb_devices" | grep -qi "0483:df11"; then
            dfu_found=1
            echo -e "  ${C_GREEN}●${NC} STM32 DFU Device detected (0483:df11)"
        fi

        # Check for Katapult/CanBoot bootloader (1d50:6177)
        if echo "$usb_devices" | grep -qi "1d50:6177"; then
            echo -e "  ${C_GREEN}●${NC} Katapult (CanBoot) bootloader detected (1d50:6177)"
        fi

        # Check for Klipper USB device (1d50:614e)
        if echo "$usb_devices" | grep -qi "1d50:614e"; then
            echo -e "  ${C_YELLOW}●${NC} Klipper USB device detected (already running firmware)"
        fi
    fi

    # Also check dfu-util for more detail
    if [ $dfu_found -eq 0 ] && command -v dfu-util &> /dev/null; then
        if dfu-util -l 2>/dev/null | grep -q "Found DFU"; then
            dfu_found=1
            echo -e "  ${C_GREEN}●${NC} DFU device detected via dfu-util"
        fi
    fi

    # Find serial devices (common MCU paths)
    for dev in /dev/serial/by-id/*; do
        if [ -e "$dev" ]; then
            serial_device="$dev"
            echo -e "  ${C_GREEN}●${NC} USB Serial: $(basename $dev)"
        fi
    done

    if [ $dfu_found -eq 0 ] && [ -z "$serial_device" ]; then
        echo -e "  ${C_YELLOW}○${NC} No MCU devices detected via USB"
    fi

    echo ""
    echo "  ---------------------------------------------------"

    # === FLASH METHOD SELECTION ===
    if [ $dfu_found -eq 1 ]; then
        echo -e "  ${C_GREEN}Recommended: DFU flash (device in bootloader mode)${NC}"
        echo ""
        echo "  [1] Flash via DFU (USB)          ${C_GREEN}← recommended${NC}"
        echo "  [2] SD Card (manual copy)"
        echo "  [3] CAN Bus (Katapult)"
        echo "  [S] Skip"
    elif [ -n "$serial_device" ]; then
        echo -e "  ${C_GREEN}Recommended: USB Serial flash${NC}"
        echo ""
        echo "  [1] Flash via USB Serial         ${C_GREEN}← recommended${NC}"
        echo "  [2] SD Card (manual copy)"
        echo "  [3] CAN Bus (Katapult)"
        echo "  [S] Skip"
    else
        echo "  No device auto-detected. Options:"
        echo ""
        echo "  [1] Flash via make flash (USB)"
        echo "  [2] SD Card (manual copy)"
        echo "  [3] CAN Bus (Katapult)"
        echo "  [S] Skip"
        echo ""
        echo "  ${C_YELLOW}TIP: Set boot jumper, connect USB, then try [1]${NC}"
    fi

    echo ""
    read -r -p "  >> METHOD: " method

    case $method in
        1)
            if [ $dfu_found -eq 1 ]; then
                log_info "Flashing via DFU..."
                local flash_output
                flash_output=$(make flash FLASH_DEVICE=0483:df11 2>&1)
                local flash_exit=$?
                echo "$flash_output"
                
                if echo "$flash_output" | grep -q "File downloaded successfully"; then
                    echo ""
                    log_success "Firmware flashed successfully!"
                    echo "  (dfu-util detach warnings are normal and can be ignored)"
                    echo ""
                    echo "  ${C_NEON}Next steps:${NC}"
                    echo "  1. Remove BOOT jumper"
                    echo "  2. Press RESET button (or power cycle)"
                    echo "  3. Board will boot with new firmware"
                elif [ $flash_exit -ne 0 ]; then
                    log_error "Flash failed. Check USB connection."
                else
                    log_success "Flash complete!"
                fi
            elif [ -n "$serial_device" ]; then
                log_info "Flashing via USB Serial: $serial_device"
                if make flash FLASH_DEVICE="$serial_device"; then
                    log_success "Flash complete!"
                else
                    log_error "Flash failed."
                fi
            else
                log_info "Flashing..."
                echo "  Ensure device is in bootloader/DFU mode!"
                read -r -p "  Press Enter when ready..."
                make flash
            fi
            ;;
        2)
            echo ""
            echo "  SD CARD INSTRUCTIONS:"
            echo "  1. Firmware is at: ~/klipper/out/klipper.bin"
            echo "  2. Rename to 'firmware.bin' (check your board docs)"
            echo "  3. Copy to FAT32 formatted SD card"
            echo "  4. Insert into board, power cycle"
            echo ""
            echo "  ${C_YELLOW}[!] Some boards need a unique filename each flash.${NC}"
            echo ""
            echo "  Quick download via SCP:"
            echo "  scp $(whoami)@$(hostname -I | awk '{print $1}'):~/klipper/out/klipper.bin ."
            ;;
        3) flash_via_can ;;
        [sS]) return ;;
    esac
}

function flash_avr_artifact() {
    echo ""
    echo "  ${C_GREEN}Detected: AVR (hex)${NC}"
    echo "  ---------------------------------------------------"
    echo "  Ensure board is connected via USB."
    read -r -p "  Press Enter to flash..."
    make flash
}

function flash_via_can() {
    echo ""
    log_info "CAN Bus Flashing (Katapult)"
    echo "  ---------------------------------------------------"

    if command -v candump &> /dev/null && ip link show can0 &> /dev/null; then
        echo "  CAN0 interface found."
    else
        log_warn "CAN interface not detected. Ensure can0 is configured."
    fi

    read -r -p "  Enter UUID to flash: " uuid
    if [ -z "$uuid" ]; then
        log_error "No UUID provided."
        return
    fi

    if [ -f "$HOME/katapult/scripts/flashtool.py" ]; then
        python3 "$HOME/katapult/scripts/flashtool.py" -u "$uuid"
    elif [ -f "$HOME/klipper/lib/canboot/flash_can.py" ]; then
        python3 "$HOME/klipper/lib/canboot/flash_can.py" -u "$uuid"
    else
        log_error "Could not find flash tool. Install Katapult first."
    fi
}
