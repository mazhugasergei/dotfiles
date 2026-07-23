add_to_path() {
	if [ -d "$1" ]; then 
		case ":${PATH}:" in 
			*:"$1":*) ;; 
			*) export PATH="$1:$PATH" ;; 
		esac
	fi
}

add_to_path /snap/bin
add_to_path ~/.local/bin
add_to_path ~/.pyenv/bin
# [ -d ~/.pyenv ] && eval "$(pyenv init - zsh)"
add_to_path ~/.bun/bin
add_to_path ~/.cargo/bin # Rust Package Manager ; TODO: remove `. "$HOME/.cargo/env"` in .zshenv
add_to_path /usr/local/go/bin

# cleanup
unset -f add_to_path
