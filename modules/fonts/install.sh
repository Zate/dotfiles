#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../bin/lib/core.sh"

readonly NERD_FONTS_VERSION="v3.1.1"

# Primary font: Meslo LG Nerd Font (recommended for oh-my-posh)
readonly PRIMARY_FONT="Meslo"
readonly PRIMARY_FONT_BREW="font-meslo-lg-nerd-font"

# Additional fonts for Linux (direct download)
readonly FONTS_TO_INSTALL=(
    "Meslo"
    "FiraCode"
    "JetBrainsMono"
)

install_font_linux() {
    local font_name="$1"
    local fonts_dir="${HOME}/.local/share/fonts"

    mkdir -p "${fonts_dir}"

    log_info "Installing ${font_name}..."

    local download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}/${font_name}.zip"
    local temp_dir
    temp_dir=$(mktemp -d)

    # Download and extract
    download_file "${download_url}" "${temp_dir}/${font_name}.zip"
    unzip -q "${temp_dir}/${font_name}.zip" -d "${temp_dir}/${font_name}"

    # Copy font files
    find "${temp_dir}/${font_name}" -name "*.ttf" -o -name "*.otf" | while read -r font_file; do
        cp "${font_file}" "${fonts_dir}/"
    done

    # Clean up
    rm -rf "${temp_dir}"
}

configure_iterm2_font() {
    # Configure iTerm2 to use Meslo Nerd Font
    local iterm_plist="${HOME}/Library/Preferences/com.googlecode.iterm2.plist"

    if [[ ! -d "/Applications/iTerm.app" ]]; then
        log_debug "iTerm2 not installed, skipping configuration"
        return 0
    fi

    if [[ ! -f "${iterm_plist}" ]]; then
        log_debug "iTerm2 preferences not found, skipping configuration"
        return 0
    fi

    log_info "Configuring iTerm2 to use Meslo LG Nerd Font..."

    # Set font for all profiles
    local profile_count
    profile_count=$(/usr/libexec/PlistBuddy -c "Print :New\ Bookmarks" "${iterm_plist}" 2>/dev/null | grep -c "Guid =" || echo "0")

    if [[ ${profile_count} -eq 0 ]]; then
        log_warning "No iTerm2 profiles found"
        return 0
    fi

    # Update each profile (usually just the Default profile at index 0)
    for ((i=0; i<profile_count; i++)); do
        local profile_name
        profile_name=$(/usr/libexec/PlistBuddy -c "Print :New\ Bookmarks:${i}:Name" "${iterm_plist}" 2>/dev/null || echo "")

        if [[ -n "${profile_name}" ]]; then
            log_debug "Setting font for profile '${profile_name}'"
            /usr/libexec/PlistBuddy -c "Set :New\ Bookmarks:${i}:Normal\ Font 'MesloLGLDZ Nerd Font 13'" "${iterm_plist}" 2>/dev/null || true
            /usr/libexec/PlistBuddy -c "Set :New\ Bookmarks:${i}:Non\ Ascii\ Font 'MesloLGLDZ Nerd Font 13'" "${iterm_plist}" 2>/dev/null || true
        fi
    done

    log_success "iTerm2 configured to use Meslo LG Nerd Font"
    log_info "Restart iTerm2 for changes to take effect"
}

install_fonts_macos() {
    log_info "Installing Meslo LG Nerd Font via Homebrew..."

    ensure_brew_installed

    # Note: homebrew/cask-fonts tap was deprecated and migrated to homebrew/cask
    # Fonts are now available directly without needing to tap homebrew/cask-fonts

    # Check if fonts are already manually installed (conflict with Homebrew)
    local fonts_dir="${HOME}/Library/Fonts"
    if find "${fonts_dir}" -name "MesloLG*NerdFont*.ttf" 2>/dev/null | grep -q .; then
        if ! brew list --cask "${PRIMARY_FONT_BREW}" &>/dev/null; then
            log_warning "Meslo fonts found in ${fonts_dir} (manually installed)"
            log_info "Removing manually installed fonts to use Homebrew..."
            find "${fonts_dir}" -name "MesloLG*NerdFont*.ttf" -delete
            log_success "Removed manually installed fonts"
        fi
    fi

    # Install Meslo LG Nerd Font (primary font for oh-my-posh)
    log_info "Installing ${PRIMARY_FONT_BREW}..."
    if brew list --cask "${PRIMARY_FONT_BREW}" &>/dev/null; then
        log_debug "${PRIMARY_FONT_BREW} already installed, upgrading..."
        brew upgrade --cask "${PRIMARY_FONT_BREW}" 2>/dev/null || log_debug "${PRIMARY_FONT_BREW} already at latest version"
    else
        brew install --cask "${PRIMARY_FONT_BREW}"
    fi

    # Verify the font was installed
    if ! brew list --cask "${PRIMARY_FONT_BREW}" &>/dev/null; then
        die "Failed to install ${PRIMARY_FONT_BREW}"
    fi

    log_success "Meslo LG Nerd Font installed via Homebrew"

    # Automatically configure iTerm2 if available
    configure_iterm2_font
}

install_fonts() {
    log_step "Installing Nerd Fonts..."

    case "${DOTFILES_OS}" in
        linux)
            # Check dependencies for Linux
            require_command "unzip" "Install unzip: apt-get install unzip"

            # Install each font
            for font in "${FONTS_TO_INSTALL[@]}"; do
                install_font_linux "${font}"
            done
            ;;
        macos)
            # Use Homebrew casks on macOS
            install_fonts_macos
            ;;
    esac

    # Refresh font cache
    case "${DOTFILES_OS}" in
        linux)
            if command_exists fc-cache; then
                log_info "Refreshing font cache..."
                fc-cache -fv >/dev/null 2>&1
            fi
            ;;
        macos)
            # macOS handles font cache automatically
            :
            ;;
    esac

    # Special handling for WSL - copy to Windows fonts directory
    if [[ "${DOTFILES_ENV}" == "wsl" ]]; then
        log_info "WSL detected, copying fonts to Windows..."
        local win_fonts_dir="/mnt/c/Windows/Fonts"
        if [[ -d "${win_fonts_dir}" ]]; then
            local linux_fonts_dir="${HOME}/.local/share/fonts"
            find "${linux_fonts_dir}" -name "*.ttf" -o -name "*.otf" | while read -r font_file; do
                local font_basename
                font_basename=$(basename "${font_file}")
                if [[ ! -f "${win_fonts_dir}/${font_basename}" ]]; then
                    cp "${font_file}" "${win_fonts_dir}/" 2>/dev/null || true
                fi
            done
            log_info "Fonts copied to Windows. You may need to restart your terminal."
        fi
    fi

    mark_installed "fonts" "${NERD_FONTS_VERSION}"
    log_success "Fonts installed successfully"

    # Provide terminal configuration guidance
    echo ""
    log_success "Font installation complete!"
    case "${DOTFILES_OS}" in
        macos)
            echo ""
            if [[ -d "/Applications/iTerm.app" ]]; then
                log_info "iTerm2 has been automatically configured!"
                log_info "  → Restart iTerm2 for changes to take effect"
            else
                log_info "iTerm2 not found"
            fi
            echo ""
            log_info "For Terminal.app (manual configuration required):"
            log_info "  1. Terminal → Settings → Profiles → Font"
            log_info "  2. Click 'Change' and select 'MesloLGLDZ Nerd Font'"
            log_info "  3. Set size: 13pt (recommended)"
            echo ""
            log_info "Run 'dotfiles doctor fonts' to verify configuration"
            ;;
        linux)
            log_info "Configure your terminal to use MesloLGLDZ Nerd Font"
            log_info "Fonts installed to: ${HOME}/.local/share/fonts"
            ;;
    esac
    echo ""
}

install_fonts "$@"
