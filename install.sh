#!/bin/bash

set -e

log() {
	echo -e "\033[44m INFO \033[0m $1"
}

# update
log "Updating package list..."
sudo apt update

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

for package in "${apt_packages[@]}"; do
	if ! command -v "$package" &> /dev/null; then
		log "Installing $package..."
		sudo apt install -y "$package"
	else
		log "$package is already installed"
	fi
done

# docker
if ! command -v docker &> /dev/null; then
	log "Installing docker..."
	curl -fsSL https://get.docker.com -o get-docker.sh
	sh get-docker.sh
	sudo usermod -aG docker $USER
	rm get-docker.sh
else
	log "docker is already installed"
fi

# node
if ! command -v node &> /dev/null; then
	log "Installing node..."
	curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
	sudo apt install -y nodejs
else
	log "node is already installed"
fi

# uv
if ! command -v uv &> /dev/null; then
	log "Installing uv..."
	curl -LsSf https://astral.sh/uv/install.sh | sh
else
	log "uv is already installed"
fi

# adguardvpn-cli
if ! command -v adguardvpn-cli &> /dev/null; then
	log "Installing AdGuard VPN CLI..."
	curl -fsSL https://raw.githubusercontent.com/AdguardTeam/AdGuardVPNCLI/master/scripts/release/install.sh | sh -s -- -v
else
	log "AdGuard VPN CLI is already installed"
fi

# stow
log "Running stow..."
stow zsh git

# zsh
log "Setting zsh as default shell..."
sudo chsh -s $(which zsh) $USER

# bash
log "Removing bash files..."
rm -f ~/.bashrc ~/.bash_profile ~/.profile ~/.bash_logout ~/.bash_history

# complete
log "Installation complete"
