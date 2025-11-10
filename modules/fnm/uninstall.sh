#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../bin/lib/core.sh"

uninstall_fnm() {
    log_step "Uninstalling fnm..."
    
    # Remove based on platform
    case "${DOTFILES_OS}" in
        linux)
            log_info "Removing fnm directory..."
            rm -rf "${HOME}/.fnm"
            ;;
        macos)
            if command_exists brew && brew list fnm &>/dev/null; then
                log_info "Uninstalling fnm via Homebrew..."
                brew uninstall fnm
            fi
            # Also clean up directory if it exists
            if [[ -d "${HOME}/.fnm" ]]; then
                rm -rf "${HOME}/.fnm"
            fi
            ;;
    esac
    
    # Remove shell integration
    for shell in bash zsh; do
        local module_file="${DOTFILES_REPO}/shell/${shell}/modules.d/50-fnm.sh"
        if [[ -f "${module_file}" ]]; then
            rm -f "${module_file}"
            log_debug "Removed shell module: ${module_file}"
        fi
    done
    
    mark_uninstalled "fnm"
    log_success "fnm uninstalled"
    log_info "Please restart your shell to complete removal"
}

uninstall_fnm "$@"