#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../bin/lib/core.sh"

uninstall_git() {
    log_step "Uninstalling Git configuration..."

    # Just mark as uninstalled, don't remove config files as user may have customized them
    log_info "Keeping configuration files (they may be customized)"
    log_info "To remove manually:"
    log_info "  rm ~/.gitconfig ~/.gitignore_global"

    mark_uninstalled "git"
    log_success "Git configuration marked as uninstalled"
}

uninstall_git "$@"
