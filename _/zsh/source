# helper function to source files if they exist
source_if_exists() {
  [ -s "$1" ] && source "$1"
}

# plugins
source_if_exists $ZSHCONF/plugins/zsh-autosuggestions/plugin.zsh

# nvm
source_if_exists ~/.nvm/nvm.sh
source_if_exists ~/.nvm/bash_completion

# bun
source_if_exists ~/.bun/_bun
