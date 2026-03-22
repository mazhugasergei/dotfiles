#!/bin/bash

# Command Line Argument Utilities
# Provides functions for parsing command line arguments and displaying help

# Print help message
# Usage: print_help
print_help() {
	echo "Usage: $0 [OPTIONS]"
	echo ""
	echo "OPTIONS:"
	echo "  -s, --skip         Skip the intro and outro typewriter effects"
	echo "      --skip-intro   Skip only the intro typewriter effects"
	echo "  -e, --errored      Force error condition for testing error outro"
	echo "  -h, --help         Show this help message"
	echo ""
	echo "Examples:"
	echo "  $0                   Run full installation with effects"
	echo "  $0 -s                Skip effects and go straight to installation"
	echo "  $0 --skip-intro      Skip intro but keep outro"
	echo "  $0 --errored         Test errored behaviour"
	echo "  $0 -e                Test errored behaviour (shorthand)"
	echo "  $0 -se               Skip effects and test errored behaviour"
	echo ""
}

# Parse command line arguments
# Usage: parse_arguments "$@"
# Sets global variables: SKIP, SKIP_INTRO, FORCE_ERROR, INSTALLATION_ERROR
parse_arguments() {
	# Initialize default values
	SKIP=false
	SKIP_INTRO=false
	FORCE_ERROR=false
	INSTALLATION_ERROR=false
	
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-s|--skip)
				SKIP=true
				shift
				;;
			--skip-intro)
				SKIP_INTRO=true
				shift
				;;
			-e|--errored)
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
						s)
							SKIP=true
							;;
						e)
							FORCE_ERROR=true
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
