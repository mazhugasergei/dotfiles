# set cursor to
# echo "\e[2 q" & clear # steady block
# echo "\e[4 q" & clear # steady underline

# ignore the rest of the file if not running interactively
[[ $- != *i* ]] && return

export ZSHCONF="$HOME/dotfiles/_/zsh"

[ -f $ZSHCONF/env.sh ] && source $ZSHCONF/env.sh
[ -f $ZSHCONF/path.sh ] && source $ZSHCONF/path.sh
[ -f $ZSHCONF/source.sh ] && source $ZSHCONF/source.sh
[ -f $ZSHCONF/aliases.sh ] && source $ZSHCONF/aliases.sh
