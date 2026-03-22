#!/bin/bash

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

# Intro Function
# Usage: show_intro
show_intro() {
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
}

# Outro Function
# Usage: show_outro [success|error]
show_outro() {
	local status="${1:-success}"
	
	if [ "$status" = "error" ]; then
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
}
