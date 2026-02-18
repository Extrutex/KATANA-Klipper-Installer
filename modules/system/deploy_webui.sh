#!/bin/bash
# modules/system/deploy_webui.sh
# KATANA Web UI Deployer (HORIZON)
# Builds React App and deploys it to /opt/katana/webui

function deploy_katana_webui() {
    draw_header "DEPLOY HORIZON UI"
    
    local webui_src="$KATANA_ROOT/webui"
    local webui_dest="/opt/katana/webui"
    
    # 1. Check Node/NPM
    if ! command -v npm &> /dev/null; then
        log_warn "Node.js/npm not found. Installing..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    
    # Check Node.js
    if ! command -v npm &> /dev/null; then
        log_error "Failed to install Node.js. Aborting web ui deployment."
        return 1
    fi
    
    log_info "Node.js Version: $(node -v)"
    log_info "NPM Version: $(npm -v)"
    
    # 2. Build React App
    log_info "Building Web UI assets..."
    
    if [ ! -d "$webui_src" ]; then
        log_error "Web UI source code missing at $webui_src"
        return 1
    fi
    
    cd "$webui_src" || return 1
    
    # Install dependencies
    exec_silent "Installing NPM packages" "npm ci --prefer-offline --no-audit"
    
    # Build
    exec_silent "Building Production Bundle" "npm run build"
    
    if [ ! -d "$webui_src/dist" ]; then
        log_error "Build failed. 'dist' folder not found."
        return 1
    fi
    
    # 3. Deploy
    log_info "Deploying to $webui_dest..."
    
    # Create dest dir with correct perms
    sudo mkdir -p "$webui_dest"
    
    # Backup old version if exists
    if [ -d "$webui_dest/assets" ]; then
         # Quick backup
         sudo tar -czf "$webui_dest/../webui_backup_$(date +%s).tar.gz" -C "$webui_dest" .
    fi
    
    # Copy new files
    sudo cp -r "$webui_src/dist/"* "$webui_dest/"
    sudo chown -R $USER:$USER "$webui_dest"
    sudo chmod -R 755 "$webui_dest"
    
    log_success "Web UI deployed successfully."
    
    # 4. Nginx Integration
    log_info "Configuring Nginx..."

    local nginx_template="$KATANA_ROOT/configs/templates/nginx_katana.conf"
    local nginx_avail="/etc/nginx/sites-available/katana"
    local nginx_enabled="/etc/nginx/sites-enabled/katana"

    if [ ! -f "$nginx_template" ]; then
        log_error "Nginx template not found at $nginx_template"
        log_warn "Manual Nginx setup required."
    else
        # Install Nginx if missing
        if ! command -v nginx &> /dev/null; then
            log_info "Installing Nginx..."
            sudo apt-get update && sudo apt-get install -y nginx
        fi

        # deploy config
        log_info "Deploying Nginx config to $nginx_avail"
        sudo cp "$nginx_template" "$nginx_avail"

        # enable site
        if [ ! -L "$nginx_enabled" ]; then
            log_info "Enabling KATANA site..."
            sudo ln -sf "$nginx_avail" "$nginx_enabled"
        fi

        # disable default if exists
        if [ -L "/etc/nginx/sites-enabled/default" ]; then
            log_info "Disabling default Nginx site..."
            sudo rm "/etc/nginx/sites-enabled/default"
        fi

        # test and restart
        log_info "Testing Nginx configuration..."
        if sudo nginx -t; then
            log_success "Nginx configuration valid."
            exec_silent "Restarting Nginx" "sudo systemctl restart nginx"
        else
            log_error "Nginx configuration invalid! Please check $nginx_avail"
        fi
    fi
    
    echo ""
    log_info "HORIZON Web UI is successfully deployed."
    log_info "Access it at http://$(hostname).local or http://$(hostname -I | cut -d' ' -f1)"
    read -p "  Press Enter..."
}
