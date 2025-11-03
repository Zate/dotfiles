#!/usr/bin/env bash
#
# module.sh - Module management functions
#

source "$(dirname "${BASH_SOURCE[0]}")/core.sh"

#
# Module information
#

list_available_modules() {
    local modules_dir="${DOTFILES_MODULES}"

    [[ -d "${modules_dir}" ]] || return 0

    for module_dir in "${modules_dir}"/*; do
        [[ -d "${module_dir}" ]] || continue
        basename "${module_dir}"
    done
}

module_exists() {
    local module="$1"
    [[ -d "${DOTFILES_MODULES}/${module}" ]]
}

get_module_info() {
    local module="$1"
    local key="$2"

    local conf_file="${DOTFILES_MODULES}/${module}/module.conf"

    if [[ ! -f "${conf_file}" ]]; then
        echo "unknown"
        return 1
    fi

    # Source the config and return the value
    (
        source "${conf_file}"
        echo "${!key:-unknown}"
    )
}

is_module_supported() {
    local module="$1"

    local platforms
    platforms=$(get_module_info "${module}" "PLATFORMS")

    if [[ "${platforms}" == "unknown" ]]; then
        # No platform restriction
        return 0
    fi

    # Check if current platform is supported
    if [[ "${platforms}" == *"${DOTFILES_OS}"* ]]; then
        return 0
    fi

    return 1
}

#
# Module operations
#

install_module() {
    local module="$1"

    if ! module_exists "${module}"; then
        die "Module '${module}' does not exist"
    fi

    if ! is_module_supported "${module}"; then
        log_warning "Module '${module}' is not supported on ${DOTFILES_OS}"
        return 1
    fi

    if is_installed "${module}"; then
        log_info "Module '${module}' is already installed"
        if ! confirm "Reinstall ${module}?"; then
            return 0
        fi
    fi

    local install_script="${DOTFILES_MODULES}/${module}/install.sh"

    if [[ ! -f "${install_script}" ]]; then
        die "Install script not found for module '${module}'"
    fi

    log_step "Installing ${module}..."

    # Run install script
    if bash "${install_script}"; then
        log_success "${module} installed successfully"
        return 0
    else
        log_error "Failed to install ${module}"
        return 1
    fi
}

update_module() {
    local module="$1"

    if ! is_installed "${module}"; then
        log_warning "Module '${module}' is not installed"
        return 1
    fi

    local update_script="${DOTFILES_MODULES}/${module}/update.sh"

    if [[ -f "${update_script}" ]]; then
        log_step "Updating ${module}..."
        if bash "${update_script}"; then
            log_success "${module} updated successfully"
            return 0
        else
            log_error "Failed to update ${module}"
            return 1
        fi
    else
        # No update script, try reinstalling
        log_info "No update script for ${module}, reinstalling..."
        install_module "${module}"
    fi
}

uninstall_module() {
    local module="$1"

    if ! is_installed "${module}"; then
        log_warning "Module '${module}' is not installed"
        return 1
    fi

    local uninstall_script="${DOTFILES_MODULES}/${module}/uninstall.sh"

    if [[ ! -f "${uninstall_script}" ]]; then
        log_warning "No uninstall script for module '${module}'"
        if ! confirm "Remove ${module} from installed list anyway?"; then
            return 1
        fi
        mark_uninstalled "${module}"
        return 0
    fi

    if ! confirm "Uninstall ${module}?"; then
        return 0
    fi

    log_step "Uninstalling ${module}..."

    # Run uninstall script
    if bash "${uninstall_script}"; then
        log_success "${module} uninstalled successfully"
        return 0
    else
        log_error "Failed to uninstall ${module}"
        return 1
    fi
}

#
# Batch operations
#

install_modules() {
    local modules=("$@")
    local failed=0

    for module in "${modules[@]}"; do
        if ! install_module "${module}"; then
            failed=$((failed + 1))
        fi
    done

    if [[ ${failed} -eq 0 ]]; then
        log_success "All modules installed successfully"
        return 0
    else
        log_error "${failed} module(s) failed to install"
        return 1
    fi
}

update_modules() {
    local modules=("$@")

    if [[ ${#modules[@]} -eq 0 ]]; then
        # Update all installed modules
        mapfile -t modules < <(get_installed_modules)
    fi

    local failed=0

    for module in "${modules[@]}"; do
        if ! update_module "${module}"; then
            failed=$((failed + 1))
        fi
    done

    if [[ ${failed} -eq 0 ]]; then
        log_success "All modules updated successfully"
        return 0
    else
        log_error "${failed} module(s) failed to update"
        return 1
    fi
}

uninstall_modules() {
    local modules=("$@")
    local failed=0

    for module in "${modules[@]}"; do
        if ! uninstall_module "${module}"; then
            failed=$((failed + 1))
        fi
    done

    if [[ ${failed} -eq 0 ]]; then
        log_success "All modules uninstalled successfully"
        return 0
    else
        log_error "${failed} module(s) failed to uninstall"
        return 1
    fi
}
