#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../bin/lib/core.sh"

install_git() {
    log_step "Installing Git configuration..."

    # Check if git is installed
    require_command "git" "Install git first"

    # Install config files
    log_info "Installing Git configuration files..."
    install_file "${SCRIPT_DIR}/config/.gitconfig" "${HOME}/.gitconfig"
    install_file "${SCRIPT_DIR}/config/.gitignore_global" "${HOME}/.gitignore_global"

    # Verify config
    log_info "Git configuration:"
    git config --global user.name || true
    git config --global user.email || true

    mark_installed "git" "1.0.0"
    log_success "Git configuration installed"
    log_info "You can customize ~/.gitconfig as needed"
}

install_git "$@"
