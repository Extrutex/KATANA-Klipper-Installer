#!/bin/bash
# ==============================================================================
# KATANA MODULE: Flash Registry
# Board profile loader for THE FORGE.
# The actual flash engine is in flash_engine.sh
# ==============================================================================

# This file previously auto-launched FORGE when sourced.
# Now it only defines helper functions for board profiles.

FLASH_PROFILES_DIR="$KATANA_ROOT/modules/hardware/profiles"

function list_saved_boards() {
    if [ -d "$FLASH_PROFILES_DIR" ]; then
        ls "$FLASH_PROFILES_DIR"/*.config 2>/dev/null | while read -r f; do
            basename "$f" .config
        done
    fi
}

function load_board_profile() {
    local board_name="$1"
    local profile="$FLASH_PROFILES_DIR/${board_name}.config"
    if [ -f "$profile" ]; then
        source "$profile"
        return 0
    else
        return 1
    fi
}
