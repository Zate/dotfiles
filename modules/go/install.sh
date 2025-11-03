#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../bin/lib/core.sh"

# Essential Go development tools
# Note: go test, go vet, go fmt, go mod, etc. are built into Go
readonly GO_TOOLS=(
    "golang.org/x/tools/gopls@latest"                           # LSP server for IDE/editor support
    "github.com/go-delve/delve/cmd/dlv@latest"                  # Debugger
    "github.com/golangci/golangci-lint/cmd/golangci-lint@latest" # Comprehensive linter (runs 50+ linters)
)

get_latest_go_version() {
    log_debug "Fetching latest Go version..."
    curl -fsSL https://go.dev/VERSION?m=text | head -1
}

get_installed_go_version() {
    if ! command_exists go; then
        echo ""
        return
    fi

    go version 2>/dev/null | grep -oE 'go[0-9.]+' | head -1
}

install_go_linux() {
    local version="$1"
    local download_url="https://go.dev/dl/${version}.${DOTFILES_OS}-${DOTFILES_ARCH}.tar.gz"

    log_info "Downloading Go ${version}..."

    # Check dependencies
    require_command "curl" "Install curl: apt-get install curl"

    # Remove old installation
    if [[ -d "/usr/local/go" ]]; then
        log_info "Removing old Go installation..."
        sudo rm -rf /usr/local/go
    fi

    # Download and extract
    local temp_file
    temp_file=$(mktemp)
    download_file "${download_url}" "${temp_file}"

    log_info "Installing Go to /usr/local/go..."
    sudo tar -C /usr/local -xzf "${temp_file}"
    rm -f "${temp_file}"

    log_success "Go ${version} installed"
}

install_go_macos() {
    local version="$1"

    log_info "Installing Go via Homebrew..."

    # Check if brew is available
    require_command "brew" "Install Homebrew from https://brew.sh"

    # Install or upgrade go
    if brew list go &>/dev/null; then
        brew upgrade go || true
    else
        brew install go
    fi

    local installed_version
    installed_version=$(get_installed_go_version)

    log_success "Go ${installed_version} installed"
}

setup_go_environment() {
    log_info "Setting up Go environment..."

    # Create GOPATH directory
    local gopath="${HOME}/go"
    mkdir -p "${gopath}"/{bin,pkg,src}

    # Create projects structure
    mkdir -p "${HOME}/projects/github"
    mkdir -p "${gopath}/src/github.com"

    # Create symlinks for convenience
    if [[ ! -L "${gopath}/src/github.com/Zate" ]]; then
        ln -sf "${HOME}/projects/github" "${gopath}/src/github.com/Zate"
    fi
    if [[ ! -L "${gopath}/src/github.com/zate" ]]; then
        ln -sf "${HOME}/projects/github" "${gopath}/src/github.com/zate"
    fi

    log_debug "Go directories created"
}

setup_go_shell_integration() {
    log_info "Setting up shell integration..."

    # Determine GOROOT based on platform
    local goroot
    if [[ "${DOTFILES_OS}" == "macos" ]] && command_exists brew; then
        goroot="$(brew --prefix go)/libexec"
    else
        goroot="/usr/local/go"
    fi

    # Create shell module for both bash and zsh
    for shell in bash zsh; do
        create_shell_module "go" "# Go environment
export GOPATH=\"\${HOME}/go\"
export GOROOT=\"${goroot}\"
export GOBIN=\"\${GOPATH}/bin\"
export PATH=\"\${GOBIN}:\${GOROOT}/bin:\${PATH}\"
" "${shell}"
    done

    log_success "Shell integration configured"
}

install_go_tools() {
    log_info "Installing Go development tools..."

    # Ensure GOPATH is set
    export GOPATH="${HOME}/go"
    export GOBIN="${GOPATH}/bin"
    export PATH="${GOBIN}:/usr/local/go/bin:${PATH}"

    local failed=0
    for tool in "${GO_TOOLS[@]}"; do
        local tool_name
        tool_name=$(echo "${tool}" | sed 's|.*/||' | sed 's|@.*||')

        log_info "Installing ${tool_name}..."

        # Capture output and check actual exit code
        local output
        if output=$(go install "${tool}" 2>&1); then
            # Success - tool installed
            log_debug "${tool_name} installed"
            # Show non-download output if any (errors, warnings)
            echo "$output" | grep -v "^go: downloading" | grep -v "^go: finding" | grep . || true
        else
            # Actual failure
            log_error "Failed to install ${tool_name}"
            echo "$output" | head -10  # Show error details
            failed=$((failed + 1))
        fi
    done

    if [[ ${failed} -gt 0 ]]; then
        log_warning "${failed} Go tool(s) failed to install"
    else
        log_success "All Go tools installed"
    fi
}

install_go() {
    log_step "Installing Go..."

    # Get latest version
    local latest_version
    latest_version=$(get_latest_go_version)

    if [[ -z "${latest_version}" ]]; then
        die "Could not determine latest Go version"
    fi

    log_info "Latest Go version: ${latest_version}"

    # Check if already installed
    local installed_version
    installed_version=$(get_installed_go_version)

    if [[ -n "${installed_version}" ]]; then
        log_info "Current installed version: ${installed_version}"

        if [[ "${installed_version}" == "${latest_version}" ]]; then
            log_info "Go is already up to date"
        else
            log_info "Updating Go from ${installed_version} to ${latest_version}"
        fi
    fi

    # Install based on platform
    case "${DOTFILES_OS}" in
        linux)
            install_go_linux "${latest_version}"
            ;;
        macos)
            install_go_macos "${latest_version}"
            ;;
    esac

    # Setup environment
    setup_go_environment
    setup_go_shell_integration

    # Install Go tools
    install_go_tools

    # Get the actually installed version
    local final_version
    final_version=$(get_installed_go_version)

    mark_installed "go" "${final_version}"
    log_success "Go installation complete!"
    log_info "Please restart your shell or run: source ~/.${DOTFILES_SHELL}rc"
}

install_go "$@"
