skip_global_compinit=1

# custom prompt
PROMPT='%F{8}%~ %F{2}$ %f'

# prevent duplicate entries in command history
export HISTCONTROL=ignoredups

# set history size limits
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history

# X Server
# (only set DISPLAY if running WSL)
if [[ -n "$WSL_DISTRO_NAME" ]]; then
  export DISPLAY=$(ip route | awk '/default/ {print $3}'):0.0
fi
