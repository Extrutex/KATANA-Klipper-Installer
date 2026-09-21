#!/bin/bash

# Wait for any running apt/dpkg process to finish before we use apt
function wait_for_apt_lock() {
    local max_wait=60
    local waited=0
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
        if [ $waited -eq 0 ]; then
            log_info "Waiting for other apt process to finish..."
        fi
        sleep 2
        waited=$((waited + 2))
        if [ $waited -ge $max_wait ]; then
            log_warn "apt lock still held after ${max_wait}s. Proceeding anyway."
            break
        fi
    done
}

function install_core_stack() {
    while true; do
        draw_header "CORE ENGINE INSTALLER"
        echo "  [1] Install Klipper (Standard)"
        echo "  [2] Install Moonraker"
        echo "  [3] Install Kalico (High-Performance)"
        echo "  [4] Install RatOS (Klipper Fork)"
        echo "  [5] Build Firmware    (MCU Builder)"
        echo ""
        echo "  [B] Back"
        read -r -p "  >> " ch

        case $ch in
            1) do_install_klipper "Standard" ;;
            2) do_install_moonraker ;;
            3) do_install_kalico ;;
            4) do_install_ratos ;;
            5) run_quick_build_menu ;;
            [bB]) return ;;
        esac
    done
}

function do_install_ratos() {
    log_info "Installing RatOS (Klipper Fork)..."
    
    # 1. Clone
    local repo_dir="$HOME/ratos_repo"
    if [ -d "$repo_dir" ]; then
        log_info "RatOS repo already exists. Pulling..."
        cd "$repo_dir" && git pull
    else
        exec_silent "Cloning RatOS" "git clone https://github.com/Rat-OS/klipper.git $repo_dir"
    fi

    # 2. VirtualEnv
    local env_dir="$HOME/ratos_env"
    if [ ! -d "$env_dir" ]; then
        exec_silent "Creating VirtualEnv" "virtualenv -p python3 $env_dir"
        exec_silent "Installing Dependencies" "$env_dir/bin/pip install -r $repo_dir/scripts/klippy-requirements.txt"
    fi
    
    log_success "RatOS installed. Use 'Engine Manager' to switch to it."
    katana_pause
}

function do_install_kalico() {
    log_info "Installing Kalico (High-Performance Klipper fork)..."

    # 1. Clone
    local repo_dir="$HOME/kalico"
    if [ -d "$repo_dir" ]; then
        log_info "Kalico repo already exists. Pulling..."
        cd "$repo_dir" && git pull
    else
        exec_silent "Cloning Kalico" "git clone https://github.com/KalicoCrew/kalico.git $repo_dir"
    fi

    # 2. VirtualEnv (shared klippy-env; Kalico is Klipper-compatible)
    local env_dir="$HOME/klippy-env"
    if [ ! -d "$env_dir" ]; then
        exec_silent "Creating VirtualEnv" "virtualenv -p python3 $env_dir"
    fi
    exec_silent "Installing Dependencies" "$env_dir/bin/pip install -r $repo_dir/scripts/klippy-requirements.txt"

    log_success "Kalico installed. Use 'Engine Manager' to switch to it."
    katana_pause
}

function do_install_klipper() {
    local variant="${1:-Standard}"
    local data_dir="${2:-$HOME/printer_data}"
    local service_name="${3:-klipper}"
    
    log_info "Installing Klipper ($variant) into $data_dir..."
    
    # 0. System Dependencies
    log_info "Installing Klipper System Dependencies (sudo required)..."
    local k_deps=("virtualenv" "python3-dev" "libffi-dev" "build-essential" "libncurses-dev" "libusb-dev" "avrdude" "gcc-avr" "binutils-avr" "avr-libc" "stm32flash" "libnewlib-arm-none-eabi" "gcc-arm-none-eabi" "binutils-arm-none-eabi" "libusb-1.0-0-dev")
    
    wait_for_apt_lock
    sudo apt-get update -qq
    wait_for_apt_lock
    if sudo apt-get install -y "${k_deps[@]}"; then
        log_success "System dependencies installed."
    else
        log_error "Failed to install some dependencies. Check your internet connection."
        # Unattended, this is a hard stop: --yes authorises the installation, it
        # does not authorise continuing without a toolchain. Continuing here is
        # how a fleet host ends up with Klipper that cannot build firmware while
        # the installer exits 0.
        if ! katana_confirm "  Continue anyway? [y/N]: " no; then
            log_error "Aborting: required build dependencies are missing."
            return 1
        fi
    fi
    
    # 1. Repo & Env (Shared across instances)
    local repo_dir="$HOME/klipper"
    if [ ! -d "$repo_dir" ]; then
        exec_silent "Cloning Klipper" "git clone https://github.com/Klipper3d/klipper.git $repo_dir"
    fi

    local env_dir="$HOME/klippy-env"
    if [ ! -d "$env_dir" ]; then
        exec_silent "Creating VirtualEnv" "virtualenv -p python3 $env_dir"
        exec_silent "Installing Dependencies" "$env_dir/bin/pip install -r $repo_dir/scripts/klippy-requirements.txt"
    fi

    # 2. Instance Directories
    mkdir -p "$data_dir/config" "$data_dir/logs" "$data_dir/comms" "$data_dir/gcodes"

    # 3. Service File (Dynamic)
    if ! command -v install_service_from_template &> /dev/null; then
        log_error "Service Manager missing! Klipper service NOT installed."
        return 1
    fi
    if ! install_service_from_template "klipper" "$service_name" "$data_dir"; then
        log_error "Could not install the $service_name systemd unit."
        return 1
    fi

    # Deliberately tolerated: on a freshly imaged host there is no valid
    # printer.cfg and usually no MCU attached yet, so klipper is EXPECTED to
    # fail its first start — it goes online once the MCU is flashed and wired.
    # Treating this as a step failure would make every unattended provisioning
    # run fail on hardware that is not yet connected. The unit is installed and
    # enabled at this point, which is what this step is responsible for.
    sudo systemctl restart "$service_name" || \
        log_warn "$service_name did not start yet (expected until printer.cfg and MCU are in place)."

    # 4. Default Config (First time only)
    local config_file="$data_dir/config/printer.cfg"
    if [ ! -f "$config_file" ]; then
        log_info "Creating default printer.cfg..."
        cat > "$config_file" <<EOF
[stepper_x]
step_pin: PA2
dir_pin: !PA1
enable_pin: !PA3
microsteps: 16
rotation_distance: 40
full_steps_per_rotation: 200

[stepper_y]
step_pin: PA4
dir_pin: !PA5
enable_pin: !PA6
microsteps: 16
rotation_distance: 40
full_steps_per_rotation: 200

[stepper_z]
step_pin: PC14
dir_pin: !PC15
enable_pin: !PC13
microsteps: 16
rotation_distance: 8
full_steps_per_rotation: 200

[extruder]
step_pin: PA7
dir_pin: !PA8
enable_pin: !PA9
microsteps: 16
rotation_distance: 33.5
full_steps_per_rotation: 200

[heater_bed]
heater_pin: PC1

[fan]
pin: PC0

[mcu]
serial: /dev/serial/by-id/change-me

[printer]
kinematics: cartesian
max_velocity: 300
max_accel: 3000
max_z_velocity: 5
max_z_accel: 100
EOF
    fi

    log_success "Klipper instance '$service_name' ready."
}

function do_install_moonraker() {
    local data_dir="${1:-$HOME/printer_data}"
    local service_name="${2:-moonraker}"
    local port="${3:-7125}"
    
    log_info "Installing Moonraker into $data_dir (Port: $port)..."
    
    # 1. System Dependencies
    log_info "Installing system dependencies..."
    wait_for_apt_lock
    sudo apt-get update -qq
    wait_for_apt_lock
    # Deliberately tolerated: several of these package names differ between
    # Debian releases (packagekit, libopenjp2-7), and a missing optional one
    # must not abort provisioning. The venv/pip step below is the real gate —
    # if a genuinely required header is absent, the requirements install fails
    # there with a readable error instead of here with an apt exit code.
    sudo apt-get install -y python3-virtualenv python3-dev liblmdb-dev \
        libopenjp2-7 libsodium-dev zlib1g-dev libjpeg-dev packagekit \
        python3-wheel python3-setuptools >>"${LOG_FILE:-/dev/null}" 2>&1 || \
        log_warn "Some Moonraker system packages were unavailable — see ${LOG_FILE:-the log}."

    # 2. Clone Repo
    local repo_dir="$HOME/moonraker"
    if [ ! -d "$repo_dir" ]; then
        exec_silent "Cloning Moonraker" "git clone https://github.com/Arksine/moonraker.git $repo_dir"
    fi

    # 3. VirtualEnv + Requirements
    local env_dir="$HOME/moonraker-env"
    if [ ! -d "$env_dir" ]; then
        exec_silent "Creating VirtualEnv" "virtualenv -p python3 $env_dir"
    fi
    log_info "Installing Moonraker Python packages..."
    if ! "$env_dir/bin/pip" install --upgrade pip setuptools wheel >>"${LOG_FILE:-/dev/null}" 2>&1; then
        log_error "Could not bootstrap pip/setuptools/wheel in $env_dir — the virtualenv is unusable."
        return 1
    fi
    # Previously `pip install ... | tail -3`: the pipeline's exit status was
    # tail's, so every dependency failure was reported as success and Moonraker
    # was installed without its dependencies. The full output goes to the log,
    # the tail stays on screen, and the status is now pip's.
    if ! "$env_dir/bin/pip" install -r "$repo_dir/scripts/moonraker-requirements.txt" \
            >>"${LOG_FILE:-/dev/null}" 2>&1; then
        log_error "Moonraker dependency installation failed — last lines:"
        tail -n 10 "${LOG_FILE:-/dev/null}" 2>/dev/null || true
        return 1
    fi

    # 4. Instance Directories
    mkdir -p "$data_dir/config" "$data_dir/logs" "$data_dir/comms" "$data_dir/gcodes" "$data_dir/systemd"

    # 5. Instance Config (moonraker.conf) — regenerate if broken
    # Validation via Python core (katana_core.config_check), grep fallback.
    local moonraker_conf="$data_dir/config/moonraker.conf"
    if [ -f "$moonraker_conf" ] && ! katana_moonraker_conf_valid "$moonraker_conf"; then
        log_warn "Existing moonraker.conf is broken. Regenerating..."
        mv "$moonraker_conf" "${moonraker_conf}.broken.$(date +%s)"
    fi
    if [ ! -f "$moonraker_conf" ]; then
        cat > "$moonraker_conf" <<EOF
[server]
host = 0.0.0.0
port = $port
klippy_uds_address = $data_dir/comms/klippy.sock

[authorization]
trusted_clients =
    127.0.0.1
    192.168.0.0/16
    10.0.0.0/8
    172.16.0.0/12
cors_domains =
    *://localhost
    *://localhost:*
    *://*.local
    *://*.local:*

[file_manager]
enable_object_processing = True

[octoprint_compat]

[history]

[update_manager]
enable_auto_refresh = True
EOF
        log_success "moonraker.conf created."
    fi

    # 6. Service File (uses our template with direct Python path)
    if ! command -v install_service_from_template &> /dev/null; then
        log_error "Service Manager missing!"
        return 1
    fi
    if ! install_service_from_template "moonraker" "$service_name" "$data_dir"; then
        log_error "Could not install the $service_name systemd unit."
        return 1
    fi
    
    # 7. PolKit Permissions
    local current_user
    current_user=$(whoami)
    log_info "Setting up PolicyKit rules..."
    
    sudo mkdir -p /etc/polkit-1/rules.d
    sudo tee /etc/polkit-1/rules.d/moonraker.rules > /dev/null << POLRULES
// PolicyKit rules for Moonraker
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.systemd1.manage-units" ||
         action.id == "org.freedesktop.login1.power-off" ||
         action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
         action.id == "org.freedesktop.login1.reboot" ||
         action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
         action.id == "org.freedesktop.packagekit.system-sources-refresh" ||
         action.id == "org.freedesktop.packagekit.package-install" ||
         action.id == "org.freedesktop.packagekit.system-update") &&
        subject.user == "$current_user") {
        return polkit.Result.YES;
    }
});
POLRULES

    sudo mkdir -p /etc/polkit-1/localauthority/50-local.d
    sudo tee /etc/polkit-1/localauthority/50-local.d/moonraker.pkla > /dev/null << POLLIT
[Allow Moonraker All]
Identity=unix-user:$current_user
Action=org.freedesktop.systemd1.manage-units;org.freedesktop.login1.reboot;org.freedesktop.login1.reboot-multiple-sessions;org.freedesktop.login1.power-off;org.freedesktop.login1.power-off-multiple-sessions;org.freedesktop.packagekit.system-sources-refresh;org.freedesktop.packagekit.package-install;org.freedesktop.packagekit.system-update
ResultActive=yes
POLLIT

    log_success "PolicyKit rules installed."

    # 8. Start Service
    sudo systemctl daemon-reload
    # Tolerated: `enable` is idempotent and already done by the template
    # installer; a non-zero here (unit already enabled, no-op link) must not
    # abort the run.
    sudo systemctl enable "$service_name" >>"${LOG_FILE:-/dev/null}" 2>&1 || true
    # Tolerated at this line only so the health check below can produce a
    # readable diagnosis instead of a bare exit code.
    sudo systemctl restart "$service_name" || true

    # Unlike klipper, Moonraker does not need an MCU or a printer.cfg to run.
    # If it is not up after the grace period the install did not succeed, and
    # saying so is the entire point of an unattended installer: a warning here
    # used to let the step return 0 with no API server on the host.
    local waited=0
    while [ "$waited" -lt 15 ]; do
        if systemctl is-active --quiet "$service_name" 2>/dev/null; then
            log_success "Moonraker is RUNNING on port $port."
            return 0
        fi
        sleep 1
        waited=$((waited + 1))
    done

    log_error "Moonraker did not come up within 15s. Last log lines:"
    sudo journalctl -u "$service_name" -n 15 --no-pager 2>/dev/null || true
    return 1
}

function update_core_stack() {
    draw_header "UPDATE KLIPPER & MOONRAKER"
    echo "  1) Update Klipper"
    echo "  2) Update Moonraker"
    echo "  3) Update Both"
    echo "  B) Back"
    read -r -p "  >> " ch

    case $ch in
        1) do_update_klipper ;;
        2) do_update_moonraker ;;
        3) do_update_klipper && do_update_moonraker ;;
        [bB]) return ;;
    esac
}

function do_update_klipper() {
    local klipper_dir="$HOME/klipper"
    
    if [ ! -d "$klipper_dir" ]; then
        log_error "Klipper not installed. Install it first."
        katana_pause
        return 1
    fi

    log_info "Updating Klipper..."
    
    cd "$klipper_dir" || { log_error "Klipper directory not found"; return 1; }
    
    # Auto-detect default branch (master or main)
    local branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    if [ -z "$branch" ]; then
        # Fallback: check which branch exists
        if git rev-parse --verify origin/master &>/dev/null; then
            branch="master"
        else
            branch="main"
        fi
    fi
    
    # Check for updates
    local current_sha=$(git rev-parse HEAD)
    git fetch origin
    local latest_sha=$(git rev-parse origin/$branch 2>/dev/null)
    
    if [ "$current_sha" == "$latest_sha" ]; then
        log_success "Klipper is already up to date."
    else
        log_info "Updating from $(git rev-parse --short HEAD) to $(git rev-parse --short origin/$branch)..."
        git pull origin $branch
        
        # Rebuild
        log_info "Rebuilding Klipper..."
        make clean
        make -j$(nproc)
        
        # Restart service
        sudo systemctl restart klipper
        sleep 2
        
        if systemctl is-active --quiet klipper; then
            log_success "Klipper updated and restarted."
        else
            log_error "Klipper failed to start after update!"
        fi
    fi
    
    katana_pause
}

function do_update_moonraker() {
    local moonraker_dir="$HOME/moonraker"
    
    if [ ! -d "$moonraker_dir" ]; then
        log_error "Moonraker not installed. Install it first."
        katana_pause
        return 1
    fi

    log_info "Updating Moonraker..."
    
    cd "$moonraker_dir" || { log_error "Moonraker directory not found"; return 1; }
    
    # Auto-detect default branch
    local branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    if [ -z "$branch" ]; then
        if git rev-parse --verify origin/master &>/dev/null; then
            branch="master"
        else
            branch="main"
        fi
    fi
    
    # Check for updates
    local current_sha=$(git rev-parse HEAD)
    git fetch origin
    local latest_sha=$(git rev-parse origin/$branch 2>/dev/null)
    
    if [ "$current_sha" == "$latest_sha" ]; then
        log_success "Moonraker is already up to date."
    else
        log_info "Updating from $(git rev-parse --short HEAD) to $(git rev-parse --short origin/$branch)..."
        git pull origin $branch
        
        # Install requirements
        log_info "Installing dependencies..."
        "$HOME/moonraker-env/bin/pip" install -r scripts/moonraker-requirements.txt --upgrade
        
        # Restart service
        sudo systemctl restart moonraker
        sleep 2
        
        if systemctl is-active --quiet moonraker; then
            log_success "Moonraker updated and restarted."
        else
            log_error "Moonraker failed to start after update!"
        fi
    fi
    
    katana_pause
}
