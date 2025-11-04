#!/usr/bin/env zsh
#
# Dotfiles zsh initialization
# Source this from ~/.zshrc
#

# Dotfiles directory
export DOTFILES_DIR="${DOTFILES_DIR:-${HOME}/.dotfiles}"

# Load all module files in numerical order
if [[ -d "${DOTFILES_DIR}/shell/zsh/modules.d" ]]; then
    for module in "${DOTFILES_DIR}/shell/zsh/modules.d"/*.sh; do
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
[[ -f "${HOME}/.zsh_local" ]] && source "${HOME}/.zsh_local"
