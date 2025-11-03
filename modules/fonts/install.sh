#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../bin/lib/core.sh"

readonly NERD_FONTS_VERSION="v3.1.1"
readonly FONTS_TO_INSTALL=(
    "FiraCode"
    "JetBrainsMono"
    "Meslo"
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

install_font_macos() {
    local font_name="$1"
    local fonts_dir="${HOME}/Library/Fonts"

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

install_fonts() {
    log_step "Installing Nerd Fonts..."

    # Check dependencies
    require_command "unzip" "Install unzip: apt-get install unzip (Linux) or brew install unzip (macOS)"

    for font in "${FONTS_TO_INSTALL[@]}"; do
        case "${DOTFILES_OS}" in
            linux)
                install_font_linux "${font}"
                ;;
            macos)
                install_font_macos "${font}"
                ;;
        esac
    done

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
}

install_fonts "$@"
