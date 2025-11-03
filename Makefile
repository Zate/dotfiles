.PHONY: help install update uninstall doctor list status clean setup test-docker test-shell test-build test-clean

help: ## Display this help message
	@echo "Usage:"
	@echo "  make <target>"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

setup: ## Setup dotfiles (symlink to ~/.dotfiles and configure shell)
	@./bin/dotfiles-setup

install: ## Install default modules (fonts, go, git, oh-my-posh)
	@./bin/dotfiles install

update: ## Update all installed modules
	@./bin/dotfiles update

uninstall: ## Uninstall a module (usage: make uninstall MODULE=go)
	@./bin/dotfiles uninstall $(MODULE)

doctor: ## Run health checks on installed modules
	@./bin/dotfiles doctor

list: ## List available modules
	@./bin/dotfiles list

status: ## Show installation status
	@./bin/dotfiles status

clean: ## Legacy: Remove installed files (use 'make uninstall' instead)
	@echo "Use 'bin/dotfiles uninstall <module>' to uninstall specific modules"
	@echo "Or 'bin/dotfiles status' to see what's installed"

# Docker testing targets
test-build: ## Build Docker test images
	@./docker/test.sh --build build

test-shell: ## Open interactive shell in Docker test container
	@./docker/test.sh shell

test-docker: ## Run full installation test in Docker
	@./docker/test.sh --build install

test-clean: ## Clean up Docker test containers and images
	@./docker/test.sh clean