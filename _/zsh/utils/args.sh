#!/bin/bash

# Command Line Argument Utilities
# Provides functions for parsing command line arguments and displaying help

# Print help message
# Usage: print_help
print_help() {
	echo "Usage: $0 [OPTIONS]"
	echo ""
	echo "OPTIONS:"
	echo "  -e, --effects				Show intro and outro typewriter effects"
	echo "      --errored				Force error condition for testing error outro"
	echo "  -h, --help					Show this help message"
	echo ""
}

# Parse command line arguments
# Usage: parse_arguments "$@"
# Sets global variables: SKIP, SKIP_INTRO, FORCE_ERROR, INSTALLATION_ERROR
parse_arguments() {
	# Initialize default values
	SHOW_EFFECTS=false
	FORCE_ERROR=false
	INSTALLATION_ERROR=false
	
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-e|--effects)
				SHOW_EFFECTS=true
				shift
				;;
			--errored)
				FORCE_ERROR=true
				shift
				;;
			-h|--help)
				print_help
				exit 0
				;;
			-*)
				# Handle combined short flags
				flags=$(echo "$1" | sed 's/^-//')
				for flag in $(echo "$flags" | fold -w1); do
					case "$flag" in
						e)
							# Count 'e' flags to determine behavior
							e_count=$(echo "$flags" | grep -o 'e' | wc -l)
							if [ $e_count -eq 1 ]; then
								SHOW_EFFECTS=true
							elif [ $e_count -gt 1 ]; then
								# Multiple 'e's means effects + errored
								SHOW_EFFECTS=true
								FORCE_ERROR=true
							fi
							;;
						*)
							echo "Unknown option: -$flag"
							print_help
							exit 1
							;;
					esac
				done
				shift
				;;
			*)
				echo "Unknown option: $1"
				print_help
				exit 1
				;;
		esac
	done
}
