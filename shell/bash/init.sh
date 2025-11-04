#!/usr/bin/env bash
#
# Dotfiles bash initialization
# Source this from ~/.bashrc
#

# Dotfiles directory
export DOTFILES_DIR="${DOTFILES_DIR:-${HOME}/.dotfiles}"

# Load all module files in numerical order
if [[ -d "${DOTFILES_DIR}/shell/bash/modules.d" ]]; then
    for module in "${DOTFILES_DIR}/shell/bash/modules.d"/*.sh; do
        [[ -f "${module}" ]] && source "${module}"
    done
fi

# Load user customizations from ~/.local/.dotfiles.d/
if [[ -d "${HOME}/.local/.dotfiles.d" ]]; then
    for custom in "${HOME}/.local/.dotfiles.d"/*.sh; do
        [[ -f "${custom}" ]] && source "${custom}"
    done
fi

# Backwards compatibility: load single custom file if it exists
[[ -f "${HOME}/.bash_local" ]] && source "${HOME}/.bash_local"
