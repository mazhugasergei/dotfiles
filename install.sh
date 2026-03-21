#!/bin/bash

set -e

# Logger object with dot notation methods
logger() {
	local method="$1"
	local message="$2"
	
	case "$method" in
		"log")
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
logger log "Updating package list..."
sudo apt update

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

for binary in "${!apt_packages[@]}"; do
	package="${apt_packages[$binary]}"
	if ! command -v "$binary" &> /dev/null; then
		logger log "Installing $package..."
		sudo apt install -y "$package"
	else
		logger done "$package is already installed"
	fi
done

# docker
if ! command -v docker &> /dev/null; then
	logger log "Installing docker..."
	curl -fsSL https://get.docker.com -o get-docker.sh
	sh get-docker.sh
	sudo usermod -aG docker $USER
	rm get-docker.sh
else
	logger done "docker is already installed"
fi

# node
if ! command -v node &> /dev/null; then
	logger log "Installing node..."
	curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
	sudo apt install -y nodejs
else
	logger done "node is already installed"
fi

# uv
if ! command -v uv &> /dev/null; then
	logger log "Installing uv..."
	curl -LsSf https://astral.sh/uv/install.sh | sh
else
	logger done "uv is already installed"
fi

# adguardvpn-cli
if ! command -v adguardvpn-cli &> /dev/null; then
	logger log "Installing AdGuard VPN CLI..."
	curl -fsSL https://raw.githubusercontent.com/AdguardTeam/AdGuardVPNCLI/master/scripts/release/install.sh | sh -s -- -v
else
	logger done "AdGuard VPN CLI is already installed"
fi

# stow
log "Running stow..."
stow zsh git
logger done "stow completed"

# zsh
logger log "Setting zsh as default shell..."
sudo chsh -s $(which zsh) $USER
logger done "zsh set as default shell"

# bash
logger log "Removing bash files..."
rm -f ~/.bashrc ~/.bash_profile ~/.profile ~/.bash_logout ~/.bash_history
logger done "bash files removed"

# complete
logger done "Installation complete"
