#!/bin/bash

set -e

clear

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS_DIR="$SCRIPT_DIR/_/zsh/utils"
source "$UTILS_DIR/logger.sh"
source "$UTILS_DIR/sudo.sh"
source "$UTILS_DIR/args.sh"
source "$UTILS_DIR/intro.sh"
source "$UTILS_DIR/packages.sh"
source "$UTILS_DIR/setup.sh"

# Parse command line arguments
parse_arguments "$@"

# Check for sudo privileges
if ! check_sudo_privileges; then
	exit 1
fi

# The Intro Reveal
if [ "$SKIP_INTRO" = false ] && [ "$SKIP" = false ]; then
	show_intro
fi

# Force error condition for testing
if [ "$FORCE_ERROR" = true ]; then
	logger error "Good heavens! An unknown error occurred during installation"
	INSTALLATION_ERROR=true

	# The Outro
	if [ "$SKIP" = false ]; then
		if [ "$INSTALLATION_ERROR" = true ]; then
			show_outro error
		else
			show_outro success
		fi
	fi

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

setup_fastfetch

# Source zshrc to apply changes immediately
if [ -f "$HOME/.zshrc" ]; then
	logger info "applying shell configuration..."
	source "$HOME/.zshrc"
	clear_previous_line
	logger done "shell configuration applied"
fi