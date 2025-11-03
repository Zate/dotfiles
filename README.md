# Dotfiles

Modern, modular dotfiles management for Linux and macOS. Supports bash and zsh across WSL, containers, and native installs.

## Features

- 🎯 **Modular**: Install only what you need
- 🔄 **Brew-like**: Update all tools with one command
- 🏥 **Doctor command**: Health checks and diagnostics
- 🐧 **Cross-platform**: Linux (WSL, containers, native) and macOS
- 🐚 **Shell agnostic**: Bash and zsh support
- 🎨 **Beautiful prompts**: Oh-My-Posh with Nerd Fonts
- 🔒 **Safe**: Atomic operations with rollback support

## Quick Start

```bash
# Clone the repository
git clone https://github.com/Zate/dotfiles.git ~/dotfiles
cd ~/dotfiles

# First-time setup
make setup

# Install default modules (fonts, go, git, oh-my-posh)
make install

# Check installation
make doctor
```

## Available Commands

```bash
# CLI commands
dotfiles install [modules...]    # Install modules
dotfiles update [modules...]      # Update modules
dotfiles uninstall <modules...>   # Remove modules
dotfiles doctor [modules...]      # Health checks
dotfiles list                     # List available modules
dotfiles status                   # Show what's installed

# Or use Make shortcuts
make install                      # Install defaults
make update                       # Update all
make doctor                       # Health check
make list                         # List modules
make status                       # Show status
```

## Installed Modules

### Fonts
Nerd Fonts for terminal (FiraCode, JetBrainsMono, Meslo). Required for oh-my-posh.

### Go
Latest Go programming language with essential development tools:
- **gopls** - LSP server for IDE/editor support
- **dlv** - Delve debugger
- **golangci-lint** - Comprehensive linter (50+ linters)

Note: Standard Go tools (`go test`, `go vet`, `go fmt`, `go mod`, etc.) are built-in.

### Git
Git configuration with sensible defaults and aliases.

### Oh-My-Posh
Beautiful prompt theme engine with marcduiker theme.

## Examples

```bash
# Install specific modules
dotfiles install go oh-my-posh

# Update everything
dotfiles update

# Update specific module
dotfiles update go

# Check health
dotfiles doctor

# Check specific modules
dotfiles doctor go fonts

# Uninstall a module
dotfiles uninstall oh-my-posh
```

## Testing in Docker

Test dotfiles installation in an isolated environment:

```bash
# Build and run tests
make test-docker

# Open interactive shell in test container
make test-shell

# Inside container:
./bin/dotfiles-setup
./bin/dotfiles install
./bin/dotfiles doctor

# Clean up
make test-clean
```

## Directory Structure

```
dotfiles/
├── bin/
│   ├── dotfiles              # Main CLI
│   ├── dotfiles-setup        # One-time setup script
│   └── lib/                  # Core libraries
├── modules/                  # Self-contained modules
│   ├── fonts/
│   ├── go/
│   ├── git/
│   └── oh-my-posh/
├── shell/                    # Shell integration
│   ├── bash/
│   │   ├── init.sh
│   │   └── modules.d/        # Module configs loaded automatically
│   └── zsh/
│       ├── init.sh
│       └── modules.d/
├── state/                    # Installation state
├── docker/                   # Testing environment
└── Makefile                  # Convenient shortcuts
```

## Creating a New Module

Each module is self-contained in `modules/<name>/`:

```bash
modules/example/
├── module.conf        # Metadata
├── install.sh         # Installation logic
├── update.sh          # Update logic (optional)
├── check.sh           # Doctor health checks
└── uninstall.sh       # Cleanup logic
```

See existing modules for examples.

## Shell Integration

Dotfiles automatically integrates with your shell:

1. Setup adds one line to `~/.bashrc` or `~/.zshrc`
2. This sources `shell/{bash,zsh}/init.sh`
3. Init script loads all modules from `shell/{bash,zsh}/modules.d/`
4. Each installed module creates a file in `modules.d/`

## Platform Support

- ✅ Linux (Ubuntu, Debian, etc.)
- ✅ macOS (Intel and Apple Silicon)
- ✅ WSL (Windows Subsystem for Linux)
- ✅ Docker containers
- ✅ Bash and Zsh

## Requirements

Minimal requirements:
- bash or zsh
- curl or wget
- git

Platform-specific:
- Linux: apt-get or equivalent
- macOS: Homebrew (installed automatically if needed)

## Configuration

Global configuration: `config/defaults.conf`
User overrides: `config/user.conf` (gitignored)

## Troubleshooting

```bash
# Run doctor to diagnose issues
dotfiles doctor

# Enable debug mode
dotfiles --debug install

# Check what's installed
dotfiles status

# Test in Docker first
make test-docker
```

## Migrating from Old Install

The legacy `install` script is now a wrapper. On first run, it will guide you through migration:

1. Run `./install` or `make install`
2. It will explain the new system
3. Follow the prompts to migrate

Old scripts are preserved at `install.old` and `scripts/`.

## Contributing

To add a new module:

1. Create directory in `modules/<name>/`
2. Add `module.conf` with metadata
3. Create `install.sh`, `check.sh`, `uninstall.sh`
4. Test in Docker: `make test-docker`
5. Submit PR

## License

MIT

## Author

Zate (zate75@gmail.com)
