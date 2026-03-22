#!/bin/bash

# Sudo Privilege Utilities
# Provides functions for checking and verifying sudo access

# Check for sudo privileges and prompt if needed
# Usage: check_sudo_privileges
# Returns: 0 if sudo access is verified, 1 if authentication fails
check_sudo_privileges() {
	if ! sudo -n true 2>/dev/null; then
		sudo -v
		if [ $? -ne 0 ]; then
			return 1
		fi
	fi
	return 0
}
