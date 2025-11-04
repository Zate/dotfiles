#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../bin/lib/core.sh"
source "${SCRIPT_DIR}/../../bin/lib/doctor.sh"

check_iterm2_font() {
    # Check if iTerm2 is installed and configured with Meslo
    if [[ ! -d "/Applications/iTerm.app" ]]; then
        log_debug "iTerm2 not found"
        return
    fi

    local iterm_prefs="${HOME}/Library/Preferences/com.googlecode.iterm2.plist"
    if [[ ! -f "${iterm_prefs}" ]]; then
        doctor_check "iterm2-font" "warn" "iTerm2 preferences not found"
        return
    fi

    # Try to read the font setting
    # Format in plist: "Normal Font" = "FontName Size";
    local current_font
    current_font=$(defaults read com.googlecode.iterm2 2>/dev/null | grep "Normal Font" | sed 's/.*= "\(.*\)";/\1/' || echo "")

    if [[ -z "${current_font}" ]] || [[ "${current_font}" == "Normal Font"* ]]; then
        doctor_check "iterm2-font" "warn" "Could not determine iTerm2 font"
        log_info "  Manually check: iTerm2 → Preferences → Profiles → Text"
        return
    fi

    # Check if it's a Meslo Nerd Font
    if [[ "${current_font}" == *"MesloLG"* ]] || [[ "${current_font}" == *"Meslo"* ]]; then
        doctor_check "iterm2-font" "pass" "iTerm2 configured with: ${current_font}"
    else
        doctor_check "iterm2-font" "fail" "iTerm2 not using Meslo Nerd Font (current: ${current_font})"
        log_info "  Fix: iTerm2 → Preferences → Profiles → Text → Select 'MesloLGLDZ Nerd Font'"
    fi
}

check_fonts() {
    log_step "Checking fonts installation..."

    # Check fonts directory exists
    case "${DOTFILES_OS}" in
        linux)
            local fonts_dir="${HOME}/.local/share/fonts"
            doctor_check_directory "${fonts_dir}" "fonts directory"

            # Check specifically for Meslo Nerd Font
            if find "${fonts_dir}" -name "MesloLG*NerdFont*.ttf" 2>/dev/null | grep -q .; then
                local meslo_count
                meslo_count=$(find "${fonts_dir}" -name "MesloLG*NerdFont*.ttf" 2>/dev/null | wc -l)
                doctor_check "meslo-nerd-font" "pass" "Meslo LG Nerd Font installed (${meslo_count} fonts)"
            else
                doctor_check "meslo-nerd-font" "fail" "Meslo LG Nerd Font not found"
                log_info "  Install: dotfiles install fonts"
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

            # Check specifically for Meslo Nerd Font files
            if find "${fonts_dir}" -name "MesloLG*NerdFont*.ttf" 2>/dev/null | grep -q .; then
                local meslo_count
                meslo_count=$(find "${fonts_dir}" -name "MesloLG*NerdFont*.ttf" 2>/dev/null | wc -l)
                doctor_check "meslo-nerd-font" "pass" "Meslo LG Nerd Font installed (${meslo_count} fonts)"
            else
                doctor_check "meslo-nerd-font" "fail" "Meslo LG Nerd Font not found"
                log_info "  Install: dotfiles install fonts"
            fi

            # Check if installed via Homebrew (preferred on macOS)
            if command_exists brew; then
                if brew list --cask font-meslo-lg-nerd-font &>/dev/null; then
                    local brew_version
                    brew_version=$(brew info --cask font-meslo-lg-nerd-font 2>/dev/null | head -1 | awk '{print $3}')
                    doctor_check "brew-font" "pass" "Meslo LG Nerd Font installed via Homebrew (${brew_version})"
                else
                    doctor_check "brew-font" "warn" "Meslo LG Nerd Font not installed via Homebrew (recommended)"
                    log_info "  Install: brew install --cask font-meslo-lg-nerd-font"
                fi
            fi

            # Check iTerm2 configuration
            check_iterm2_font
            ;;
    esac

    return 0
}

check_fonts "$@"
