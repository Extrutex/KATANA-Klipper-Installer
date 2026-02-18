#!/bin/bash
# core/service_manager.sh
# KATANA Core Module: Service Management & Templating
# Professionalizes systemd unit creation.

function install_service_from_template() {
    local service_type="$1"
    local target_service_name="${2:-$service_type}"
    local target_data_dir="${3:-$HOME/printer_data}"
    local template_path="$KATANA_ROOT/configs/templates/services/${service_type}.service.template"
    local target_path="/etc/systemd/system/${target_service_name}.service"
    
    log_info "Deploying Service Template: $service_type -> $target_service_name"
    
    if [ ! -f "$template_path" ]; then
        log_error "Template not found: $template_path"
        return 1
    fi
    
    # Check Sudo (required for /etc/systemd)
    if ! sudo -n true 2>/dev/null; then
         log_warn "Sudo required to install service."
         sudo -v
    fi
    
    # Render Template
    # Replace template variables
    # Safe pattern: using | as delimiter to avoid path clashes
    local rendered_content=$(cat "$template_path" | \
        sed "s|{{USER}}|$USER|g" | \
        sed "s|{{HOME}}|$HOME|g" | \
        sed "s|{{SERVICE_NAME}}|$target_service_name|g" | \
        sed "s|{{DATA_DIR}}|$target_data_dir|g")
        
    # Write to target
    echo "$rendered_content" | sudo tee "$target_path" > /dev/null
    
    if [ $? -eq 0 ]; then
        log_success "Service unit created: $target_path"
        
        # Reload & Enable
        sudo systemctl daemon-reload
        sudo systemctl enable "$target_service_name"
        log_info "Service enabled."
    else
        log_error "Failed to write service file."
        return 1
    fi
}

function verify_service_health() {
    local service_name="$1"
    if systemctl is-active --quiet "$service_name"; then
        log_success "Service $service_name is RUNNING."
        return 0
    else
        log_warn "Service $service_name is NOT running."
        return 1
    fi
}
