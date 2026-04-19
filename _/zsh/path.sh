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
[ -d ~/.pyenv ] && eval "$(pyenv init - zsh)"
add_to_path ~/.bun/bin
add_to_path ~/.cargo/bin

# cleanup
unset -f add_to_path
