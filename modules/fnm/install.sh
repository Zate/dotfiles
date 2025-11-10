#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../bin/lib/core.sh"

get_latest_fnm_version() {
    # No longer needed - we'll use local checks only
    echo ""
}

get_installed_fnm_version() {
    if ! command_exists fnm; then
        echo ""
        return
    fi
    
    fnm --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'
}

install_fnm_linux() {
    local version="$1"
    
    log_info "Installing fnm ${version} via install script..."
    
    # Check dependencies
    require_command "curl" "Install curl: apt-get install curl"
    
    # Install using the official install script
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "${HOME}/.fnm" --skip-shell
    
    log_success "fnm ${version} installed"
}

install_fnm_macos() {
    log_info "Managing fnm via Homebrew..."
    
    # Check if fnm is already available
    if command_exists fnm; then
        local current_version
        current_version=$(fnm --version 2>/dev/null | head -1)
        log_info "fnm is already installed: ${current_version}"
        
        # Try to upgrade
        log_info "Upgrading fnm..."
        brew upgrade fnm 2>/dev/null || log_info "fnm is already up to date"
    else
        log_info "Installing fnm..."
        brew install fnm
    fi
    
    local final_version
    final_version=$(fnm --version 2>/dev/null | head -1)
    log_success "fnm ready: ${final_version}"
}

setup_fnm_shell_integration() {
    log_info "Setting up shell integration..."
    
    # Create shell module for both bash and zsh using the core function
    for shell in bash zsh; do
        create_shell_module "fnm" "# fnm (Fast Node Manager) environment
export FNM_DIR=\"\${HOME}/.fnm\"
if command -v fnm >/dev/null 2>&1; then
    eval \"\$(fnm env --use-on-cd)\" 2>/dev/null
fi" "${shell}"
    done
    
    log_success "Shell integration configured"
}

install_default_node() {
    log_info "Setting up default Node.js version..."
    
    # Source fnm environment
    export FNM_DIR="${HOME}/.fnm"
    if command_exists fnm; then
        eval "$(fnm env --use-on-cd)"
        
        # Install and use latest LTS
        log_info "Installing latest LTS Node.js..."
        fnm install --lts
        fnm use lts-latest
        fnm default lts-latest
        
        local node_version
        if command_exists node; then
            node_version=$(node --version)
            log_success "Node.js ${node_version} set as default"
        fi
    else
        log_warning "fnm not found in PATH, skipping Node.js installation"
    fi
}

install_fnm() {
    log_step "Installing fnm..."
    
    # Install based on platform
    case "${DOTFILES_OS}" in
        linux)
            install_fnm_linux
            ;;
        macos)
            install_fnm_macos
            ;;
    esac
    
    # Setup shell integration
    setup_fnm_shell_integration
    
    # Install default Node.js version if fnm is available
    if command_exists fnm; then
        install_default_node
    fi
    
    # Get the installed version for tracking
    local final_version
    final_version=$(get_installed_fnm_version)
    
    mark_installed "fnm" "${final_version}"
    log_success "fnm installation complete!"
    log_info "Please restart your shell or run: source ~/.${DOTFILES_SHELL}rc"
}

install_fnm "$@"