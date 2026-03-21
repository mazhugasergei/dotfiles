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

# apt packages
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

# Check all packages and create installation plan
declare -A to_install
declare -A already_installed

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
non_apt_packages=(
	"docker"
	"node"
	"adguardvpn-cli"
)

for package in "${non_apt_packages[@]}"; do
	if ! which "$package" &> /dev/null; then
		to_install["$package"]="custom"
	else
		already_installed["$package"]="custom"
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

# Configuration for table formatting
min_pkg_col_width=23
min_status_col_width=17
min_method_col_width=8
col_padding=2

# Ensure minimum widths and add padding
pkg_col_width=$((max_pkg_length + col_padding))
status_col_width=$((max_status_length + col_padding))
method_col_width=$((min_method_col_width + col_padding))
if [ $pkg_col_width -lt $min_pkg_col_width ]; then
	pkg_col_width=$min_pkg_col_width
fi
if [ $status_col_width -lt $min_status_col_width ]; then
	status_col_width=$min_status_col_width
fi

# Build table dynamically
top_border="┌─$(printf '─%.0s' $(seq 1 $pkg_col_width))─┬─$(printf '─%.0s' $(seq 1 $status_col_width))─┬─$(printf '─%.0s' $(seq 1 $method_col_width))─┐"
header="│ $(printf "%-${pkg_col_width}s" "Package Name") │ $(printf "%-${status_col_width}s" "Status") │ $(printf "%-${method_col_width}s" "Method") │"
middle_border="├─$(printf '─%.0s' $(seq 1 $pkg_col_width))─┼─$(printf '─%.0s' $(seq 1 $status_col_width))─┼─$(printf '─%.0s' $(seq 1 $method_col_width))─┤"
bottom_border="└─$(printf '─%.0s' $(seq 1 $pkg_col_width))─┴─$(printf '─%.0s' $(seq 1 $status_col_width))─┴─$(printf '─%.0s' $(seq 1 $method_col_width))─┘"

echo "$top_border"
echo "$header"
echo "$middle_border"

for package in "${!already_installed[@]}"; do
	method="${already_installed[$package]}"
	echo -e "│ $(printf "%-${pkg_col_width}s" "$package") │ \033[32m✓ Already installed\033[0m │ $(printf "%-${method_col_width}s" "$method") │"
done

for package in "${!to_install[@]}"; do
	method="${to_install[$package]}"
	echo "│ $(printf "%-${pkg_col_width}s" "$package") │ ○ To be installed  │ $(printf "%-${method_col_width}s" "$method") │"
done

echo "$bottom_border"
echo ""

# Install missing packages
if [ ${#to_install[@]} -gt 0 ]; then
	logger info "Installing missing packages..."
	for package in "${!to_install[@]}"; do
		method="${to_install[$package]}"
		case "$method" in
			"apt")
				logger info "Installing $package via apt..."
				sudo apt-get install -yqq "$package"
				logger done "$package installed"
				;;
			"custom")
				case "$package" in
					"docker")
						logger info "Installing $package via official script..."
						curl -fsSL https://get.docker.com -o get-docker.sh
						sh get-docker.sh
						sudo usermod -aG docker $USER
						rm get-docker.sh
						logger done "$package installed"
						;;
					"node")
						logger info "Installing $package via NodeSource..."
						curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
						sudo apt-get install -yqq nodejs
						logger done "$package installed"
						;;
					"adguardvpn-cli")
						logger info "Installing $package via official script..."
						curl -fsSL https://raw.githubusercontent.com/AdguardTeam/AdGuardVPNCLI/master/scripts/release/install.sh | sh -s -- -v
						logger done "$package installed"
						;;
				esac
				;;
		esac
	done
else
	logger done "All packages are already installed"
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
