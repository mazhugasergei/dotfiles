#!/bin/bash

set -e

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
else

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

fi # Close the FORCE_ERROR else block

# complete
if [ "$SKIP" = false ]; then
	# The Outro
	if [ "$INSTALLATION_ERROR" = true ]; then
		show_outro error
	else
		show_outro success
	fi
fi
