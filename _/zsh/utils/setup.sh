#!/bin/bash

# System Setup Utilities
# Provides functions for stow configuration and shell setup

# Run stow to configure dotfiles
# Usage: run_stow
# Returns: 0 on success, 1 on failure
run_stow() {
	local original_dir=$(pwd)
	cd "$(dirname "${BASH_SOURCE[1]}")"  # Use the calling script's directory
	
	# Show initial log
	logger info "running stow..."
	
	# Move cursor up one line and clear it to overwrite the previous message
	echo -ne "\033[1A\033[K"
	
	if stow zsh git; then
		logger done "stow completed successfully"
	else
		logger error "stow failed"
		cd "$original_dir"
		return 1
	fi
	
	cd "$original_dir"
	return 0
}

# Set zsh as the default shell
# Usage: set_zsh_default
# Returns: 0 on success, 1 on failure
set_zsh_default() {
	if [ "$SHELL" != "$(which zsh)" ]; then
		logger info "setting zsh as default shell..."
		if ! sudo chsh -s $(which zsh) $USER; then
			return 1
		fi
		logger done "zsh set as default shell"
	else
		logger done "zsh is already the default shell"
	fi
	return 0
}

# Remove bash configuration files
# Usage: remove_bash_files
# Returns: 0 always (just reports what was done)
remove_bash_files() {
	local bash_files=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.bash_logout" "$HOME/.bash_history")
	local files_removed=false

	for file in "${bash_files[@]}"; do
		if [ -f "$file" ]; then
			rm -f "$file"
			files_removed=true
		fi
	done

	if [ "$files_removed" = true ]; then
		logger done "bash files removed"
	else
		logger done "no bash files found to remove"
	fi
	return 0
}

# Create fastfetch configuration
# Usage: setup_fastfetch
# Returns: 0 on success, 1 on failure
setup_fastfetch() {
	local fastfetch_dir="$HOME/.config/fastfetch"
	local config_file="$fastfetch_dir/config.jsonc"
	
	logger info "setting up fastfetch configuration..."
	
	# Create directory if it doesn't exist
	if [ ! -d "$fastfetch_dir" ]; then
		mkdir -p "$fastfetch_dir" || {
			logger error "failed to create fastfetch directory"
			return 1
		}
	fi
	
	# Create the configuration file
	cat > "$config_file" << 'EOF'
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "type": "data",
    "source": "\u001b[97m  ▄▀▄▀▀▀▀▄▀▄\n  █        ▀▄      ▄\n █  ▀  ▀     ▀▄▄  █ █\n █ ▄ █▀ ▄       ▀▀  █\n █  ▀▀▀▀            █\n █                  █\n █                  █\n  █  ▄▄  ▄▄▄▄  ▄▄  █\n  █ ▄▀█ ▄▀  █ ▄▀█ ▄▀\n   ▀   ▀     ▀   ▀\u001b[0m",
    "padding": {
      "top": 1,
      "left": 1
    }
  },
  "display": {
    "color": {
      "keys": "90",
      "title": "90"
    }
  },
  "modules": [
    "title",
    "separator",
    "os",
    "host",
    "kernel",
    "uptime",
    "packages",
    "shell",
    "wm",
    "terminal",
    "cpu",
    "gpu",
    "memory",
    "swap",
    "disk",
    "localip",
    "battery",
    "locale"
  ]
}
EOF
	
	clear_previous_line
	if [ $? -eq 0 ]; then
		logger done "fastfetch configuration created"
		return 0
	else
		logger error "failed to create fastfetch configuration"
		return 1
	fi
}

# Complete system setup (stow, zsh, bash cleanup, fastfetch)
# Usage: complete_setup
# Returns: 0 on success, 1 on any failure
complete_setup() {
	local setup_error=0
	
	# Run stow
	if ! run_stow; then
		setup_error=1
	fi
	
	# Set zsh as default shell
	if ! set_zsh_default; then
		setup_error=1
	fi
	
	# Remove bash files
	remove_bash_files
	
	# Setup fastfetch configuration
	if ! setup_fastfetch; then
		setup_error=1
	fi
	
	return $setup_error
}
