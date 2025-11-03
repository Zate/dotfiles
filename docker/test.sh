#!/usr/bin/env bash
#
# test.sh - Run dotfiles installation tests in Docker
#

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "${SCRIPT_DIR}")"

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[✓]${NC} $*"; }
log_error() { echo -e "${RED}[✗]${NC} $*"; }

usage() {
    cat <<EOF
Usage: $0 [options] [command]

Options:
    -d, --distro DISTRO    Distribution to test (ubuntu, debian, all) [default: ubuntu]
    -b, --build            Force rebuild of Docker images
    -h, --help             Show this help

Commands:
    build       Build Docker images
    shell       Open interactive shell in container
    install     Run full installation test
    doctor      Run doctor checks
    clean       Remove containers and images

Examples:
    $0 shell                    # Open shell in Ubuntu container
    $0 --distro debian shell    # Open shell in Debian container
    $0 install                  # Run installation test
    $0 doctor                   # Run doctor checks after install

EOF
}

build_images() {
    local distro="$1"

    log_info "Building Docker images for ${distro}..."

    case "${distro}" in
        ubuntu)
            docker-compose -f "${SCRIPT_DIR}/docker-compose.yml" build ubuntu
            ;;
        debian)
            docker-compose -f "${SCRIPT_DIR}/docker-compose.yml" build debian
            ;;
        all)
            docker-compose -f "${SCRIPT_DIR}/docker-compose.yml" build
            ;;
        *)
            log_error "Unknown distro: ${distro}"
            exit 1
            ;;
    esac

    log_success "Build complete"
}

run_shell() {
    local distro="$1"

    log_info "Opening shell in ${distro} container..."

    docker-compose -f "${SCRIPT_DIR}/docker-compose.yml" run --rm "${distro}" /bin/bash
}

run_install_test() {
    local distro="$1"

    log_info "Running installation test in ${distro} container..."

    docker-compose -f "${SCRIPT_DIR}/docker-compose.yml" run --rm "${distro}" /bin/bash -c "
        set -e
        echo '==> Running dotfiles setup...'
        ./bin/dotfiles-setup <<< y

        echo ''
        echo '==> Installing default modules...'
        ./bin/dotfiles install

        echo ''
        echo '==> Running doctor checks...'
        ./bin/dotfiles doctor

        echo ''
        echo '==> Installation status...'
        ./bin/dotfiles status
    "

    if [[ $? -eq 0 ]]; then
        log_success "Installation test passed for ${distro}"
    else
        log_error "Installation test failed for ${distro}"
        return 1
    fi
}

run_doctor_test() {
    local distro="$1"

    log_info "Running doctor checks in ${distro} container..."

    docker-compose -f "${SCRIPT_DIR}/docker-compose.yml" run --rm "${distro}" /bin/bash -c "
        ./bin/dotfiles doctor
    "
}

clean_docker() {
    log_info "Cleaning up Docker containers and images..."

    docker-compose -f "${SCRIPT_DIR}/docker-compose.yml" down --rmi all --volumes
    log_success "Cleanup complete"
}

main() {
    local distro="ubuntu"
    local force_build=false
    local command="shell"

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--distro)
                distro="$2"
                shift 2
                ;;
            -b|--build)
                force_build=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            build|shell|install|doctor|clean)
                command="$1"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Change to docker directory for docker-compose
    cd "${SCRIPT_DIR}"

    # Execute command
    case "${command}" in
        build)
            build_images "${distro}"
            ;;
        shell)
            [[ "${force_build}" == "true" ]] && build_images "${distro}"
            run_shell "${distro}"
            ;;
        install)
            [[ "${force_build}" == "true" ]] && build_images "${distro}"
            run_install_test "${distro}"
            ;;
        doctor)
            run_doctor_test "${distro}"
            ;;
        clean)
            clean_docker
            ;;
        *)
            log_error "Unknown command: ${command}"
            usage
            exit 1
            ;;
    esac
}

main "$@"
