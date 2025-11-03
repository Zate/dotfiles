#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../bin/lib/core.sh"
source "${SCRIPT_DIR}/../../bin/lib/doctor.sh"

check_git() {
    log_step "Checking Git configuration..."

    # Check git command
    doctor_check_command "git"

    if command_exists git; then
        # Check version
        local version
        version=$(git --version 2>/dev/null | grep -oE '[0-9.]+' | head -1)
        doctor_check "git-version" "pass" "Git version: ${version}"

        # Check user config
        local user_name
        user_name=$(git config --global user.name 2>/dev/null || echo "")
        if [[ -n "${user_name}" ]]; then
            doctor_check "git-user-name" "pass" "User name: ${user_name}"
        else
            doctor_check "git-user-name" "warn" "User name not configured"
        fi

        local user_email
        user_email=$(git config --global user.email 2>/dev/null || echo "")
        if [[ -n "${user_email}" ]]; then
            doctor_check "git-user-email" "pass" "User email: ${user_email}"
        else
            doctor_check "git-user-email" "warn" "User email not configured"
        fi

        # Check config files
        doctor_check_file "${HOME}/.gitconfig" "gitconfig"
        doctor_check_file "${HOME}/.gitignore_global" "gitignore_global"

        # Check default branch
        local default_branch
        default_branch=$(git config --global init.defaultBranch 2>/dev/null || echo "")
        if [[ -n "${default_branch}" ]]; then
            doctor_check "git-default-branch" "pass" "Default branch: ${default_branch}"
        else
            doctor_check "git-default-branch" "warn" "Default branch not configured"
        fi
    fi

    return 0
}

check_git "$@"
