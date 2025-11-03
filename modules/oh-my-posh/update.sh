#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Just run install again - it will update to latest
exec "${SCRIPT_DIR}/install.sh" "$@"
