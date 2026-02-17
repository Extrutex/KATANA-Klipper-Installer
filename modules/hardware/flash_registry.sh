#!/bin/bash
# KATANA REDIRECTOR
# This file replaces the old flash_registry.sh to force-load the new engine.

if [ -f "$MODULES_DIR/hardware/flash_engine.sh" ]; then
    source "$MODULES_DIR/hardware/flash_engine.sh"
    run_hal_flasher
else
    echo "CRITICAL ERROR: Flash Engine missing!"
    read -p "Press Enter..."
fi
