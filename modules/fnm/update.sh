#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../bin/lib/core.sh"

update_fnm() {
    log_step "Updating fnm..."
    
    if ! command_exists fnm; then
        log_error "fnm is not installed"
        return 1
    fi
    
    local current_version
    current_version=$(fnm --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    
    log_info "Current fnm version: ${current_version}"
    
    # Update based on platform
    case "${DOTFILES_OS}" in
        linux)
            log_info "Updating fnm via install script..."
            curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "${HOME}/.fnm" --skip-shell
            ;;
        macos)
            if command_exists brew && brew list fnm &>/dev/null; then
                log_info "Updating fnm via Homebrew..."
                brew upgrade fnm
            else
                log_error "fnm not installed via Homebrew"
                return 1
            fi
            ;;
    esac
    
    local new_version
    new_version=$(fnm --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    
    if [[ "${current_version}" != "${new_version}" ]]; then
        log_success "fnm updated from ${current_version} to ${new_version}"
        mark_installed "fnm" "${new_version}"
    else
        log_info "fnm is already up to date (${current_version})"
    fi
}

update_fnm "$@"