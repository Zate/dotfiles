#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../bin/lib/core.sh"
source "${SCRIPT_DIR}/../../bin/lib/doctor.sh"

check_oh_my_posh() {
    log_step "Checking oh-my-posh installation..."

    # Check oh-my-posh command
    if ! command_exists oh-my-posh; then
        # Check if installed via Homebrew but not linked (macOS)
        if [[ "${DOTFILES_OS}" == "macos" ]] && command_exists brew; then
            if brew list oh-my-posh &>/dev/null; then
                doctor_check "oh-my-posh" "fail" "oh-my-posh installed via Homebrew but not linked"
                log_info "  Fix: Run 'brew link --overwrite oh-my-posh'"
            else
                doctor_check "oh-my-posh" "fail" "oh-my-posh command not found"
            fi
        else
            doctor_check "oh-my-posh" "fail" "oh-my-posh command not found"
        fi
    else
        doctor_check "oh-my-posh" "pass" "oh-my-posh command is available"

        # Check version
        local version
        version=$(oh-my-posh version 2>/dev/null | head -1)
        doctor_check "oh-my-posh-version" "pass" "oh-my-posh version: ${version}"

        # Check theme file
        local theme_file="${HOME}/.config/oh-my-posh/marcduiker.omp.json"
        doctor_check_file "${theme_file}" "theme-file"

        # Check if binary is in PATH
        local posh_path
        posh_path=$(command -v oh-my-posh)
        doctor_check "oh-my-posh-location" "pass" "oh-my-posh binary: ${posh_path}"

        # Check fonts dependency
        if is_installed "fonts"; then
            doctor_check "fonts-dependency" "pass" "Nerd Fonts are installed"
        else
            doctor_check "fonts-dependency" "warn" "Nerd Fonts not installed (recommended)"
        fi

        # Check shell integration
        local shell_module
        shell_module=$(get_shell_modules_dir)/50-oh-my-posh.sh
        if [[ -f "${shell_module}" ]]; then
            doctor_check "shell-integration" "pass" "Shell integration configured"
        else
            doctor_check "shell-integration" "warn" "Shell integration not found"
        fi
    fi

    return 0
}

check_oh_my_posh "$@"
