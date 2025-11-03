#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../bin/lib/core.sh"

uninstall_go() {
    log_step "Uninstalling Go..."

    case "${DOTFILES_OS}" in
        linux)
            if [[ -d "/usr/local/go" ]]; then
                log_info "Removing /usr/local/go..."
                sudo rm -rf /usr/local/go
            fi
            ;;
        macos)
            if command_exists brew && brew list go &>/dev/null; then
                log_info "Removing Go via Homebrew..."
                brew uninstall go
            fi
            ;;
    esac

    # Remove shell integration
    for shell in bash zsh; do
        remove_shell_module "go" "${shell}"
    done

    # Note: We don't remove ~/go directory as it may contain user projects

    mark_uninstalled "go"
    log_success "Go uninstalled"
    log_info "Note: ~/go directory was preserved (contains your Go projects)"
}

uninstall_go "$@"
