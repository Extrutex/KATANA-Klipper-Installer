#!/bin/bash
# ==============================================================================
# KATANA SYSTEM HARDENING
# ==============================================================================

function run_hardening_wizard() {
    while true; do
        draw_header "SYSTEM HARDENING"
        
        echo "  [1] Full Hardening (UFW + Log2Ram + SSH)"
        echo "  [2] UFW Firewall Only"
        echo "  [3] SSH Hardening Only"
        echo "  [4] Log2Ram (SD Card Protection)"
        echo "  [5] View Current Security Status"
        echo "  [6] Port Management (Open/Close Ports)"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> " ch
        
        case $ch in
            1) full_hardening ;;
            2) install_ufw_firewall ;;
            3) ssh_hardening ;;
            4) install_log2ram ;;
            5) show_security_status ;;
            6) port_management ;;
            b|B) return ;;
        esac
    done
}

function full_hardening() {
    draw_header "FULL SYSTEM HARDENING"
    echo "  This will enable:"
    echo "  - UFW Firewall (SSH/HTTP/API allowed)"
    echo "  - SSH Hardening (Key auth only, disable root)"
    echo "  - Log2Ram (Protect SD card)"
    echo ""
    read -p "  Continue? [y/N] " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    
    install_ufw_firewall
    ssh_hardening
    install_log2ram
    
    draw_success "Full hardening complete!"
    read -p "  Press Enter..."
}

function install_ufw_firewall() {
    log_info "Configuring UFW Firewall..."
    
    # Check if ufw is installed
    if ! command -v ufw &> /dev/null; then
        if sudo -n true 2>/dev/null; then
            sudo apt-get update
            sudo apt-get install -y ufw
        else
            echo "  [!] Sudo required to install UFW."
            sudo apt-get update
            sudo apt-get install -y ufw
        fi
    fi
    
    # Reset to defaults
    sudo ufw --force reset
    
    # Policies
    sudo ufw default deny incoming
    sudo u
    
    # Allow rules forfw default allow outgoing Klipper stack
    sudo ufw allow ssh/tcp
    sudo ufw allow 22/tcp
    sudo ufw allow http/tcp
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 7125/tcp   # Moonraker
    sudo ufw allow 8080/tcp   # Crowsnest
    sudo ufw allow 8081/tcp   # Crowsnest
    sudo ufw allow 5000/tcp   # OctoPrint
    
    # Enable
    echo "y" | sudo ufw enable
    
    # Show status
    sudo ufw status numbered
    
    log_success "UFW Firewall active."
}

function ssh_hardening() {
    draw_header "SSH HARDENING"
    echo "  This will:"
    echo "  - Disable root login"
    echo "  - Disable password authentication"
    echo "  - Enable key-based authentication only"
    echo "  - Change SSH port to 2222 (optional)"
    echo ""
    echo "  WARNING: Make sure you have SSH keys set up!"
    echo ""
    read -p "  Continue? [y/N] " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    
    # Backup original sshd_config
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Create hardened config
    log_info "Applying SSH hardening..."
    
    # Check if we should change port
    read -p "  Change SSH port to 2222? [y/N] " port_yn
    local ssh_port="22"
    if [[ "$port_yn" =~ ^[yY] ]]; then
        ssh_port="2222"
        sudo ufw allow $ssh_port/tcp
    fi
    
    # Generate hardened config
    sudo tee /etc/ssh/sshd_config > /dev/null <<EOF
# KATANA SSH Hardened Configuration
# Backup at: /etc/ssh/sshd_config.backup

Port $ssh_port
Protocol 2

# Disable root login
PermitRootLogin no

# Disable password auth (keys only)
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no

# Key-based auth only
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# Disable unused auth methods
KerberosAuthentication no
GSSAPIAuthentication no

# Security settings
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no

# Login settings
LoginGraceTime 60
MaxAuthTries 3
MaxSessions 2

# Banner
Banner /etc/ssh/banner

# Client alive settings (detect disconnected clients)
ClientAliveInterval 300
ClientAliveCountMax 2

# Allow specific users (uncomment and add your user)
# AllowUsers pi

Include /etc/ssh/sshd_config.d/*.conf
EOF

    # Create SSH banner
    sudo tee /etc/ssh/banner > /dev/null <<EOF
=====================================
  KATANAOS SECURE SYSTEM
  Unauthorized access prohibited
=====================================
EOF

    # Restart SSH
    log_info "Restarting SSH service..."
    sudo systemctl restart sshd
    
    # Update UFW if port changed
    if [ "$ssh_port" != "22" ]; then
        sudo ufw delete allow 22/tcp
    fi
    
    log_success "SSH hardened!"
    echo "  New SSH port: $ssh_port"
    echo "  Use: ssh -p $ssh_port user@host"
    read -p "  Press Enter..."
}

function install_log2ram() {
    log_info "Checking Log2Ram..."
    
    if dpkg -s log2ram >/dev/null 2>&1; then
        log_success "Log2Ram is already installed."
        read -p "  Press Enter..."
        return
    fi
    
    log_info "Installing Log2Ram..."
    
    # Add repository
    echo "deb [signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian/ bookworm main" | sudo tee /etc/apt/sources.list.d/azlux.list
    
    # Add key
    sudo wget -O /usr/share/keyrings/azlux-archive-keyring.gpg https://azlux.fr/repo.gpg 2>/dev/null || \
    sudo curl -sSL https://azlux.fr/repo.gpg | sudo gpg --dearmor -o /usr/share/keyrings/azlux-archive-keyring.gpg
    
    # Install
    sudo apt update
    sudo apt install -y log2ram
    
    log_success "Log2Ram installed!"
    echo "  This will protect your SD card from log writes."
    echo "  Logs are now stored in RAM and synced periodically."
    read -p "  Press Enter..."
}

function show_security_status() {
    draw_header "SECURITY STATUS"
    
    # UFW Status
    echo "  ${C_WHITE}UFW Firewall:${NC}"
    if command -v ufw &> /dev/null; then
        local ufw_status=$(sudo ufw status | head -1)
        echo "    $ufw_status"
    else
        echo "    ${C_YELLOW}Not installed${NC}"
    fi
    echo ""
    
    # SSH Status
    echo "  ${C_WHITE}SSH Hardening:${NC}"
    if [ -f /etc/ssh/sshd_config.backup ]; then
        echo "    ${C_GREEN}✓ Hardened${NC}"
    else
        echo "    ${C_GREY}○ Not hardened${NC}"
    fi
    echo ""
    
    # Log2Ram
    echo "  ${C_WHITE}Log2Ram:${NC}"
    if dpkg -s log2ram >/dev/null 2>&1; then
        echo "    ${C_GREEN}✓ Installed${NC}"
    else
        echo "    ${C_GREY}○ Not installed${NC}"
    fi
    echo ""
    
    read -p "  Press Enter..."
}

function port_management() {
    while true; do
        draw_header "PORT MANAGEMENT"
        
        echo "  Current open ports:"
        echo ""
        sudo ufw status numbered | grep -E "^\[" | sed 's/^/  /'
        echo ""
        echo "  ${C_NEON}[1]${NC}  Open Port (e.g., 8080, 9000)"
        echo "  ${C_RED}[2]${NC}  Close Port"
        echo "  ${C_YELLOW}[3]${NC}  Common Ports Quick Add"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> " ch
        
        case $ch in
            1) open_port ;;
            2) close_port ;;
            3) quick_ports ;;
            b|B) return ;;
        esac
    done
}

function open_port() {
    echo ""
    read -p "  Enter port number: " port
    read -p "  Enter service name (optional, e.g., Spoolman): " service
    
    if [ -z "$port" ]; then
        log_error "No port specified."
        return
    fi
    
    sudo ufw allow $port/tcp
    log_success "Port $port opened!"
    echo ""
    read -p "  Press Enter..."
}

function close_port() {
    echo ""
    sudo ufw status numbered | grep -E "^\["
    echo ""
    read -p "  Enter rule number to delete: " rule_num
    
    if [ -z "$rule_num" ]; then
        log_error "No rule specified."
        return
    fi
    
    sudo ufw delete $rule_num
    log_success "Rule deleted!"
    echo ""
    read -p "  Press Enter..."
}

function quick_ports() {
    draw_header "QUICK PORT ADD"
    
    echo "  Common ports for 3D printing:"
    echo ""
    echo "  [1]  8080  - Crowsnest/Webcam"
    echo "  [2]  8081  - Second Camera"
    echo "  [3]  8888  - OctoPrint"
    echo "  [4]  9000  - Spoolman"
    echo "  [5]  3000  - Custom Web UI"
    echo "  [6]  5432  - PostgreSQL"
    echo "  [7]  3306  - MySQL/MariaDB"
    echo ""
    echo "  [A]  Add all common ports"
    echo "  [B]  Back"
    echo ""
    read -p "  >> " ch
    
    case $ch in
        1) sudo ufw allow 8080/tcp ;;
        2) sudo ufw allow 8081/tcp ;;
        3) sudo ufw allow 8888/tcp ;;
        4) sudo ufw allow 9000/tcp ;;
        5) sudo ufw allow 3000/tcp ;;
        6) sudo ufw allow 5432/tcp ;;
        7) sudo ufw allow 3306/tcp ;;
        a|A) 
            sudo ufw allow 8080/tcp
            sudo ufw allow 8081/tcp
            sudo ufw allow 8888/tcp
            sudo ufw allow 9000/tcp
            sudo ufw allow 3000/tcp
            ;;
        *) return ;;
    esac
    
    log_success "Ports added!"
    echo ""
    read -p "  Press Enter..."
}
