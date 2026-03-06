# set cursor to
# echo "\e[2 q" & clear # steady block
# echo "\e[4 q" & clear # steady underline

# ignore the rest of the file if not running interactively
[[ $- != *i* ]] && return

export ZSHCONF="$HOME/dotfiles/_/zsh"

[ -f $ZSHCONF/env ] && source $ZSHCONF/env
[ -f $ZSHCONF/path ] && source $ZSHCONF/path
[ -f $ZSHCONF/source ] && source $ZSHCONF/source
[ -f $ZSHCONF/aliases ] && source $ZSHCONF/aliases
