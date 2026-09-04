#!/bin/bash
# ==============================================================================
# KATANA MODULE: NEXUS A.Z.M.
# Adaptive Z-Offset & Meshing - industrial first-layer automation
#
# Deploys a single self-contained Klipper macro package:
#   150 C thermal pre-flight -> nozzle scrubbing -> authoritative Z reference
#   -> gantry leveling -> adaptive bed mesh -> computed Z-offset -> adaptive purge
#
# Pure Jinja2/G-Code, no Python extras, no external dependencies.
# ==============================================================================

NEXUS_FILES="nexus_azm.cfg"
NEXUS_CFG_SUBDIR="nexus_azm"
NEXUS_MARKER="# --- NEXUS A.Z.M. ---"

function install_nexus_azm() {
    while true; do
        draw_header "NEXUS A.Z.M. (Adaptive Z-Offset & Meshing)"

        local nexus_status="NOT INSTALLED"
        if [ -d "$HOME/printer_data/config/$NEXUS_CFG_SUBDIR" ]; then
            nexus_status="${C_GREEN}INSTALLED${NC}"
        fi

        echo ""
        echo "  Status: [$nexus_status]"
        echo ""
        echo "  ${C_NEON}[1]${NC}  Install NEXUS A.Z.M."
        echo "  ${C_NEON}[2]${NC}  Show prerequisites"
        echo "  ${C_RED}[3]${NC}  Remove NEXUS A.Z.M."
        echo ""
        echo "  [B] Back"
        echo ""
        read -r -p "  >> COMMAND: " ch

        case $ch in
            1) do_install_nexus ;;
            2) do_show_nexus_requirements ;;
            3) do_remove_nexus ;;
            [bB]) return ;;
            *) log_error "Invalid Selection" ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# Prerequisite report
#
# NEXUS derives every adaptive decision from machine state. Missing prerequisites
# do not crash a print - they silently degrade it to a full-bed mesh and a corner
# purge. Making that visible before installation is cheaper than debugging it
# after the first job.
# ------------------------------------------------------------------------------
function do_show_nexus_requirements() {
    draw_header "NEXUS A.Z.M. - PREREQUISITES"

    local pcfg="$HOME/printer_data/config/printer.cfg"

    echo ""
    echo "  Mandatory in printer.cfg:"
    echo ""
    _nexus_check_section "$pcfg" "exclude_object" "object geometry for adaptive mesh and purge"
    _nexus_check_section "$pcfg" "bed_mesh"       "mesh_min / mesh_max define the probing envelope"
    echo ""
    echo "  Z probe (at least one required):"
    echo ""
    local probe_found=0
    local sect
    for sect in probe bltouch smart_effector scanner probe_eddy_current load_cell_probe; do
        if _nexus_has_section "$pcfg" "$sect"; then
            echo -e "    ${C_GREEN}[ OK ]${NC} [$sect]"
            probe_found=1
        fi
    done
    if [ "$probe_found" -eq 0 ]; then
        echo -e "    ${C_RED}[FAIL]${NC} no Z probe section found"
    fi
    echo ""
    echo "  Recommended:"
    echo ""
    _nexus_check_section "$pcfg" "quad_gantry_level" "auto-detected, skipped if absent" "optional"
    _nexus_check_section "$pcfg" "z_tilt"            "auto-detected, skipped if absent" "optional"
    echo ""
    echo "  Slicer: object labelling MUST be enabled"
    echo "    OrcaSlicer / Bambu Studio : Others -> Label objects"
    echo "    PrusaSlicer / SuperSlicer : Output options -> Label objects"
    echo ""
    read -r -p "  Press Enter..."
}

function _nexus_has_section() {
    local pcfg="$1"
    local section="$2"
    [ -f "$pcfg" ] || return 1
    # Matches "[section]" and "[section name]" at the start of a line.
    grep -qE "^\[[[:space:]]*${section}([[:space:]]+[^]]*)?\]" "$pcfg"
}

function _nexus_check_section() {
    local pcfg="$1"
    local section="$2"
    local hint="$3"
    local level="${4:-required}"

    if _nexus_has_section "$pcfg" "$section"; then
        echo -e "    ${C_GREEN}[ OK ]${NC} [$section] - $hint"
    elif [ "$level" = "optional" ]; then
        echo -e "    ${C_YELLOW}[ -- ]${NC} [$section] - $hint"
    else
        echo -e "    ${C_RED}[FAIL]${NC} [$section] MISSING - $hint"
    fi
}

# ------------------------------------------------------------------------------
# Install
# ------------------------------------------------------------------------------
function do_install_nexus() {
    draw_header "INSTALL NEXUS A.Z.M."
    echo ""
    echo "  NEXUS A.Z.M. replaces the manual first-layer routine:"
    echo ""
    echo "    Thermal pre-flight  - probing at a fixed 150 C setpoint"
    echo "    Nozzle scrubbing    - before the authoritative Z reference"
    echo "    Dynamic Z-offset    - computed from nozzle, layer, material, temp"
    echo "    Adaptive mesh       - probes the object area, not the whole bed"
    echo "    Adaptive purge      - volumetric line next to the bounding box"
    echo ""

    local cfg_dir="$HOME/printer_data/config"
    local nexus_dir="$cfg_dir/$NEXUS_CFG_SUBDIR"
    local pcfg="$cfg_dir/printer.cfg"
    local src_dir="$CONFIGS_DIR/$NEXUS_CFG_SUBDIR"

    if [ ! -d "$cfg_dir" ]; then
        log_error "Config directory not found at $cfg_dir"
        read -r -p "  Press Enter..."
        return
    fi

    # --- Lifecycle conflict -------------------------------------------------
    # KATANA-FLOW and NEXUS both own the print lifecycle. Running both is not
    # a crash, but the slicer must call exactly one entry point - otherwise the
    # machine homes, heats and purges twice per job.
    if [ -d "$cfg_dir/katana_flow" ]; then
        log_warn "KATANA-FLOW is installed and also owns the print lifecycle."
        echo ""
        echo "  Both can coexist in printer.cfg, but the slicer start G-code"
        echo "  must call exactly ONE of them:"
        echo ""
        echo "    FLOW_START ...        (KATANA-FLOW)"
        echo "    NEXUS_START_PRINT ... (NEXUS A.Z.M.)"
        echo ""
    fi

    # --- Prerequisites ------------------------------------------------------
    local missing=""
    _nexus_has_section "$pcfg" "exclude_object" || missing="$missing [exclude_object]"
    _nexus_has_section "$pcfg" "bed_mesh"       || missing="$missing [bed_mesh]"
    if [ -n "$missing" ]; then
        log_warn "Missing in printer.cfg:$missing"
        echo ""
        echo "  NEXUS installs anyway and falls back to a full-bed mesh and a"
        echo "  corner purge, but the adaptive modules stay inactive until the"
        echo "  sections above exist."
        echo ""
    fi

    read -r -p "  Install? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi

    mkdir -p "$nexus_dir"

    log_info "Deploying NEXUS A.Z.M. macros..."
    local failed=0
    local f
    for f in $NEXUS_FILES; do
        if [ -f "$src_dir/$f" ]; then
            cp "$src_dir/$f" "$nexus_dir/$f"
        else
            log_error "Missing: $src_dir/$f"
            failed=1
        fi
    done

    if [ "$failed" -eq 1 ]; then
        log_error "Some files missing. Check your KATANA installation."
        read -r -p "  Press Enter..."
        return
    fi

    if [ -f "$pcfg" ]; then
        if grep -q "$NEXUS_CFG_SUBDIR" "$pcfg"; then
            log_warn "NEXUS A.Z.M. already included in printer.cfg"
        else
            cp "$pcfg" "$pcfg.bak.nexusazm"
            {
                echo ""
                echo "$NEXUS_MARKER"
                echo "[include $NEXUS_CFG_SUBDIR/*.cfg]"
            } >> "$pcfg"
            log_info "Added include to printer.cfg (backup: printer.cfg.bak.nexusazm)"
        fi
    fi

    log_success "NEXUS A.Z.M. installed!"
    echo ""
    echo "  1) RESTART Klipper"
    echo "  2) Validate the installation:    NEXUS_AZM_SELFTEST"
    echo "  3) Adjust [gcode_macro _NEXUS_AZM_CONF] to the machine"
    echo "     (brush position, mesh spacing, offset model coefficients)"
    echo "  4) Arm the commissioning dry run: NEXUS_AZM_DRYRUN ENABLE=1"
    echo "     Start a real sliced job - NEXUS reports the complete plan"
    echo "     (mesh window, offset terms, purge placement) and aborts"
    echo "     without any motion or heating. Disable with ENABLE=0."
    echo ""
    echo "  Slicer Start G-Code:"
    echo "    NEXUS_START_PRINT BED=[first_layer_bed_temperature] \\"
    echo "      EXTRUDER=[first_layer_temperature] NOZZLE=[nozzle_diameter] \\"
    echo "      LAYER=[first_layer_height] MATERIAL=[filament_type]"
    echo ""
    echo "  Slicer End G-Code:"
    echo "    NEXUS_END_PRINT"
    echo ""
    read -r -p "  Press Enter..."
}

# ------------------------------------------------------------------------------
# Remove
# ------------------------------------------------------------------------------
function do_remove_nexus() {
    draw_header "REMOVE NEXUS A.Z.M."
    echo ""
    log_warn "The slicer start G-code must be switched back before the next job."
    echo ""
    read -r -p "  Remove NEXUS A.Z.M. completely? [y/N]: " yn

    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi

    local cfg_dir="$HOME/printer_data/config"
    local nexus_dir="$cfg_dir/$NEXUS_CFG_SUBDIR"
    local pcfg="$cfg_dir/printer.cfg"

    log_info "Removing config files..."
    rm -rf "$nexus_dir"

    if [ -f "$pcfg" ]; then
        log_info "Cleaning printer.cfg..."
        cp "$pcfg" "$pcfg.bak.nexusazm.remove"
        local tmpfile
        tmpfile=$(mktemp)
        # Only the marker and the include line NEXUS wrote are removed. A blanket
        # filter on the module name would also delete user comments mentioning it.
        grep -vF "$NEXUS_MARKER" "$pcfg" \
            | grep -vE "^\[include[[:space:]]+${NEXUS_CFG_SUBDIR}/\*\.cfg\]" > "$tmpfile"
        mv "$tmpfile" "$pcfg"
        log_success "printer.cfg cleaned (backup: printer.cfg.bak.nexusazm.remove)"
    fi

    log_success "NEXUS A.Z.M. removed!"
    read -r -p "  Press Enter..."
}
