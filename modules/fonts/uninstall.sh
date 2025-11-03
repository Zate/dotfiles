#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../bin/lib/core.sh"

uninstall_fonts() {
    log_step "Uninstalling fonts..."

    case "${DOTFILES_OS}" in
        linux)
            local fonts_dir="${HOME}/.local/share/fonts"
            find "${fonts_dir}" -name "*Nerd Font*" -delete 2>/dev/null || true

            if command_exists fc-cache; then
                log_info "Refreshing font cache..."
                fc-cache -fv >/dev/null 2>&1
            fi
            ;;
        macos)
            local fonts_dir="${HOME}/Library/Fonts"
            find "${fonts_dir}" -name "*Nerd Font*" -delete 2>/dev/null || true
            ;;
    esac

    mark_uninstalled "fonts"
    log_success "Fonts uninstalled"
}

uninstall_fonts "$@"
