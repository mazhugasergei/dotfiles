#!/bin/bash

# Run stow to configure dotfiles
# Returns: 0 on success, 1 on failure
run_stow() {
	local original_dir=$(pwd)
	cd "$(dirname "${BASH_SOURCE[1]}")"  # Use the calling script's directory
	
	# Show initial log
	logger info "running stow..."
	
	# Move cursor up one line and clear it to overwrite the previous message
	echo -ne "\033[1A\033[K"

	to_stow=(zsh git)
	
	# Remove conflicting files before stowing
	rm -f "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.zlogin" "$HOME/.zlogout" 2>/dev/null || true
	rm -f "$HOME/.gitconfig" "$HOME/.gitignore" 2>/dev/null || true
	rm -rf "$HOME/.config/zsh" "$HOME/.config/git" 2>/dev/null || true
	
	if stow "${to_stow[@]}"; then
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
	
	return $setup_error
}
