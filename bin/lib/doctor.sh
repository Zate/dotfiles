#!/usr/bin/env bash
#
# doctor.sh - Health check framework for dotfiles
#

source "$(dirname "${BASH_SOURCE[0]}")/core.sh"

# Doctor check results
# Use bash 4+ associative arrays if available, fallback to simple variables
if [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
    declare -A DOCTOR_RESULTS
else
    # For older bash versions (like macOS default), use a workaround
    DOCTOR_RESULTS_STORE=""
fi
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

    # Store results based on bash version
    if [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
        DOCTOR_RESULTS["${name}"]="${status}:${message}"
    else
        # Fallback for older bash - append to simple string
        DOCTOR_RESULTS_STORE="${DOCTOR_RESULTS_STORE}${name}=${status}:${message}\n"
    fi

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
    if [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
        DOCTOR_RESULTS=()
    else
        DOCTOR_RESULTS_STORE=""
    fi
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

doctor_check_file_sync() {
    local repo_file="$1"
    local runtime_file="$2"
    local name="$3"

    if [[ ! -f "${repo_file}" ]]; then
        doctor_check "${name}" "fail" "Repo file not found: ${repo_file}"
        return
    fi

    if [[ ! -f "${runtime_file}" ]]; then
        doctor_check "${name}" "fail" "Runtime file not found: ${runtime_file}"
        return
    fi

    # Compare files using diff
    if diff -q "${repo_file}" "${runtime_file}" >/dev/null 2>&1; then
        doctor_check "${name}" "pass" "${name} is up to date"
    else
        doctor_check "${name}" "fail" "${name} is outdated (differs from repo)"
        log_info "  Run: dotfiles doctor --fix"
    fi
}

fix_file_sync() {
    local repo_file="$1"
    local runtime_file="$2"
    local name="$3"

    if [[ ! -f "${repo_file}" ]]; then
        log_error "Cannot fix ${name}: repo file not found: ${repo_file}"
        return 1
    fi

    log_info "Updating ${name}..."

    # Create directory if it doesn't exist
    local runtime_dir
    runtime_dir=$(dirname "${runtime_file}")
    mkdir -p "${runtime_dir}"

    # Backup existing file if it exists
    if [[ -f "${runtime_file}" ]]; then
        local backup="${runtime_file}.backup"
        cp "${runtime_file}" "${backup}"
        log_debug "Backed up to ${backup}"
    fi

    # Copy updated file
    if cp "${repo_file}" "${runtime_file}"; then
        log_success "Updated ${name}"
        return 0
    else
        log_error "Failed to update ${name}"
        return 1
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

    # Source the check script (not bash subprocess) so counters are shared
    if source "${check_script}"; then
        doctor_summary
        return 0
    else
        doctor_summary
        return 1
    fi
}

fix_shell_setup() {
    log_step "Fixing shell setup..."

    # Detect current shell
    local shell_type
    case "${SHELL}" in
        */bash) shell_type="bash" ;;
        */zsh) shell_type="zsh" ;;
        *)
            log_error "Unknown shell: ${SHELL}"
            return 1
            ;;
    esac

    local fixed=0
    local failed=0

    # Fix init.sh if outdated
    local repo_init="${DOTFILES_REPO}/shell/${shell_type}/init.sh"
    local runtime_init="${HOME}/.dotfiles/shell/${shell_type}/init.sh"

    if [[ -f "${repo_init}" && -f "${runtime_init}" ]]; then
        if ! diff -q "${repo_init}" "${runtime_init}" >/dev/null 2>&1; then
            if fix_file_sync "${repo_init}" "${runtime_init}" "init.sh"; then
                fixed=$((fixed + 1))
            else
                failed=$((failed + 1))
            fi
        fi
    fi

    if [[ ${failed} -eq 0 ]]; then
        log_success "Fixed ${fixed} file(s)"
        return 0
    else
        log_error "Failed to fix ${failed} file(s)"
        return 1
    fi
}

check_shell_setup() {
    log_step "Checking shell setup..."
    doctor_reset

    # Detect current shell
    local shell_type
    case "${SHELL}" in
        */bash) shell_type="bash" ;;
        */zsh) shell_type="zsh" ;;
        *) shell_type="unknown" ;;
    esac

    if [[ "${shell_type}" == "unknown" ]]; then
        doctor_check "shell" "fail" "Unknown shell: ${SHELL}"
        return 1
    fi

    doctor_check "shell" "pass" "Detected shell: ${shell_type}"

    # Check shell RC file
    local shell_rc="${HOME}/.${shell_type}rc"
    if [[ ! -f "${shell_rc}" ]]; then
        doctor_check "shell-rc" "fail" "${shell_rc} not found"
        log_info "  Run: touch ${shell_rc}"
        return 1
    fi

    doctor_check "shell-rc" "pass" "${shell_rc} exists"

    # Check for dotfiles source line in RC file
    local init_line="[[ -f \"\${HOME}/.dotfiles/shell/${shell_type}/init.sh\" ]] && source \"\${HOME}/.dotfiles/shell/${shell_type}/init.sh\""
    if grep -Fq "${init_line}" "${shell_rc}" 2>/dev/null; then
        doctor_check "shell-integration" "pass" "Dotfiles integration configured in ${shell_rc}"
    else
        doctor_check "shell-integration" "fail" "Dotfiles integration not found in ${shell_rc}"
        log_info "  Run: ./bin/dotfiles-setup"
    fi

    # Check ~/.dotfiles directory structure
    if [[ -d "${HOME}/.dotfiles" ]]; then
        doctor_check "dotfiles-dir" "pass" "~/.dotfiles directory exists"
    else
        doctor_check "dotfiles-dir" "fail" "~/.dotfiles directory not found"
        log_info "  Run: ./bin/dotfiles-setup"
        return 1
    fi

    # Check init.sh exists
    local init_file="${HOME}/.dotfiles/shell/${shell_type}/init.sh"
    if [[ -f "${init_file}" ]]; then
        doctor_check "init-file" "pass" "init.sh exists at ~/.dotfiles/shell/${shell_type}/"
    else
        doctor_check "init-file" "fail" "init.sh not found at ~/.dotfiles/shell/${shell_type}/"
        log_info "  Run: ./bin/dotfiles-setup"
    fi

    # Check if init.sh is in sync with repo version
    local repo_init="${DOTFILES_REPO}/shell/${shell_type}/init.sh"
    if [[ -f "${init_file}" && -f "${repo_init}" ]]; then
        doctor_check_file_sync "${repo_init}" "${init_file}" "init.sh-sync"
    fi

    # Check modules.d directory
    local modules_dir="${HOME}/.dotfiles/shell/${shell_type}/modules.d"
    if [[ -d "${modules_dir}" ]]; then
        local module_count
        module_count=$(find "${modules_dir}" -name "*.sh" 2>/dev/null | wc -l)
        doctor_check "modules-dir" "pass" "modules.d directory exists (${module_count} module(s))"
    else
        doctor_check "modules-dir" "fail" "modules.d directory not found"
        log_info "  Run: ./bin/dotfiles-setup"
    fi

    # Check for user customization directory
    local custom_dir="${HOME}/.local/.dotfiles.d"
    if [[ -d "${custom_dir}" ]]; then
        local custom_count
        custom_count=$(find "${custom_dir}" -name "*.sh" 2>/dev/null | wc -l)
        doctor_check "custom-dir" "pass" "Custom directory exists (${custom_count} file(s))"
    else
        doctor_check "custom-dir" "warn" "No custom directory (${custom_dir})"
        log_info "  Create ${custom_dir}/ and add *.sh files for user-specific customizations"
    fi

    # Backwards compatibility check
    local custom_file="${HOME}/.${shell_type}_local"
    if [[ -f "${custom_file}" ]]; then
        doctor_check "legacy-custom-file" "warn" "Legacy custom file exists: ${custom_file}"
        log_info "  Consider migrating to ${custom_dir}/ for better organization"
    fi

    doctor_summary
    return $?
}

run_all_checks() {
    local modules=("$@")

    # Always check shell setup first
    if ! check_shell_setup; then
        log_error "Shell setup check failed"
        echo ""
    fi

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
