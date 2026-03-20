#!/bin/bash

set -e

log() {
	echo -e "\033[44m INFO \033[0m $1"
}

log "Installing zsh..."
sudo apt update && sudo apt install -y zsh

log "Setting zsh as default shell..."
sudo chsh -s $(which zsh) $USER

log "Installing stow..."
if ! command -v stow &> /dev/null; then
	sudo apt install -y stow
fi

log "Installing git..."
if ! command -v git &> /dev/null; then
	sudo apt install -y git
fi

log "Installing docker..."
if ! command -v docker &> /dev/null; then
	curl -fsSL https://get.docker.com -o get-docker.sh
	sh get-docker.sh
	sudo usermod -aG docker $USER
	rm get-docker.sh
fi

log "Installing node..."
if ! command -v node &> /dev/null; then
	curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
	sudo apt install -y nodejs
fi

log "Installing python..."
if ! command -v python3 &> /dev/null; then
	sudo apt install -y python3 python3-pip
fi

log "Installing uv..."
if ! command -v uv &> /dev/null; then
	curl -LsSf https://astral.sh/uv/install.sh | sh
fi

log "Running stow..."
stow zsh git

log "Installation complete"

log "Removing bash files..."
rm -f ~/.bashrc ~/.bash_profile ~/.profile ~/.bash_logout ~/.bash_history
