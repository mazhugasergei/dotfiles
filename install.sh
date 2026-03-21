#!/bin/bash

set -e

# Parse command line arguments
SKIP_INTRO=false
INSTALLATION_ERROR=false
while [[ $# -gt 0 ]]; do
	case "$1" in
		-s|--skip)
			SKIP_INTRO=true
			shift
			;;
		-h|--help)
			echo "Usage: $0 [OPTIONS]"
			echo ""
			echo "OPTIONS:"
			echo "  -s, --skip         Skip the intro and outro typewriter effects"
			echo "  -h, --help         Show this help message"
			echo ""
			echo "Examples:"
			echo "  $0                    Run full installation with effects"
			echo "  $0 -s                Skip effects and go straight to installation"
			echo ""
			exit 0
			;;
		*)
			echo "Unknown option: $1"
			echo "Usage: $0 [-s|--skip] [-h|--help]"
			exit 1
			;;
	esac
done

# Check for sudo privileges
if ! sudo -n true 2>/dev/null; then
	logger warn "This script requires sudo privileges to install packages."
	logger warn "Please enter your sudo password when prompted."
	sudo -v
	if [ $? -ne 0 ]; then
		logger error "Sudo authentication failed. Exiting."
		exit 1
	fi
	logger done "Sudo access verified"
fi

# Typewriter Configuration
TYPE_SPEED=0.05
TYPE_LINES_DELAY=1

# Typewriter Function
# Usage: type_out "text"
type_out() {
  echo -e "$1" | while IFS= read -r -n1 char; do
    printf "%s" "$char"
    sleep "$TYPE_SPEED"
  done
  printf "\n"
}

# The Intro Reveal
if [ "$SKIP_INTRO" = false ]; then
	intro_strings=(
		"> Right, let's have a look at this absolute shambles, then..."
		"> I shall be transforming this appalling OS into a world-class workstation, easy days."
		"> A cheeky little install? Don't mind if I do..."
	)
	
	echo ""
	sleep "$TYPE_LINES_DELAY"
	for line in "${intro_strings[@]}"; do
		type_out "$line"
		sleep "$TYPE_LINES_DELAY"
	done
	echo ""
fi

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
	"uv"
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
table_pkg_col_min_width=23
table_status_col_min_width=17
table_method_col_min_width=8
table_col_padding=2

# Ensure minimum widths and add padding
table_pkg_col_width=$((max_pkg_length + table_col_padding))
table_status_col_width=$((max_status_length + table_col_padding))
table_method_col_width=$((table_method_col_min_width + table_col_padding))
if [ $table_pkg_col_width -lt $table_pkg_col_min_width ]; then
	table_pkg_col_width=$table_pkg_col_min_width
fi
if [ $table_status_col_width -lt $table_status_col_min_width ]; then
	table_status_col_width=$table_status_col_min_width
fi

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

# Install missing packages
if [ ${#to_install[@]} -gt 0 ]; then
	logger info "Installing missing packages..."
	for package in "${!to_install[@]}"; do
		method="${to_install[$package]}"
		case "$method" in
			"apt")
				logger info "Installing $package via apt..."
				if ! sudo apt-get install -yqq "$package"; then
					INSTALLATION_ERROR=true
				fi
				logger done "$package installed"
				;;
			"custom")
				case "$package" in
					"docker")
						logger info "Installing $package via official script..."
						if ! curl -fsSL https://get.docker.com -o get-docker.sh; then
							INSTALLATION_ERROR=true
						fi
						if ! sh get-docker.sh; then
							INSTALLATION_ERROR=true
						fi
						if ! sudo usermod -aG docker $USER; then
							INSTALLATION_ERROR=true
						fi
						rm get-docker.sh
						logger done "$package installed"
						;;
					"node")
						logger info "Installing $package via NodeSource..."
						if ! curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -; then
							INSTALLATION_ERROR=true
						fi
						if ! sudo apt-get install -yqq nodejs; then
							INSTALLATION_ERROR=true
						fi
						logger done "$package installed"
						;;
					"adguardvpn-cli")
						logger info "Installing $package via official script..."
						if ! curl -fsSL https://raw.githubusercontent.com/AdguardTeam/AdGuardVPNCLI/master/scripts/release/install.sh | sh -s -- -v; then
							INSTALLATION_ERROR=true
						fi
						logger done "$package installed"
						;;
					"uv")
						logger info "Installing $package via official script..."
						if ! curl -sSfL https://astral.sh/uv/install.sh | sh; then
							INSTALLATION_ERROR=true
						fi
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
original_dir=$(pwd)
cd "$(dirname "$0")"
logger info "Running stow..."
stow zsh git
logger done "stow completed"
cd "$original_dir"

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
if [ "$SKIP_INTRO" = false ]; then
	# The Outro
	if [ "$INSTALLATION_ERROR" = true ]; then
		outro_strings=(
			"> Well, this is a right old dog's dinner, isn't it?"
			"> It appears your machine has rejected my superior efforts. Typical."
			"> I've reached a bit of a sticky wicket. Absolute shambles."
			"> I'm off for a sulk. Sort it out yourself. Toodle-loo!"
		)
	else
		outro_strings=(
			"> Miraculous. It's almost as if a competent professional handled the setup."
			"> I've managed to save this rig from certain mediocrity. You're quite welcome."
			"> Everything is in its right place. Simply marvelous. Wallop."
		)
	fi
	
	echo ""
	sleep "$TYPE_LINES_DELAY"
	for line in "${outro_strings[@]}"; do
		type_out "$line"
		sleep "$TYPE_LINES_DELAY"
	done
	echo ""
fi
