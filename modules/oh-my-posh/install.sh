#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../bin/lib/core.sh"

readonly OH_MY_POSH_THEME="marcduiker"

get_oh_my_posh_version() {
    if ! command_exists oh-my-posh; then
        echo ""
        return
    fi

    oh-my-posh version 2>/dev/null | head -1 || echo ""
}

install_oh_my_posh_linux() {
    log_info "Installing oh-my-posh..."

    # Create bin directory
    mkdir -p "${HOME}/bin"

    # Download install script and run it
    local install_script
    install_script=$(mktemp)
    download_file "https://ohmyposh.dev/install.sh" "${install_script}"

    chmod +x "${install_script}"
    bash "${install_script}" -d "${HOME}/bin"
    rm -f "${install_script}"

    log_success "oh-my-posh binary installed to ~/bin/oh-my-posh"
}

install_oh_my_posh_macos() {
    log_info "Installing oh-my-posh via Homebrew..."

    require_command "brew" "Install Homebrew from https://brew.sh"

    if brew list oh-my-posh &>/dev/null; then
        brew upgrade oh-my-posh || true
    else
        brew install oh-my-posh
    fi

    log_success "oh-my-posh installed via Homebrew"
}

install_theme() {
    log_info "Installing ${OH_MY_POSH_THEME} theme..."

    # Create config directory
    local config_dir="${HOME}/.config/oh-my-posh"
    mkdir -p "${config_dir}"

    # Copy theme
    cp "${SCRIPT_DIR}/themes/${OH_MY_POSH_THEME}.omp.json" "${config_dir}/${OH_MY_POSH_THEME}.omp.json"

    log_success "Theme installed to ${config_dir}/${OH_MY_POSH_THEME}.omp.json"
}

setup_shell_integration() {
    log_info "Setting up shell integration..."

    local theme_path="${HOME}/.config/oh-my-posh/${OH_MY_POSH_THEME}.omp.json"

    # Bash integration
    create_shell_module "oh-my-posh" "# Oh My Posh
if command -v oh-my-posh >/dev/null 2>&1; then
    eval \"\$(oh-my-posh init bash --config '${theme_path}')\"
fi
" "bash"

    # Zsh integration
    create_shell_module "oh-my-posh" "# Oh My Posh
if command -v oh-my-posh >/dev/null 2>&1; then
    eval \"\$(oh-my-posh init zsh --config '${theme_path}')\"
fi
" "zsh"

    log_success "Shell integration configured"
}

install_oh_my_posh() {
    log_step "Installing oh-my-posh..."

    # Check if fonts are installed (required dependency)
    if ! is_installed "fonts"; then
        log_warning "Nerd Fonts not installed. oh-my-posh requires Nerd Fonts for proper display."
        if confirm "Install fonts module first?"; then
            bash "${DOTFILES_MODULES}/fonts/install.sh"
        else
            log_warning "Continuing without fonts - some glyphs may not display correctly"
        fi
    fi

    # Install based on platform
    case "${DOTFILES_OS}" in
        linux)
            install_oh_my_posh_linux
            ;;
        macos)
            install_oh_my_posh_macos
            ;;
    esac

    # Install theme
    install_theme

    # Setup shell integration
    setup_shell_integration

    # Get version
    local version
    version=$(get_oh_my_posh_version)

    mark_installed "oh-my-posh" "${version}"
    log_success "oh-my-posh installation complete!"
    log_info "Theme: ${OH_MY_POSH_THEME}"
    log_info "Please restart your shell to see the new prompt"
}

install_oh_my_posh "$@"
