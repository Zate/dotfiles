#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../bin/lib/core.sh"
source "${SCRIPT_DIR}/../../bin/lib/doctor.sh"

check_go() {
    log_step "Checking Go installation..."

    # Check go command
    doctor_check_command "go"

    if command_exists go; then
        # Check version
        local version
        version=$(go version 2>/dev/null | grep -oE 'go[0-9.]+' | head -1)
        doctor_check "go-version" "pass" "Go version: ${version}"

        # Check GOPATH
        doctor_check_env_var "GOPATH"

        # Check GOROOT
        doctor_check_env_var "GOROOT"

        # Check GOBIN
        doctor_check_env_var "GOBIN"

        # Check go binary location
        local go_path
        go_path=$(command -v go)
        doctor_check "go-location" "pass" "Go binary: ${go_path}"

        # Check GOPATH directories
        doctor_check_directory "${GOPATH}/bin" "GOPATH/bin"
        doctor_check_directory "${GOPATH}/src" "GOPATH/src"

        # Check common Go tools
        local tools=("gopls" "golangci-lint" "dlv")
        for tool in "${tools[@]}"; do
            if command_exists "${tool}"; then
                doctor_check "${tool}" "pass" "${tool} is installed"
            else
                doctor_check "${tool}" "warn" "${tool} not found (optional tool)"
            fi
        done
    else
        doctor_check "go" "fail" "Go is not installed"
    fi

    return 0
}

check_go "$@"
