#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../bin/lib/core.sh"

check_fnm() {
    log_step "Checking fnm..."
    
    # Check if fnm is installed
    if ! command_exists fnm; then
        log_error "fnm is not installed"
        return 1
    fi
    
    local version
    version=$(fnm --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    
    if [[ -n "${version}" ]]; then
        log_success "fnm ${version} is installed"
    else
        log_error "fnm is installed but version could not be determined"
        return 1
    fi
    
    # Check if shell integration is working
    if [[ -n "${FNM_DIR:-}" ]]; then
        log_success "fnm environment is configured"
    else
        log_warning "fnm environment variables not set (restart shell may be needed)"
    fi
    
    # Check if Node.js is available through fnm
    if command_exists node; then
        local node_version
        node_version=$(node --version)
        log_success "Node.js ${node_version} is available"
    else
        log_info "No Node.js version is currently active"
        log_info "Run 'fnm install --lts && fnm use lts-latest' to install Node.js"
    fi
    
    return 0
}

check_fnm "$@"