#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../bin/lib/core.sh"

uninstall_oh_my_posh() {
    log_step "Uninstalling oh-my-posh..."

    case "${DOTFILES_OS}" in
        linux)
            if [[ -f "${HOME}/bin/oh-my-posh" ]]; then
                log_info "Removing ~/bin/oh-my-posh..."
                rm -f "${HOME}/bin/oh-my-posh"
            fi
            ;;
        macos)
            if command_exists brew && brew list oh-my-posh &>/dev/null; then
                log_info "Removing oh-my-posh via Homebrew..."
                brew uninstall oh-my-posh
            fi
            ;;
    esac

    # Remove shell integration
    for shell in bash zsh; do
        remove_shell_module "oh-my-posh" "${shell}"
    done

    # Keep theme files in case user wants them
    log_info "Keeping theme files in ~/.config/oh-my-posh (remove manually if desired)"

    mark_uninstalled "oh-my-posh"
    log_success "oh-my-posh uninstalled"
}

uninstall_oh_my_posh "$@"
