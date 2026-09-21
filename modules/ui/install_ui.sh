#!/bin/bash
# modules/ui/install_ui.sh


function install_ui_stack() {
    while true; do
        draw_header "🌐 WEB INTERFACE MANAGER"
        echo ""
        echo "  [1] Install Mainsail"
        echo "  [2] Install Fluidd"
        echo ""
        echo "  --- Uninstall / Reinstall ---"
        echo "  [3] Uninstall Mainsail"
        echo "  [4] Uninstall Fluidd"
        echo "  [5] Uninstall ALL UIs"
        echo ""
        echo "  [B] Back"
        echo ""
        read -r -p "  >> COMMAND: " ch
        
        case $ch in
            1) do_install_mainsail ;;
            2) do_install_fluidd ;;
            3) uninstall_mainsail ;;
            4) uninstall_fluidd ;;
            5) uninstall_all_ui ;;
            [bB]) return ;;
            *) log_error "Invalid Selection" ;;
        esac
    done
}

# ==============================================================================
# WEB UI BUNDLE DEPLOYMENT
# ------------------------------------------------------------------------------
# Mainsail and Fluidd are both shipped as a release ZIP of a static site. The
# previous implementation ("Simplified placeholder logic as real logic was
# lost") checked no exit code at all: wget, unzip and rm could each fail and the
# function still logged success. A 404, a truncated download or a full disk
# produced an empty $HOME/mainsail, a green log line and an nginx vhost serving
# nothing — the failure surfaced days later as a blank browser tab.
# ==============================================================================

# Release URL per UI, overridable via environment.
#
# The override is not a test hook bolted on: a shop that provisions printers
# behind a corporate proxy or on an isolated production line needs to install
# from an internal mirror, and pinning a known-good release is how a fleet stays
# on one version. It also lets the headless test run without network.
function katana_web_ui_url() {
    local ui_type="$1"
    case "$ui_type" in
        mainsail)
            printf '%s\n' "${KATANA_MAINSAIL_URL:-https://github.com/mainsail-crew/mainsail/releases/latest/download/mainsail.zip}"
            ;;
        fluidd)
            printf '%s\n' "${KATANA_FLUIDD_URL:-https://github.com/fluidd-core/fluidd/releases/latest/download/fluidd.zip}"
            ;;
        *)
            return 1
            ;;
    esac
}

# Downloads <url> to <dest>. curl and wget are both accepted because the target
# images differ; a missing downloader is an error, not a silent skip.
function katana_fetch_url() {
    local url="$1" dest="$2"

    if command -v curl >/dev/null 2>&1; then
        # --fail: an HTTP 404 must not be written to disk as a 9-byte "file"
        # and then fail confusingly in unzip. -L follows the release redirect.
        curl -fsSL --retry 2 --connect-timeout 20 -o "$dest" "$url"
        return $?
    fi

    if command -v wget >/dev/null 2>&1; then
        wget -q --tries=3 --timeout=20 -O "$dest" "$url"
        return $?
    fi

    log_error "Neither curl nor wget is available — cannot download $url"
    return 1
}

# Installs a web UI release bundle into $install_dir.
#
# Order of operations, and why:
#   1. stage in a directory NEXT TO the target, not in /tmp — the final step is
#      then a rename on the same filesystem, i.e. atomic. A /tmp staging area
#      turns the last step into a cross-device copy that can fail halfway and
#      leave exactly the broken half-install this function exists to prevent.
#   2. download with a checked exit code
#   3. `unzip -t` before extracting, so a truncated or corrupted archive is
#      named as such instead of producing a partial tree
#   4. extract, then verify index.html actually exists — a ZIP that unpacks
#      cleanly but is not a web bundle is still a failed install
#   5. swap into place, keeping the previous version until the new one is in
#
# The body runs in a subshell so `trap ... EXIT` cleans the staging directory on
# every exit path including failure, without installing an EXIT trap into the
# long-lived interactive shell. The subshell also confines `set -euo pipefail`
# to this block: any unchecked command failure aborts the deployment instead of
# falling through to a success message.
function install_web_ui_bundle() {
    local ui_type="$1"
    local install_dir="$2"
    local url

    if ! url="$(katana_web_ui_url "$ui_type")"; then
        log_error "Unknown web UI '$ui_type'."
        return 1
    fi

    log_info "Deploying $ui_type from $url"

    (
        set -euo pipefail

        parent_dir="$(dirname "$install_dir")"
        mkdir -p "$parent_dir"

        staging="$(mktemp -d "$parent_dir/.katana-${ui_type}.XXXXXX")"
        trap 'rm -rf "$staging"' EXIT

        archive="$staging/bundle.zip"

        if ! katana_fetch_url "$url" "$archive"; then
            log_error "$ui_type: download failed ($url) — check network, proxy or release URL."
            exit 1
        fi

        if [ ! -s "$archive" ]; then
            log_error "$ui_type: downloaded archive is empty ($url)."
            exit 1
        fi

        # Integrity before extraction: unzip -t reads the central directory and
        # CRCs every member, which is what catches a truncated transfer.
        if ! unzip -tqq "$archive" >>"${LOG_FILE:-/dev/null}" 2>&1; then
            log_error "$ui_type: archive is corrupt (failed unzip -t) — download incomplete or not a ZIP."
            exit 1
        fi

        if ! unzip -q "$archive" -d "$staging/payload" >>"${LOG_FILE:-/dev/null}" 2>&1; then
            log_error "$ui_type: extraction failed — check free disk space and permissions on $parent_dir."
            exit 1
        fi

        if [ ! -f "$staging/payload/index.html" ]; then
            log_error "$ui_type: archive contains no index.html — this is not a $ui_type web bundle."
            exit 1
        fi

        # Swap. The previous install is kept aside until the new tree is in
        # place, so a failure here never leaves the host without a UI.
        previous=""
        if [ -e "$install_dir" ]; then
            previous="${install_dir}.replaced.$(date +%s)"
            mv "$install_dir" "$previous"
        fi

        if ! mv "$staging/payload" "$install_dir"; then
            log_error "$ui_type: could not move the new bundle into $install_dir."
            if [ -n "$previous" ]; then
                mv "$previous" "$install_dir"
                log_warn "$ui_type: restored the previous installation."
            fi
            exit 1
        fi

        if [ -n "$previous" ]; then
            rm -rf "$previous"
        fi

        exit 0
    ) || return 1

    log_success "$ui_type bundle deployed to $install_dir"
    return 0
}

function do_install_mainsail() {
    log_info "Installing Mainsail..."

    local install_dir="$HOME/mainsail"
    if [ -d "$install_dir" ] && [ -f "$install_dir/index.html" ]; then
        log_warn "Mainsail already exists at $install_dir — skipping download."
    elif ! install_web_ui_bundle "mainsail" "$install_dir"; then
        log_error "Mainsail installation aborted."
        return 1
    fi

    # Configure Nginx
    if ! setup_nginx "mainsail"; then
        log_error "Mainsail: nginx configuration failed."
        return 1
    fi

    # Add to Moonraker Update Manager. Optional: a missing update manager is a
    # degraded install, not a failed one — the UI itself is already serving.
    if source "$KATANA_ROOT/modules/system/moonraker_update_manager.sh" 2>/dev/null; then
        add_update_manager_entry "Mainsail" "web" "$HOME/mainsail" "" "" "stable" "mainsail-crew/mainsail" \
            || log_warn "Mainsail: could not register with the Moonraker update manager."
    fi

    log_success "Mainsail Installed."
    katana_pause
}

function do_install_fluidd() {
    log_info "Installing Fluidd..."

    local install_dir="$HOME/fluidd"
    if [ -d "$install_dir" ] && [ -f "$install_dir/index.html" ]; then
        log_warn "Fluidd already exists at $install_dir — skipping download."
    elif ! install_web_ui_bundle "fluidd" "$install_dir"; then
        log_error "Fluidd installation aborted."
        return 1
    fi

    # Configure Nginx
    if ! setup_nginx "fluidd"; then
        log_error "Fluidd: nginx configuration failed."
        return 1
    fi

    # Add to Moonraker Update Manager (see do_install_mainsail).
    if source "$KATANA_ROOT/modules/system/moonraker_update_manager.sh" 2>/dev/null; then
        add_update_manager_entry "Fluidd" "web" "$HOME/fluidd" "" "" "stable" "fluidd-core/fluidd" \
            || log_warn "Fluidd: could not register with the Moonraker update manager."
    fi

    log_success "Fluidd Installed."
    katana_pause
}



function uninstall_mainsail() {
    draw_header "UNINSTALL MAINSAIL"
    echo ""
    # Destructive and never implied by --yes: without a human, the answer is no.
    if ! katana_confirm "  Uninstall Mainsail? [y/N]: " no; then return 0; fi
    
    log_info "Removing Mainsail..."
    rm -rf "$HOME/mainsail"
    sudo rm -f /etc/nginx/sites-enabled/mainsail /etc/nginx/sites-available/mainsail
    sudo systemctl restart nginx
    draw_success "Mainsail uninstalled."
    katana_pause
}

function uninstall_fluidd() {
    draw_header "UNINSTALL FLUIDD"
    echo ""
    # Destructive and never implied by --yes: without a human, the answer is no.
    if ! katana_confirm "  Uninstall Fluidd? [y/N]: " no; then return 0; fi
    
    log_info "Removing Fluidd..."
    rm -rf "$HOME/fluidd"
    sudo rm -f /etc/nginx/sites-enabled/fluidd /etc/nginx/sites-available/fluidd
    sudo systemctl restart nginx
    draw_success "Fluidd uninstalled."
    katana_pause
}

function uninstall_all_ui() {
    draw_header "UNINSTALL ALL UIs"
    echo ""
    # Destructive and never implied by --yes: without a human, the answer is no.
    if ! katana_confirm "  Uninstall ALL web interfaces? [y/N]: " no; then return 0; fi
    
    log_info "Removing all UIs..."
    rm -rf "$HOME/mainsail" "$HOME/fluidd" "$HOME/horizon"
    sudo rm -f /etc/nginx/sites-enabled/mainsail /etc/nginx/sites-available/mainsail
    sudo rm -f /etc/nginx/sites-enabled/fluidd /etc/nginx/sites-available/fluidd
    sudo systemctl restart nginx
    draw_success "All UIs uninstalled."
    katana_pause
}

function do_remove_ui() {
    log_info "Removing UI..."
    rm -rf "$HOME/mainsail" "$HOME/fluidd"
    log_success "UI Removed."
    katana_pause
}

function setup_nginx() {
    local ui_type="$1" # mainsail or fluidd
    log_info "Configuring Nginx for $ui_type..."
    
    # Check if nginx is installed
    if ! command -v nginx &> /dev/null; then
        if declare -f wait_for_apt_lock > /dev/null 2>&1; then wait_for_apt_lock; fi
        if sudo -n true 2>/dev/null; then
            sudo apt-get install -y nginx
        else
            echo "  [!] Sudo required to install nginx."
            sudo apt-get install -y nginx
        fi
    fi
    
    # Determine port - first UI gets 80, second gets 81
    local port=80
    local default_flag="default_server"
    
    # Check if another UI is already using port 80
    if [ -f /etc/nginx/sites-available/mainsail ] && [ "$ui_type" != "mainsail" ]; then
        port=81
        default_flag=""
    elif [ -f /etc/nginx/sites-available/fluidd ] && [ "$ui_type" != "fluidd" ]; then
        port=81
        default_flag=""
    fi
    
    # Check nginx ports already configured
    local existing_ports=$(grep -r "listen" /etc/nginx/sites-enabled/ 2>/dev/null | grep -oP '\d+' | sort -u || true)
    while echo "$existing_ports" | grep -q "^${port}$"; do
        port=$((port + 1))
    done
    
    log_info "Using port: $port"
    
    local cfg_file="/etc/nginx/sites-available/$ui_type"
    local root_dir="$HOME/$ui_type"
    
    # Backup existing config if exists
    if [ -f "$cfg_file" ]; then
        sudo cp "$cfg_file" "$cfg_file.bak"
    fi
    
    # Remove old symlink if exists
    sudo rm -f "/etc/nginx/sites-enabled/$ui_type"
    
    # Create nginx config with determined port
    sudo tee "$cfg_file" > /dev/null <<EOF
server {
    listen $port $default_flag;
    listen [::]:$port $default_flag;
    
    server_name _;
    
    access_log /var/log/nginx/${ui_type}_access.log;
    error_log /var/log/nginx/${ui_type}_error.log;

    client_max_body_size 100M;

    location / {
        root $root_dir;
        index index.html index.htm;
        try_files \$uri \$uri/ /index.html;
    }

    location /api {
        proxy_pass http://localhost:7125;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /access {
        proxy_pass http://localhost:7125;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /server {
        proxy_pass http://localhost:7125;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /websocket {
        proxy_pass http://localhost:7125/websocket;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 86400;
    }

    location /printer {
        proxy_pass http://localhost:7125;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /machine {
        proxy_pass http://localhost:7125;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    
    # Fix permissions for Nginx - CRITICAL FOR 403 REDIRECT LOOP
    log_info "Fixing permissions for $root_dir..."
    # 1. Ensure the user home dir is traversing for others (o+x)
    sudo chmod o+x "$HOME"
    
    # 2. Ensure the UI folder is readable/executable for everyone
    # $USER is not exported by every login/cron/systemd context; id -un always is.
    local run_user="${USER:-$(id -un)}"
    sudo chown -R "$run_user":"$run_user" "$root_dir"
    sudo chmod -R 755 "$root_dir"
    
    # Enable site
    sudo ln -sf "$cfg_file" /etc/nginx/sites-enabled/
    
    # Disable default if exists and this is first UI
    if [ "$port" = "80" ] && [ -L /etc/nginx/sites-enabled/default ]; then
        sudo rm -f /etc/nginx/sites-enabled/default
    fi
    
    # Test and restart
    if sudo nginx -t; then
        sudo systemctl enable nginx
        sudo systemctl start nginx
        sudo systemctl reload nginx
        log_success "Nginx configured for $ui_type on port $port"
        return 0
    fi

    # A broken vhost means the UI is not reachable. Reporting that as success
    # was the second half of the same bug as the placeholder installer: the
    # caller's last command was the `head` of the diagnostic output, so
    # setup_nginx returned 0 on a failed config test.
    log_error "Nginx config test failed — $ui_type is NOT being served."
    sudo nginx -t 2>&1 | head -20
    return 1
}
