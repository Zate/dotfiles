#!/usr/bin/env bash
#
# doctor.sh - Health check framework for dotfiles
#

source "$(dirname "${BASH_SOURCE[0]}")/core.sh"

# Doctor check results
declare -A DOCTOR_RESULTS
DOCTOR_PASSED=0
DOCTOR_WARNED=0
DOCTOR_FAILED=0

#
# Doctor check functions
#

doctor_check() {
    local name="$1"
    local status="$2"  # pass, warn, fail
    local message="$3"

    DOCTOR_RESULTS["${name}"]="${status}:${message}"

    case "${status}" in
        pass)
            DOCTOR_PASSED=$((DOCTOR_PASSED + 1))
            log_success "${message}"
            ;;
        warn)
            DOCTOR_WARNED=$((DOCTOR_WARNED + 1))
            log_warning "${message}"
            ;;
        fail)
            DOCTOR_FAILED=$((DOCTOR_FAILED + 1))
            log_error "${message}"
            ;;
    esac
}

doctor_reset() {
    DOCTOR_RESULTS=()
    DOCTOR_PASSED=0
    DOCTOR_WARNED=0
    DOCTOR_FAILED=0
}

doctor_summary() {
    echo ""
    log_step "Doctor Summary"
    echo "  ✓ Passed: ${DOCTOR_PASSED}"
    echo "  ⚠ Warnings: ${DOCTOR_WARNED}"
    echo "  ✗ Failed: ${DOCTOR_FAILED}"
    echo ""

    if [[ ${DOCTOR_FAILED} -eq 0 && ${DOCTOR_WARNED} -eq 0 ]]; then
        log_success "All checks passed!"
        return 0
    elif [[ ${DOCTOR_FAILED} -eq 0 ]]; then
        log_warning "Some checks have warnings"
        return 0
    else
        log_error "Some checks failed"
        return 1
    fi
}

#
# Common health checks
#

doctor_check_command() {
    local cmd="$1"
    local name="${2:-${cmd}}"

    if command_exists "${cmd}"; then
        doctor_check "${name}" "pass" "${name} command is available"
    else
        doctor_check "${name}" "fail" "${name} command not found"
    fi
}

doctor_check_file() {
    local file="$1"
    local name="${2:-$(basename "${file}")}"

    if [[ -f "${file}" ]]; then
        doctor_check "${name}" "pass" "${name} exists"
    else
        doctor_check "${name}" "fail" "${name} not found"
    fi
}

doctor_check_directory() {
    local dir="$1"
    local name="${2:-$(basename "${dir}")}"

    if [[ -d "${dir}" ]]; then
        doctor_check "${name}" "pass" "${name} directory exists"
    else
        doctor_check "${name}" "fail" "${name} directory not found"
    fi
}

doctor_check_in_path() {
    local cmd="$1"
    local expected_path="$2"
    local name="${3:-${cmd}}"

    if ! command_exists "${cmd}"; then
        doctor_check "${name}" "fail" "${name} not found in PATH"
        return
    fi

    local actual_path
    actual_path=$(command -v "${cmd}")

    if [[ "${actual_path}" == "${expected_path}"* ]]; then
        doctor_check "${name}" "pass" "${name} found at ${actual_path}"
    else
        doctor_check "${name}" "warn" "${name} found at ${actual_path} (expected ${expected_path})"
    fi
}

doctor_check_version() {
    local cmd="$1"
    local expected_version="$2"
    local version_flag="${3:---version}"
    local name="${4:-${cmd}}"

    if ! command_exists "${cmd}"; then
        doctor_check "${name}" "fail" "${name} not installed"
        return
    fi

    local actual_version
    actual_version=$(${cmd} ${version_flag} 2>&1 | head -1)

    if [[ "${actual_version}" == *"${expected_version}"* ]]; then
        doctor_check "${name}" "pass" "${name} version ${expected_version} installed"
    else
        doctor_check "${name}" "warn" "${name} version mismatch: got ${actual_version}"
    fi
}

doctor_check_env_var() {
    local var_name="$1"
    local expected_value="${2:-}"
    local name="${3:-${var_name}}"

    if [[ -z "${!var_name:-}" ]]; then
        doctor_check "${name}" "fail" "${name} environment variable not set"
        return
    fi

    if [[ -z "${expected_value}" ]]; then
        doctor_check "${name}" "pass" "${name} is set to: ${!var_name}"
    elif [[ "${!var_name}" == "${expected_value}" ]]; then
        doctor_check "${name}" "pass" "${name} is set correctly"
    else
        doctor_check "${name}" "warn" "${name} is set to '${!var_name}' (expected '${expected_value}')"
    fi
}

#
# Module health check runner
#

run_module_check() {
    local module="$1"
    local check_script="${DOTFILES_MODULES}/${module}/check.sh"

    if [[ ! -f "${check_script}" ]]; then
        log_warning "No health check available for ${module}"
        return 0
    fi

    log_step "Checking ${module}..."
    doctor_reset

    # Source and run the check script
    if bash "${check_script}"; then
        doctor_summary
        return 0
    else
        doctor_summary
        return 1
    fi
}

run_all_checks() {
    local modules=("$@")

    if [[ ${#modules[@]} -eq 0 ]]; then
        # Check all installed modules
        mapfile -t modules < <(get_installed_modules)
    fi

    local total_failed=0
    for module in "${modules[@]}"; do
        if ! run_module_check "${module}"; then
            total_failed=$((total_failed + 1))
        fi
        echo ""
    done

    if [[ ${total_failed} -eq 0 ]]; then
        log_success "All module checks passed!"
        return 0
    else
        log_error "${total_failed} module(s) failed health checks"
        return 1
    fi
}
