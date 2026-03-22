#!/bin/bash

# Package Manager Utilities
# Provides functions for checking, displaying, and installing packages

# Package lists
apt_packages=(
	"fastfetch"
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

# Display package status table
# Usage: display_package_table
display_package_table() {
  # Move cursor up and clear line
  echo -ne "\033[1A\033[K"
  logger done "package status check completed, see the results below"
  echo ""

  # CRITICAL: Use declare -A for associative arrays
  declare -A table_titles
  table_titles["pkg"]="Package Name"
  table_titles["method"]="Method" 
  table_titles["status"]="Status"
  
  status_strings=("✓ Already installed" "○ To be installed")

  # 1. Calculate max widths (using 'wc -m' for accurate character counts)
  all_packages=("${!already_installed[@]}" "${!to_install[@]}" "${table_titles[pkg]}")
  max_pkg_length=0
  for p in "${all_packages[@]}"; do
    len=$(echo -n "$p" | wc -m)
    (( len > max_pkg_length )) && max_pkg_length=$len
  done

  max_method_length=15 # Hardcoded or calculated similarly to pkg
  
  # Status column needs careful handling due to Unicode symbols
  max_status_length=0
  for s in "${status_strings[@]}" "${table_titles[status]}"; do
    len=$(echo -n "$s" | wc -m)
    (( len > max_status_length )) && max_status_length=$len
  done

  # Helper function to print a padded row
  print_row() {
    local col1="$1"
    local col2="$2"
    local col3="$3"
    local color="$4"

    # Calculate padding for the status column manually to account for Unicode
    local col3_len=$(echo -n "$col3" | wc -m)
    local padding_count=$((max_status_length - col3_len))
    local padding=$(printf '%*s' "$padding_count" "")

    printf "│ %-${max_pkg_length}s │ %-${max_method_length}s │ %b%s%b%s │\n" \
      "$col1" "$col2" "$color" "$col3" "\033[0m" "$padding"
  }

  # 2. Draw Table
  local line_pkg=$(printf '─%.0s' $(seq 1 $((max_pkg_length + 2))))
  local line_met=$(printf '─%.0s' $(seq 1 $((max_method_length + 2))))
  local line_sta=$(printf '─%.0s' $(seq 1 $((max_status_length + 2))))

  echo "┌${line_pkg}┬${line_met}┬${line_sta}┐"
  print_row "${table_titles[pkg]}" "${table_titles[method]}" "${table_titles[status]}" ""
  echo "├${line_pkg}┼${line_met}┼${line_sta}┤"

  for package in "${!already_installed[@]}"; do
    print_row "$package" "${already_installed[$package]}" "${status_strings[0]}" "\033[32m"
  done

  for package in "${!to_install[@]}"; do
    print_row "$package" "${to_install[$package]}" "${status_strings[1]}" ""
  done

  echo "└${line_pkg}┴${line_met}┴${line_sta}┘"
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
