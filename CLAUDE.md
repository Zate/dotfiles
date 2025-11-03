# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a modern, modular dotfiles repository that provides cross-platform shell environment configuration and development tool installation. It supports Linux (WSL, container, native) and macOS, with bash and zsh support.

## Architecture

### Core Components

**bin/dotfiles** - Main CLI entry point
- Command routing (install, update, uninstall, doctor, list, status)
- Argument parsing and validation
- User-facing interface

**bin/lib/core.sh** - Core library functions
- Platform detection (OS, architecture, environment)
- Logging functions (log_info, log_success, log_error, etc.)
- File operations (install_file, safe_link, backup_file)
- State management (mark_installed, is_installed, get_installed_version)
- Shell integration helpers (create_shell_module, remove_shell_module)
- Download and extraction helpers

**bin/lib/module.sh** - Module management
- Module discovery and validation
- Install/update/uninstall operations
- Batch operations for multiple modules
- Dependency checking

**bin/lib/doctor.sh** - Health check framework
- Check result tracking
- Common health check functions (doctor_check_command, doctor_check_file, etc.)
- Module check runner
- Summary reporting

### Module System

Each module is self-contained in `modules/<name>/`:

```
modules/example/
├── module.conf        # Metadata (name, version, dependencies, platforms)
├── install.sh         # Installation logic
├── update.sh          # Update logic (optional, defaults to reinstall)
├── check.sh           # Doctor health checks
└── uninstall.sh       # Cleanup logic
```

**module.conf Format:**
```bash
NAME="example"
DESCRIPTION="Example tool"
VERSION="auto"  # or specific version
DEPENDENCIES=()  # e.g., ("fonts")
PLATFORMS="linux macos"
SHELLS="bash zsh"
```

**Installation Script Pattern:**
```bash
#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../bin/lib/core.sh"

install_example() {
    log_step "Installing ${NAME}..."

    # Platform-specific installation
    case "${DOTFILES_OS}" in
        linux)
            install_example_linux
            ;;
        macos)
            install_example_macos
            ;;
    esac

    # Shell integration if needed
    create_shell_module "example" "export EXAMPLE_HOME=..."

    mark_installed "example" "${version}"
    log_success "${NAME} installed successfully"
}

install_example "$@"
```

### Shell Integration

**shell/{bash,zsh}/init.sh** - Shell initialization
- Sources all module files from modules.d/
- Loads user customizations

**shell/{bash,zsh}/modules.d/** - Module configurations
- Named with numeric prefixes for load order (00-path.sh, 20-aliases.sh, 50-modulename.sh)
- Automatically loaded by init.sh
- Created/removed by modules during install/uninstall

### State Management

**state/.installed_modules** - List of installed modules (one per line)
**state/.module_versions** - Module versions (format: `module=version`)

### Environment Detection

The system detects:
- **OS**: linux, macos
- **Architecture**: amd64, arm64, armv6l, 386
- **Environment**: wsl, docker, chromeos, lxd, native
- **Shell**: bash, zsh

## Development Commands

### Building and Testing

```bash
# Local testing
make setup                   # First-time setup
make install                 # Install default modules
make update                  # Update all modules
make doctor                  # Health check
make list                    # List available modules
make status                  # Show installation status

# Docker testing (isolated, safe)
make test-docker             # Full install test in container
make test-shell              # Interactive shell in container
make test-build              # Build Docker images
make test-clean              # Clean up Docker artifacts

# Direct CLI usage
./bin/dotfiles install go oh-my-posh
./bin/dotfiles update
./bin/dotfiles doctor
./bin/dotfiles --debug install  # Debug mode
```

### Adding a New Module

1. **Create module directory**: `mkdir -p modules/newmodule`

2. **Create module.conf**:
```bash
NAME="newmodule"
DESCRIPTION="Description of the module"
VERSION="auto"
DEPENDENCIES=()
PLATFORMS="linux macos"
SHELLS="bash zsh"
```

3. **Create install.sh**:
   - Source core.sh for helper functions
   - Detect platform and install appropriately
   - Create shell integration if needed
   - Call `mark_installed "newmodule" "${version}"`

4. **Create check.sh**:
   - Source core.sh and doctor.sh
   - Use `doctor_check_command`, `doctor_check_file`, etc.
   - Return 0 on success

5. **Create uninstall.sh**:
   - Remove installed files
   - Remove shell integration
   - Call `mark_uninstalled "newmodule"`

6. **Test in Docker**: `make test-docker`

## Current Modules

### fonts
- Installs Nerd Fonts (FiraCode, JetBrainsMono, Meslo)
- Platform-specific installation to font directories
- WSL support: copies to Windows fonts directory
- Refreshes font cache on Linux

### go
- Fetches latest Go version from go.dev
- Linux: Downloads and extracts to /usr/local/go
- macOS: Installs via Homebrew
- Creates GOPATH structure (~/go/{bin,pkg,src})
- Creates project symlinks (~/projects/github → $GOPATH/src/github.com/Zate)
- Installs 3 essential Go tools:
  - gopls (LSP server for IDE support)
  - dlv (Delve debugger)
  - golangci-lint (comprehensive linter - 50+ linters)
- Sets up shell environment (GOPATH, GOROOT, GOBIN, PATH)
- Note: Standard tools (go test, go vet, go fmt, go mod) are built into Go

### git
- Installs .gitconfig with user info (Zate/zate75@gmail.com)
- Installs .gitignore_global
- Configures default branch, aliases, color output

### oh-my-posh
- Dependency: fonts
- Linux: Downloads from ohmyposh.dev to ~/bin
- macOS: Installs via Homebrew
- Installs marcduiker theme to ~/.config/oh-my-posh/
- Sets up shell integration for both bash and zsh

## Important Notes

### Platform-Specific Paths

**Go Installation:**
- Linux: /usr/local/go
- macOS: $(brew --prefix go)/libexec

**Fonts:**
- Linux: ~/.local/share/fonts
- macOS: ~/Library/Fonts
- WSL: Also copies to /mnt/c/Windows/Fonts

**oh-my-posh:**
- Linux: ~/bin/oh-my-posh
- macOS: Homebrew managed

### Error Handling

- All scripts use `set -e` for strict error handling
- core.sh uses `set -o errexit -o nounset -o pipefail`
- Atomic operations where possible
- Backup files before modification

### Shell RC Integration

The setup script adds ONE line to ~/.bashrc or ~/.zshrc:
```bash
[[ -f "${HOME}/.dotfiles/shell/bash/init.sh" ]] && source "${HOME}/.dotfiles/shell/bash/init.sh"
```

This init.sh then loads all modules from modules.d/, making the system modular and clean.

### Docker Testing Environment

- **Dockerfile**: Ubuntu 22.04 base
- **Dockerfile.debian**: Debian bullseye base
- **docker-compose.yml**: Orchestration for both distros
- **test.sh**: Test runner script

Test containers have:
- testuser with sudo access
- Dotfiles volume mounted
- All prerequisites installed

## Common Patterns

### Checking Command Existence
```bash
require_command "curl" "Install curl first"  # Dies if missing
command_exists "curl"  # Returns 0/1, doesn't die
```

### Platform-Specific Logic
```bash
case "${DOTFILES_OS}" in
    linux)
        # Linux-specific
        ;;
    macos)
        # macOS-specific
        ;;
esac
```

### Creating Shell Integration
```bash
create_shell_module "modulename" "
export VAR=\"value\"
export PATH=\"\${HOME}/bin:\${PATH}\"
" "bash"  # or "zsh", or omit for current shell
```

### Doctor Checks
```bash
doctor_check_command "binary"
doctor_check_file "${HOME}/.config/file"
doctor_check_env_var "GOPATH"
```

## Testing Guidelines

1. **Always test in Docker first**: `make test-docker`
2. **Test both distros** if making platform-specific changes
3. **Run doctor after install**: Validates installation
4. **Test uninstall**: Ensure clean removal
5. **Test update**: Should handle reinstalls gracefully

## Git Practices

- Never commit as Claude Code
- The user is: Zate <zate75@gmail.com>
- Always commit as the user
- state/ directory is gitignored (installation state is local)
- TEMP-*.md files are for planning, not committed

## Tips

- Use `log_debug` for verbose output (only shows with --debug)
- Use `log_info` for progress messages
- Use `log_success` for completion messages
- Use `log_warning` for non-fatal issues
- Use `die` to exit with error message
- Test changes in Docker to avoid breaking the host system
