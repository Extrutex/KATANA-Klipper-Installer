#!/bin/bash
# core/config_loader.sh
# KATANA Core Module: Configuration Loader
# Loads defaults from configs/katana.conf.defaults, then overrides
# from ~/.katana.conf if it exists.

_katana_load_config() {
    local defaults_file="$KATANA_ROOT/configs/katana.conf.defaults"
    local user_config="$HOME/.katana.conf"

    # Load defaults
    if [ -f "$defaults_file" ]; then
        # Source only lines that look like KEY=VALUE (skip comments/blanks)
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            # Trim whitespace
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs | sed 's/^"//;s/"$//')
            # Only set if not already defined (allows env overrides)
            if [ -z "${!key}" ]; then
                export "$key=$value"
            fi
        done < "$defaults_file"
    fi

    # User overrides (if file exists)
    if [ -f "$user_config" ]; then
        while IFS='=' read -r key value; do
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs | sed 's/^"//;s/"$//')
            export "$key=$value"
        done < "$user_config"
    fi
}

_katana_load_config
