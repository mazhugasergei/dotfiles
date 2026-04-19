#!/bin/bash

# Package Manager Utilities

# Package lists
apt_packages=(
  "fastfetch"
  "zsh"
  "wget"
  "curl"
  "ca-certificates"
  "stow"
  "git"
  "gh"
  "python3"
  "python3-pip"
)

non_apt_packages=(
  "docker"
  "node"
  "uv"
)

# Helper function to move cursor up one line and clear it
clear_previous_line() {
  echo -ne "\033[1A\033[K"
}

# Helper function to clear the entire table from the terminal
clear_table() {
  # The table has: 1 (check completed) + 1 (blank) + 3 (headers) + total pkgs + 1 (bottom border) + 1 (blank)
  local total_pkgs=$((${#already_installed[@]} + ${#to_install[@]} + ${#errored_installs[@]} + ${#just_installed[@]}))
  local lines_to_clear=$((total_pkgs + 7))
  for ((i=0; i<lines_to_clear; i++)); do
    clear_previous_line
  done
}

# Helper function for "Live-Stream & Rollback" installation pattern
install_with_rollback() {
  local package_name="$1"
  local install_cmd="$2"
  local line_count=0
  
  if [[ "$package_name" == "package list" ]]; then
    logger info "updating $package_name..."
  else
    logger info "installing $package_name..."
  fi
  
  line_count=1
  local exit_code_file=$(mktemp)
  local log_file=$(mktemp)

  while IFS= read -r line; do
    echo "$line"
    echo "$line" >> "$log_file"
    ((line_count++))
  done < <(eval "$install_cmd" 2>&1; echo $? > "$exit_code_file")

  local exit_code
  exit_code=$(cat "$exit_code_file")
  [[ -z "$exit_code" ]] && exit_code=1 
  
  # Rollback terminal output
  for ((i=0; i<line_count; i++)); do
    clear_previous_line
  done

  if [ "$exit_code" -eq 0 ]; then
    rm -f "$exit_code_file" "$log_file"
    return 0
  else
    logger error "$package_name installation failed"
    cat "$log_file"
    rm -f "$exit_code_file" "$log_file"
    return 1
  fi
}

# Check package status
check_package_status() {
  unset to_install already_installed errored_installs just_installed
  declare -gA to_install
  declare -gA already_installed
  declare -gA errored_installs
  declare -gA just_installed

  for package in "${apt_packages[@]}"; do
    if ! dpkg -l | grep -q "^ii  $package "; then
      to_install["$package"]="apt"
    else
      already_installed["$package"]="apt"
    fi
  done

  for package in "${non_apt_packages[@]}"; do
    if ! which "$package" &> /dev/null; then
      to_install["$package"]="custom"
    else
      already_installed["$package"]="custom"
    fi
  done
}

# Display package status table
display_package_table() {
  logger info "checking package status..."
  clear_previous_line
  logger done "package status check completed"
  echo ""

  declare -A table_titles
  table_titles["pkg"]="Package Name"
  table_titles["method"]="Method" 
  table_titles["status"]="Status"
  
  status_strings=("✓ Already installed" "○ To be installed" "✗ Errored" "✓ Just installed")

  all_packages=("${!already_installed[@]}" "${!to_install[@]}" "${!errored_installs[@]}" "${!just_installed[@]}" "${table_titles[pkg]}")
  max_pkg_length=0
  for p in "${all_packages[@]}"; do
    len=$(echo -n "$p" | wc -m)
    (( len > max_pkg_length )) && max_pkg_length=$len
  done

  max_method_length=7
  max_status_length=21

  print_row() {
    local col1="$1" col2="$2" col3="$3" color="$4"
    local col3_len=$(echo -n "$col3" | wc -m)
    local padding=$(printf '%*s' $((max_status_length - col3_len)) "")
    printf "│ %-${max_pkg_length}s │ %-${max_method_length}s │ %b%s%b%s │\n" \
      "$col1" "$col2" "$color" "$col3" "\033[0m" "$padding"
  }

  local line_pkg=$(printf '─%.0s' $(seq 1 $((max_pkg_length + 2))))
  local line_met=$(printf '─%.0s' $(seq 1 $((max_method_length + 2))))
  local line_sta=$(printf '─%.0s' $(seq 1 $((max_status_length + 2))))

  echo "┌${line_pkg}┬${line_met}┬${line_sta}┐"
  print_row "${table_titles[pkg]}" "${table_titles[method]}" "${table_titles[status]}" ""
  echo "├${line_pkg}┼${line_met}┼${line_sta}┤"

  # Sort by package name within groups for visual consistency
  for package in $(echo "${!already_installed[@]}" | tr ' ' '\n' | sort); do
    print_row "$package" "${already_installed[$package]}" "${status_strings[0]}" "\033[90m"
  done
  for package in $(echo "${!just_installed[@]}" | tr ' ' '\n' | sort); do
    print_row "$package" "${just_installed[$package]}" "${status_strings[3]}" "\033[32m"
  done
  for package in $(echo "${!to_install[@]}" | tr ' ' '\n' | sort); do
    print_row "$package" "${to_install[$package]}" "${status_strings[1]}" ""
  done
  for package in $(echo "${!errored_installs[@]}" | tr ' ' '\n' | sort); do
    print_row "$package" "${errored_installs[$package]}" "${status_strings[2]}" "\033[31m"
  done
  echo "└${line_pkg}┴${line_met}┴${line_sta}┘"
  echo ""
}

# --- INSTALLERS ---

install_apt_package() {
  install_with_rollback "$1" "sudo apt-get install -y $1"
}

install_docker() {
  install_with_rollback "docker" "curl -fL https://get.docker.com -o get-docker.sh && sh get-docker.sh && sudo usermod -aG docker $USER && rm -f get-docker.sh"
}

install_node() {
  local NODE_VERSION=${1:-"--lts"}
  if [ ! -d "$HOME/.nvm" ]; then
    install_with_rollback "NVM" "curl -fL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash" || return 1
  fi
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  
  local TARGET_VER=$NODE_VERSION
  [[ "$NODE_VERSION" == "--lts" ]] && TARGET_VER="lts/*"
  
  install_with_rollback "Node.js" "nvm install $NODE_VERSION && nvm use $TARGET_VER && nvm alias default $TARGET_VER"
}

install_uv() {
  install_with_rollback "uv" "curl -fL https://astral.sh/uv/install.sh | sh"
}

install_custom_package() {
  case "$1" in
    "docker") install_docker ;;
    "node") install_node ;;
    "uv") install_uv ;;
  esac
}

install_packages() {
  local total_err=0
  
  # Create a static list of keys to iterate over so we can modify the maps safely
  local pkgs_to_process=("${!to_install[@]}")

  for pkg in "${pkgs_to_process[@]}"; do
    local method="${to_install[$pkg]}"
    local success=1

    if [ "$method" == "apt" ]; then
      install_apt_package "$pkg" && success=0
    else
      install_custom_package "$pkg" && success=0
    fi
    
    # Logic to move the package between associative arrays
    if [ "$success" -eq 0 ]; then
      just_installed["$pkg"]="$method"
      unset to_install["$pkg"]
    else
      errored_installs["$pkg"]="$method"
      unset to_install["$pkg"]
      total_err=$((total_err + 1))
    fi

    # Redraw the table with updated statuses
    clear_table
    display_package_table
  done
  
  if [ "$total_err" -eq 0 ]; then
    logger done "all packages installed successfully"
    return 0
  else
    logger warn "$total_err package(s) failed to install"
    return 1
  fi
}

# MAIN ENTRY POINT
manage_packages() {
  [[ "$PACKAGES_MANAGED" == "true" ]] && return 0
  export PACKAGES_MANAGED="true"

  if install_with_rollback "package list" "sudo apt-get update"; then
     logger done "package list updated successfully"
  else
     return 1
  fi
  
  check_package_status
  
  if [ ${#to_install[@]} -gt 0 ]; then
    display_package_table
    install_packages
  else
    logger done "all packages are already installed"
  fi

  echo ""
}