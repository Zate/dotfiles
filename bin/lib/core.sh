#!/usr/bin/env bash
#
# core.sh - Core library functions for dotfiles management
#

# Prevent multiple sourcing (check for actual function, not just variable)
# This ensures functions are available even in subprocesses
if declare -f log_info >/dev/null 2>&1; then
    return 0
fi

# Strict error handling
set -o errexit
set -o nounset
set -o pipefail

# Colors for output
if [[ -z "${RED:-}" ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly CYAN='\033[0;36m'
    readonly NC='\033[0m' # No Color
fi

# Dotfiles directories
# DOTFILES_REPO: The repository location (source for modules, scripts)
# DOTFILES_HOME: The runtime location (destination for shell modules, state)
export DOTFILES_REPO="${DOTFILES_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
export DOTFILES_HOME="${DOTFILES_HOME:-${HOME}/.dotfiles}"

# Backwards compatibility
export DOTFILES_DIR="${DOTFILES_REPO}"

# Repository paths (source)
export DOTFILES_BIN="${DOTFILES_REPO}/bin"
export DOTFILES_LIB="${DOTFILES_BIN}/lib"
export DOTFILES_MODULES="${DOTFILES_REPO}/modules"

# Runtime paths (destination)
export DOTFILES_STATE="${DOTFILES_HOME}/state"
export DOTFILES_CONFIG="${DOTFILES_HOME}/config"

# Debug mode
export DOTFILES_DEBUG="${DOTFILES_DEBUG:-false}"
export DOTFILES_VERBOSE="${DOTFILES_VERBOSE:-false}"

# Platform detection
export DOTFILES_OS=""
export DOTFILES_ARCH=""
export DOTFILES_OS_ARCH=""
export DOTFILES_SHELL=""
export DOTFILES_ENV=""  # wsl, docker, container, native

#
# Logging functions
#

log_debug() {
    [[ "${DOTFILES_DEBUG}" == "true" ]] || return 0
    echo -e "${CYAN}[DEBUG]${NC} $*" >&2
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*" >&2
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[✗]${NC} $*" >&2
}

log_step() {
    echo -e "${CYAN}==>${NC} $*" >&2
}

#
# Error handling
#

die() {
    log_error "$@"
    exit 1
}

#
# Platform detection
#

detect_os() {
    local os_name
    os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "${os_name}" in
        linux*)
            DOTFILES_OS="linux"
            ;;
        darwin*)
            DOTFILES_OS="macos"
            ;;
        *)
            die "Unsupported operating system: ${os_name}"
            ;;
    esac

    export DOTFILES_OS
    log_debug "Detected OS: ${DOTFILES_OS}"
}

detect_arch() {
    local arch_name
    arch_name=$(uname -m | tr '[:upper:]' '[:lower:]')

    case "${arch_name}" in
        x86_64*)
            DOTFILES_ARCH="amd64"
            ;;
        aarch64*|arm64*)
            DOTFILES_ARCH="arm64"
            ;;
        armv6l*)
            DOTFILES_ARCH="armv6l"
            ;;
        i386|i686)
            DOTFILES_ARCH="386"
            ;;
        *)
            die "Unsupported architecture: ${arch_name}"
            ;;
    esac

    export DOTFILES_ARCH
    DOTFILES_OS_ARCH="${DOTFILES_OS}-${DOTFILES_ARCH}"
    export DOTFILES_OS_ARCH
    log_debug "Detected architecture: ${DOTFILES_ARCH}"
}

detect_env() {
    # Detect special environments
    if [[ -f "/.dockerenv" ]]; then
        DOTFILES_ENV="docker"
    elif [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/version 2>/dev/null; then
        DOTFILES_ENV="wsl"
    elif [[ -d "/mnt/chromeos" ]]; then
        DOTFILES_ENV="chromeos"
    elif [[ -d "/dev/lxd" ]]; then
        DOTFILES_ENV="lxd"
    else
        DOTFILES_ENV="native"
    fi

    export DOTFILES_ENV
    log_debug "Detected environment: ${DOTFILES_ENV}"
}

detect_shell() {
    case "${SHELL}" in
        */bash)
            DOTFILES_SHELL="bash"
            ;;
        */zsh)
            DOTFILES_SHELL="zsh"
            ;;
        *)
            log_warning "Unknown shell: ${SHELL}, defaulting to bash"
            DOTFILES_SHELL="bash"
            ;;
    esac

    export DOTFILES_SHELL
    log_debug "Detected shell: ${DOTFILES_SHELL}"
}

init_platform() {
    detect_os
    detect_arch
    detect_env
    detect_shell
}

#
# File operations
#

backup_file() {
    local file="$1"

    [[ -e "${file}" ]] || return 0

    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    log_debug "Backing up ${file} to ${backup}"
    cp -a "${file}" "${backup}"
}

install_file() {
    local src="$1"
    local dest="$2"
    local backup="${3:-true}"

    # Backup existing file if requested
    if [[ "${backup}" == "true" ]]; then
        backup_file "${dest}"
    fi

    # Create parent directory
    mkdir -p "$(dirname "${dest}")"

    # Copy file
    log_debug "Installing ${src} to ${dest}"
    cp -f "${src}" "${dest}"
}

safe_link() {
    local src="$1"
    local dest="$2"
    local backup="${3:-true}"

    # Backup existing file if requested
    if [[ "${backup}" == "true" ]]; then
        backup_file "${dest}"
    fi

    # Remove existing symlink or file
    [[ -L "${dest}" ]] && rm -f "${dest}"
    [[ -f "${dest}" ]] && rm -f "${dest}"

    # Create parent directory
    mkdir -p "$(dirname "${dest}")"

    # Create symlink
    log_debug "Linking ${src} to ${dest}"
    ln -sf "${src}" "${dest}"
}

#
# Command checking
#

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

require_command() {
    local cmd="$1"
    local install_hint="${2:-}"

    if ! command_exists "${cmd}"; then
        log_error "Required command not found: ${cmd}"
        [[ -n "${install_hint}" ]] && log_info "  ${install_hint}"
        return 1
    fi

    return 0
}

#
# Homebrew helpers (macOS)
#

ensure_brew_installed() {
    if [[ "${DOTFILES_OS}" != "macos" ]]; then
        return 0
    fi

    if ! command_exists brew; then
        die "Homebrew is required on macOS but not found. Install from https://brew.sh"
    fi

    log_debug "Homebrew is installed"
    return 0
}

brew_ensure_linked() {
    local package="$1"

    if [[ "${DOTFILES_OS}" != "macos" ]]; then
        return 0
    fi

    # Check if package provides any binaries
    local brew_prefix
    brew_prefix=$(brew --prefix "${package}" 2>/dev/null) || return 1

    if [[ ! -d "${brew_prefix}/bin" ]]; then
        log_debug "Package ${package} has no binaries to link"
        return 0
    fi

    # Check if binaries are accessible in PATH
    local needs_linking=false
    for binary in "${brew_prefix}/bin"/*; do
        local bin_name
        bin_name=$(basename "${binary}")

        if ! command_exists "${bin_name}"; then
            needs_linking=true
            break
        fi
    done

    if [[ "${needs_linking}" == "true" ]]; then
        log_info "Linking ${package}..."
        if brew link --overwrite "${package}" >/dev/null 2>&1; then
            log_success "Successfully linked ${package}"
        else
            log_warning "Could not link ${package} automatically"
            return 1
        fi
    else
        log_debug "Package ${package} is already linked"
    fi

    return 0
}

brew_install_package() {
    local package="$1"
    local verify_command="${2:-${package}}"  # Command to verify, defaults to package name

    if [[ "${DOTFILES_OS}" != "macos" ]]; then
        log_error "brew_install_package called on non-macOS system"
        return 1
    fi

    ensure_brew_installed

    # Install or upgrade
    if brew list "${package}" &>/dev/null; then
        log_info "Upgrading ${package}..."
        brew upgrade "${package}" 2>/dev/null || log_debug "${package} already at latest version"
    else
        log_info "Installing ${package}..."
        brew install "${package}"
    fi

    # Ensure it's linked
    brew_ensure_linked "${package}"

    # Verify the command is available
    if [[ -n "${verify_command}" ]] && ! command_exists "${verify_command}"; then
        log_warning "${verify_command} command still not available after install"
        log_info "You may need to restart your shell or check your PATH"
        return 1
    fi

    log_success "${package} installed and verified"
    return 0
}

check_command() {
    local cmd="$1"

    if command_exists "${cmd}"; then
        log_success "${cmd} is available"
        return 0
    else
        log_error "${cmd} not found"
        return 1
    fi
}

check_file() {
    local file="$1"

    if [[ -f "${file}" ]]; then
        log_success "${file} exists"
        return 0
    else
        log_error "${file} not found"
        return 1
    fi
}

check_directory() {
    local dir="$1"

    if [[ -d "${dir}" ]]; then
        log_success "${dir} exists"
        return 0
    else
        log_error "${dir} not found"
        return 1
    fi
}

#
# Version comparison
#

version_gt() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

version_gte() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" == "$2"
}

#
# State management
#

ensure_state_dir() {
    mkdir -p "${DOTFILES_STATE}"
}

mark_installed() {
    local module="$1"
    local version="${2:-unknown}"

    ensure_state_dir

    # Add to installed list
    if ! grep -qx "${module}" "${DOTFILES_STATE}/.installed_modules" 2>/dev/null; then
        echo "${module}" >> "${DOTFILES_STATE}/.installed_modules"
    fi

    # Store version
    local version_file="${DOTFILES_STATE}/.module_versions"
    if [[ -f "${version_file}" ]]; then
        sed -i.bak "/^${module}=/d" "${version_file}"
    fi
    echo "${module}=${version}" >> "${version_file}"

    log_debug "Marked ${module} as installed (version: ${version})"
}

mark_uninstalled() {
    local module="$1"

    ensure_state_dir

    # Remove from installed list
    local installed_file="${DOTFILES_STATE}/.installed_modules"
    if [[ -f "${installed_file}" ]]; then
        sed -i.bak "/^${module}$/d" "${installed_file}"
    fi

    # Remove version
    local version_file="${DOTFILES_STATE}/.module_versions"
    if [[ -f "${version_file}" ]]; then
        sed -i.bak "/^${module}=/d" "${version_file}"
    fi

    log_debug "Marked ${module} as uninstalled"
}

is_installed() {
    local module="$1"

    [[ -f "${DOTFILES_STATE}/.installed_modules" ]] || return 1
    grep -qx "${module}" "${DOTFILES_STATE}/.installed_modules" 2>/dev/null
}

get_installed_version() {
    local module="$1"

    [[ -f "${DOTFILES_STATE}/.module_versions" ]] || return 1
    grep "^${module}=" "${DOTFILES_STATE}/.module_versions" 2>/dev/null | cut -d= -f2
}

get_installed_modules() {
    [[ -f "${DOTFILES_STATE}/.installed_modules" ]] || return 0
    cat "${DOTFILES_STATE}/.installed_modules"
}

#
# Shell integration
#

get_shell_config_dir() {
    local shell="${1:-${DOTFILES_SHELL}}"
    echo "${DOTFILES_HOME}/shell/${shell}"
}

get_shell_modules_dir() {
    local shell="${1:-${DOTFILES_SHELL}}"
    echo "${DOTFILES_HOME}/shell/${shell}/modules.d"
}

create_shell_module() {
    local module="$1"
    local content="$2"
    local shell="${3:-${DOTFILES_SHELL}}"

    local modules_dir
    modules_dir="$(get_shell_modules_dir "${shell}")"
    mkdir -p "${modules_dir}"

    local module_file="${modules_dir}/50-${module}.sh"
    echo "${content}" > "${module_file}"

    log_debug "Created shell module: ${module_file}"
}

remove_shell_module() {
    local module="$1"
    local shell="${2:-${DOTFILES_SHELL}}"

    local module_file
    module_file="$(get_shell_modules_dir "${shell}")/50-${module}.sh"

    if [[ -f "${module_file}" ]]; then
        rm -f "${module_file}"
        log_debug "Removed shell module: ${module_file}"
    fi
}

#
# Download helpers
#

download_file() {
    local url="$1"
    local dest="$2"

    log_debug "Downloading ${url} to ${dest}"

    if command_exists curl; then
        curl -fsSL "${url}" -o "${dest}"
    elif command_exists wget; then
        wget -q "${url}" -O "${dest}"
    else
        die "Neither curl nor wget available for downloading"
    fi
}

extract_tarball() {
    local file="$1"
    local dest="$2"

    log_debug "Extracting ${file} to ${dest}"
    mkdir -p "${dest}"
    tar -xzf "${file}" -C "${dest}"
}

#
# Confirmation prompts
#

confirm() {
    local prompt="$1"
    local default="${2:-n}"

    # Skip confirmation in non-interactive mode
    [[ -t 0 ]] || return 0

    local response
    if [[ "${default}" == "y" ]]; then
        read -rp "${prompt} [Y/n] " response
        response="${response:-y}"
    else
        read -rp "${prompt} [y/N] " response
        response="${response:-n}"
    fi

    case "${response}" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

#
# Initialization
#

# Initialize platform detection
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Being sourced
    init_platform
fi
