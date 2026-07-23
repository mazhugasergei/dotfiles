#!/bin/bash

set -e

clear

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS_DIR="$SCRIPT_DIR/_/zsh/utils"
source "$UTILS_DIR/cursor.sh"
source "$UTILS_DIR/logger.sh"
source "$UTILS_DIR/packages.sh"
source "$UTILS_DIR/config.sh"
source "$UTILS_DIR/sudo.sh"

# Check for sudo privileges
if ! check_sudo_privileges; then
	exit 1
fi
	
# Package installation
if ! manage_packages; then
	INSTALLATION_ERROR=true
fi

# System setup
if ! run_stow; then
	INSTALLATION_ERROR=true
fi

if ! set_zsh_default; then
	INSTALLATION_ERROR=true
fi

remove_bash_files

# Source zshrc to apply changes immediately
if [ -f "$HOME/.zshrc" ]; then
	logger info "applying shell configuration..."
	source "$HOME/.zshrc"
	clear_previous_line
	logger done "shell configuration applied"
fi
