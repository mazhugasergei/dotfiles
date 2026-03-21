#!/bin/bash

set -e

# Logger object with dot notation methods
logger() {
	local method="$1"
	local message="$2"
	
	case "$method" in
		"info")
			echo -e "\033[44m INFO \033[0m $message"
			;;
		"done")
			echo -e "\033[42m DONE \033[0m $message"
			;;
		"error")
			echo -e "\033[41m ERROR \033[0m $message"
			;;
		"warn")
			echo -e "\033[43m WARN \033[0m $message"
			;;
		*)
			echo "Unknown logger method: $method"
			return 1
			;;
	esac
}

# update
logger info "Updating package list..."
sudo apt-get update -qq

# apt packages (binary:package mapping)
declare -A apt_packages=(
	["zsh"]="zsh"
	["wget"]="wget"
	["curl"]="curl"
	["ca-certificates"]="ca-certificates"
	["stow"]="stow"
	["git"]="git"
	["gh"]="gh"
	["python3"]="python3"
	["pip"]="python3-pip"
)

# Check all packages and create installation plan
declare -A to_install
declare -A already_installed

logger info "Checking package status..."
for binary in "${!apt_packages[@]}"; do
	package="${apt_packages[$binary]}"
	if ! dpkg -l | grep -q "^ii  $package "; then
		to_install["$package"]="$binary"
	else
		already_installed["$package"]="$binary"
	fi
done

# Display package status table
echo ""

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

# Ensure minimum widths and add padding
pkg_col_width=$((max_pkg_length + 2))
status_col_width=$((max_status_length + 2))
if [ $pkg_col_width -lt 23 ]; then
	pkg_col_width=23
fi
if [ $status_col_width -lt 17 ]; then
	status_col_width=17
fi

# Build table dynamically
top_border="┌─$(printf '─%.0s' $(seq 1 $pkg_col_width))─┬─$(printf '─%.0s' $(seq 1 $status_col_width))─┐"
header="│ $(printf "%-${pkg_col_width}s" "Package Name") │ $(printf "%-${status_col_width}s" "Status") │"
middle_border="├─$(printf '─%.0s' $(seq 1 $pkg_col_width))─┼─$(printf '─%.0s' $(seq 1 $status_col_width))─┤"
bottom_border="└─$(printf '─%.0s' $(seq 1 $pkg_col_width))─┴─$(printf '─%.0s' $(seq 1 $status_col_width))─┘"

echo "$top_border"
echo "$header"
echo "$middle_border"

for package in "${!already_installed[@]}"; do
	echo "│ $(printf "%-${pkg_col_width}s" "$package") │ ✓ Already installed │"
done

for package in "${!to_install[@]}"; do
	echo "│ $(printf "%-${pkg_col_width}s" "$package") │ ○ To be installed  │"
done

echo "$bottom_border"
echo ""

# Install missing packages
if [ ${#to_install[@]} -gt 0 ]; then
	logger info "Installing missing packages..."
	for package in "${!to_install[@]}"; do
		logger info "Installing $package..."
		sudo apt-get install -yqq "$package"
		logger done "$package installed"
	done
else
	logger done "All packages are already installed"
fi

# docker
if ! command -v docker &> /dev/null; then
	logger info "Installing docker..."
	curl -fsSL https://get.docker.com -o get-docker.sh
	sh get-docker.sh
	sudo usermod -aG docker $USER
	rm get-docker.sh
else
	logger done "docker is already installed"
fi

# node
if ! command -v node &> /dev/null; then
	logger info "Installing node..."
	curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
	sudo apt-get install -yqq nodejs
else
	logger done "node is already installed"
fi

# uv
# if ! command -v uv &> /dev/null; then
# 	logger info "Installing uv..."
# 	curl -LsSf https://astral.sh/uv/install.sh | sh
# else
# 	logger done "uv is already installed"
# fi

# adguardvpn-cli
if ! command -v adguardvpn-cli &> /dev/null; then
	logger info "Installing AdGuard VPN CLI..."
	curl -fsSL https://raw.githubusercontent.com/AdguardTeam/AdGuardVPNCLI/master/scripts/release/install.sh | sh -s -- -v
else
	logger done "AdGuard VPN CLI is already installed"
fi

# stow
logger info "Running stow..."
stow zsh git
logger done "stow completed"

# zsh
if [ "$SHELL" != "$(which zsh)" ]; then
	logger info "Setting zsh as default shell..."
	sudo chsh -s $(which zsh) $USER
	logger done "zsh set as default shell"
else
	logger done "zsh is already the default shell"
fi

# bash
bash_files=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.bash_logout" "$HOME/.bash_history")
files_removed=false

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

# complete
logger done "Installation complete"
