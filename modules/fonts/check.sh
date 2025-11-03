#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../bin/lib/core.sh"
source "${SCRIPT_DIR}/../../bin/lib/doctor.sh"

check_fonts() {
    log_step "Checking fonts installation..."

    # Check fonts directory exists
    case "${DOTFILES_OS}" in
        linux)
            local fonts_dir="${HOME}/.local/share/fonts"
            doctor_check_directory "${fonts_dir}" "fonts directory"

            # Check if any Nerd Font is installed
            if find "${fonts_dir}" -name "*Nerd Font*.ttf" 2>/dev/null | grep -q .; then
                doctor_check "nerd-fonts" "pass" "Nerd Fonts are installed"
            else
                doctor_check "nerd-fonts" "fail" "No Nerd Fonts found"
            fi

            # Check font cache
            if command_exists fc-cache; then
                doctor_check "fc-cache" "pass" "Font cache utility available"
            else
                doctor_check "fc-cache" "warn" "fc-cache not available"
            fi
            ;;
        macos)
            local fonts_dir="${HOME}/Library/Fonts"
            doctor_check_directory "${fonts_dir}" "fonts directory"

            # Check if any Nerd Font is installed
            if find "${fonts_dir}" -name "*Nerd Font*.ttf" 2>/dev/null | grep -q .; then
                doctor_check "nerd-fonts" "pass" "Nerd Fonts are installed"
            else
                doctor_check "nerd-fonts" "fail" "No Nerd Fonts found"
            fi
            ;;
    esac

    return 0
}

check_fonts "$@"
