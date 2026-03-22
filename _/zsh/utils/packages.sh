#!/bin/bash

# Package Manager Utilities
# Provides functions for checking, displaying, and installing packages

# Package lists
apt_packages=(
	"zsh"
	"wget"
	"curl"
	"ca-certificates"
	"stow"
	"git"
	"gh"
	"python3"
	"python3-pip"
)

non_apt_packages=(
	"docker"
	"node"
	"adguardvpn-cli"
	"uv"
)

# Check package status and create installation plan
# Usage: check_package_status
# Returns: Sets global arrays to_install and already_installed
check_package_status() {
	declare -gA to_install
	declare -gA already_installed

	logger info "Checking package status..."

	# Check apt packages
	for package in "${apt_packages[@]}"; do
		if ! dpkg -l | grep -q "^ii  $package "; then
			to_install["$package"]="apt"
		else
			already_installed["$package"]="apt"
		fi
	done

	# Check non-apt packages
	for package in "${non_apt_packages[@]}"; do
		if ! which "$package" &> /dev/null; then
			to_install["$package"]="custom"
		else
			already_installed["$package"]="custom"
		fi
	done
}

# Calculate table dimensions for package display
# Usage: calculate_table_dimensions
# Returns: Sets global table width variables
calculate_table_dimensions() {
	# Find the longest package name
	max_pkg_length=0
	all_packages=("${!already_installed[@]}" "${!to_install[@]}")
	for package in "${all_packages[@]}"; do
		if [ ${#package} -gt $max_pkg_length ]; then
			max_pkg_length=${#package}
		fi
	done

	# Find the longest status string
	status_strings=("Already installed" "To be installed")
	max_status_length=0
	for status in "${status_strings[@]}"; do
		if [ ${#status} -gt $max_status_length ]; then
			max_status_length=${#status}
		fi
	done

	# Configuration for table formatting
	table_pkg_col_min_width=23
	table_status_col_min_width=17
	table_method_col_min_width=8
	table_col_padding=2

	# Ensure minimum widths and add padding
	declare -g table_pkg_col_width=$((max_pkg_length + table_col_padding))
	declare -g table_status_col_width=$((max_status_length + table_col_padding))
	declare -g table_method_col_width=$((table_method_col_min_width + table_col_padding))
	
	if [ $table_pkg_col_width -lt $table_pkg_col_min_width ]; then
		table_pkg_col_width=$table_pkg_col_min_width
	fi
	if [ $table_status_col_width -lt $table_status_col_min_width ]; then
		table_status_col_width=$table_status_col_min_width
	fi
}

# Display package status table
# Usage: display_package_table
display_package_table() {
	# Move cursor up one line and clear it to erase the "Checking package status..." message
	echo -ne "\033[1A\033[K"
	
	# Show check completed message
	logger done "package status check completed, see the results below"
	
	echo ""
	calculate_table_dimensions

	# Build table dynamically
	table_top_border="┌─$(printf '─%.0s' $(seq 1 $table_pkg_col_width))─┬─$(printf '─%.0s' $(seq 1 $table_method_col_width))─┬─$(printf '─%.0s' $(seq 1 $table_status_col_width))─┐"
	table_header="│ $(printf "%-${table_pkg_col_width}s" "Package Name") │ $(printf "%-${table_method_col_width}s" "Method") │ $(printf "%-${table_status_col_width}s" "Status") │"
	table_middle_border="├─$(printf '─%.0s' $(seq 1 $table_pkg_col_width))─┼─$(printf '─%.0s' $(seq 1 $table_method_col_width))─┼─$(printf '─%.0s' $(seq 1 $table_status_col_width))─┤"
	table_bottom_border="└─$(printf '─%.0s' $(seq 1 $table_pkg_col_width))─┴─$(printf '─%.0s' $(seq 1 $table_method_col_width))─┴─$(printf '─%.0s' $(seq 1 $table_status_col_width))─┘"

	echo "$table_top_border"
	echo "$table_header"
	echo "$table_middle_border"

	for package in "${!already_installed[@]}"; do
		method="${already_installed[$package]}"
		echo -e "│ $(printf "%-${table_pkg_col_width}s" "$package") │ $(printf "%-${table_method_col_width}s" "$method") │ \033[32m✓ Already installed\033[0m │"
	done

	for package in "${!to_install[@]}"; do
		method="${to_install[$package]}"
		echo "│ $(printf "%-${table_pkg_col_width}s" "$package") │ $(printf "%-${table_method_col_width}s" "$method") │ ○ To be installed  │"
	done

	echo "$table_bottom_border"
	echo ""
}

# Install packages using apt
# Usage: install_apt_package <package>
install_apt_package() {
	local package="$1"
	logger info "Installing $package via apt..."
	if ! sudo apt-get install -yqq "$package"; then
		return 1
	fi
	logger done "$package installed"
	return 0
}

# Install Docker
# Usage: install_docker
install_docker() {
	logger info "Installing docker via official script..."
	if ! curl -fsSL https://get.docker.com -o get-docker.sh; then
		return 1
	fi
	if ! sh get-docker.sh; then
		rm get-docker.sh
		return 1
	fi
	if ! sudo usermod -aG docker $USER; then
		rm get-docker.sh
		return 1
	fi
	rm get-docker.sh
	logger done "docker installed"
	return 0
}

# Install Node.js
# Usage: install_node
install_node() {
	logger info "Installing node via NodeSource..."
	if ! curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -; then
		return 1
	fi
	if ! sudo apt-get install -yqq nodejs; then
		return 1
	fi
	logger done "node installed"
	return 0
}

# Install AdGuard VPN CLI
# Usage: install_adguardvpn_cli
install_adguardvpn_cli() {
	logger info "Installing adguardvpn-cli via official script..."
	if ! curl -fsSL https://raw.githubusercontent.com/AdguardTeam/AdGuardVPNCLI/master/scripts/release/install.sh | sh -s -- 2>/dev/null; then
		return 1
	fi
	logger done "adguardvpn-cli installed"
	
	# Source .zshrc to ensure adguardvpn-cli is in PATH
	source "$HOME/.zshrc" 2>/dev/null || true
	
	# Configure AdGuard VPN to change system DNS
	logger info "Configuring AdGuard VPN DNS settings..."
	if ! adguardvpn-cli config set-change-system-dns on; then
		logger warn "Failed to configure AdGuard VPN DNS settings"
		return 1
	fi
	logger done "AdGuard VPN DNS configured"
	return 0
}

# Install uv (Python package manager)
# Usage: install_uv
install_uv() {
	logger info "Installing uv via official script..."
	if ! curl -sSfL https://astral.sh/uv/install.sh | sh; then
		return 1
	fi
	logger done "uv installed"
	return 0
}

# Install custom packages
# Usage: install_custom_package <package>
install_custom_package() {
	local package="$1"
	case "$package" in
		"docker")
			install_docker
			;;
		"node")
			install_node
			;;
		"adguardvpn-cli")
			install_adguardvpn_cli
			;;
		"uv")
			install_uv
			;;
		*)
			logger error "Unknown custom package: $package"
			return 1
			;;
	esac
}

# Install all missing packages
# Usage: install_packages
# Returns: 0 on success, 1 on any installation error
install_packages() {
	if [ ${#to_install[@]} -gt 0 ]; then
		logger info "Installing missing packages..."
		local install_error=0
		
		for package in "${!to_install[@]}"; do
			method="${to_install[$package]}"
			case "$method" in
				"apt")
					if ! install_apt_package "$package"; then
						install_error=1
					fi
					;;
				"custom")
					if ! install_custom_package "$package"; then
						install_error=1
					fi
					;;
			esac
		done
		
		return $install_error
	else
		logger done "All packages are already installed"
		return 0
	fi
}

# Main package management function
# Usage: manage_packages
# Returns: 0 on success, 1 on any error
manage_packages() {
	# Update package list
	logger info "Updating package list..."
	
	if ! sudo apt-get update -qq; then
		# Move cursor up one line and clear it to overwrite the previous message
		echo -ne "\033[1A\033[K"
		logger error "package list update failed"
		return 1
	fi
	
	# Move cursor up one line and clear it to overwrite the previous message
	echo -ne "\033[1A\033[K"
	logger done "package list updated"
	
	# Check package status
	check_package_status
	
	# Display package table
	display_package_table
	
	# Install packages
	if ! install_packages; then
		return 1
	fi
	
	return 0
}
