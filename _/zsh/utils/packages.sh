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

# Helper function to move cursor up one line and clear it
# Usage: clear_previous_line
clear_previous_line() {
	echo -ne "\033[1A\033[K"
}

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
  clear_previous_line
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

  # Calculate max method length dynamically
  all_methods=("apt" "custom" "${table_titles[method]}")
  max_method_length=0
  for m in "${all_methods[@]}"; do
    len=$(echo -n "$m" | wc -m)
    (( len > max_method_length )) && max_method_length=$len
  done

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
	if ! sudo apt-get install -yqq "$package" &> /dev/null; then
		return 1
	fi
	clear_previous_line
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

# Install Node.js and npm via NVM (Avoids apt/sudo conflicts)
# Usage: install_node [version_tag]
install_node() {
  local NODE_VERSION=${1:-"--lts"}
  
  logger info "Checking for NVM (Node Version Manager)..."
  
  # 1. Install or Load NVM
  if [ ! -d "$HOME/.nvm" ]; then
    clear_previous_line
    logger info "NVM not found. Installing..."
    # Silent download and install, silencing the bash output entirely
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash > /dev/null 2>&1
  else
    clear_previous_line
    logger info "NVM already installed. Loading..."
  fi

  # Initialize NVM into current shell session
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  # 2. Install Node and NPM
  logger info "Installing Node.js ($NODE_VERSION)..."
  
  # Note: Removed quotes from $NODE_VERSION so --lts is passed as a flag
  if nvm install $NODE_VERSION > /dev/null 2>&1; then
    
    # Determine the correct string for alias/use
    local TARGET_VER=$NODE_VERSION
    if [[ "$NODE_VERSION" == "--lts" ]]; then
      TARGET_VER="lts/*"
    fi

    nvm use "$TARGET_VER" > /dev/null
    nvm alias default "$TARGET_VER" > /dev/null
    
    local INSTALLED_NODE=$(node -v)
    local INSTALLED_NPM=$(npm -v)
    
    clear_previous_line
    logger done "Node $INSTALLED_NODE and npm $INSTALLED_NPM installed"
    return 0
  else
    clear_previous_line
    logger error "Node.js installation failed"
    return 1
  fi
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
		
		# Show completion log after all installations
		if [ $install_error -eq 0 ]; then
			logger done "All packages installed successfully"
		else
			logger warn "Some packages failed to install"
		fi
		
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
		clear_previous_line
		logger error "package list update failed"
		return 1
	fi
	
	clear_previous_line
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
