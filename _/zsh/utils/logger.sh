#!/bin/bash

# Logger Utilities
# Provides colored logging functionality with dot notation methods

# Logger object with dot notation methods
# Usage: logger <method> <message>
# Methods: info, done, error, warn
logger() {
	local method="$1"
	local message="$2"
	
	case "$method" in
		"info")
			echo -e "\033[44m INFO \033[0m $message"
			;;
		"done")
			echo -e "\033[42m DONE \033[0m $message"
			;;
		"error")
			echo -e "\033[41m ERROR \033[0m $message"
			;;
		"warn")
			echo -e "\033[43m WARN \033[0m $message"
			;;
		*)
			echo "Unknown logger method: $method"
			return 1
			;;
	esac
}
