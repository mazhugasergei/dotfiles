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
  "adguardvpn-cli"
  "uv"
)

# Helper function to move cursor up one line and clear it
clear_previous_line() {
  echo -ne "\033[1A\033[K"
}

# Helper function for "Live-Stream & Rollback" installation pattern
install_with_rollback() {
  local package_name="$1"
  local install_cmd="$2"
  local custom_done="${3:-installed}"
  local line_count=0
  
  logger info "Installing $package_name..."
  [[ "$package_name" == "package list" ]] && { clear_previous_line; logger info "Updating $package_name..."; }
  
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
  
  if [ "$exit_code" -eq 0 ]; then
    for ((i=0; i<line_count; i++)); do
      clear_previous_line
    done
    logger done "$package_name $custom_done"
    rm -f "$exit_code_file" "$log_file"
    return 0
  else
    for ((i=0; i<line_count; i++)); do
      clear_previous_line
    done
    
    logger error "$package_name installation failed"
    cat "$log_file"
    
    rm -f "$exit_code_file" "$log_file"
    return 1
  fi
}

# Check package status
check_package_status() {
  unset to_install already_installed
  declare -gA to_install
  declare -gA already_installed

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
  logger info "Checking package status..."
  clear_previous_line
  logger done "package status check completed"
  echo ""

  declare -A table_titles
  table_titles["pkg"]="Package Name"
  table_titles["method"]="Method" 
  table_titles["status"]="Status"
  
  status_strings=("✓ Already installed" "○ To be installed")

  all_packages=("${!already_installed[@]}" "${!to_install[@]}" "${table_titles[pkg]}")
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

  for package in "${!already_installed[@]}"; do
    print_row "$package" "${already_installed[$package]}" "${status_strings[0]}" "\033[32m"
  done
  for package in "${!to_install[@]}"; do
    print_row "$package" "${to_install[$package]}" "${status_strings[1]}" ""
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

install_adguardvpn_cli() {
  install_with_rollback "adguardvpn-cli" "curl -fL https://raw.githubusercontent.com/AdguardTeam/AdGuardVPNCLI/master/scripts/release/install.sh | sh -s -- && adguardvpn-cli config set-change-system-dns on"
}

install_uv() {
  install_with_rollback "uv" "curl -fL https://astral.sh/uv/install.sh | sh"
}

install_custom_package() {
  case "$1" in
    "docker") install_docker ;;
    "node") install_node ;;
    "adguardvpn-cli") install_adguardvpn_cli ;;
    "uv") install_uv ;;
  esac
}

install_packages() {
  logger info "Installing missing packages..."
  local total_err=0
  local lines_to_clear=1 # Starts with 1 for the "Installing missing packages..." line

  for pkg in "${!to_install[@]}"; do
    if [ "${to_install[$pkg]}" == "apt" ]; then
      install_apt_package "$pkg" && ((lines_to_clear++)) || total_err=$((total_err + 1))
    else
      install_custom_package "$pkg" && ((lines_to_clear++)) || total_err=$((total_err + 1))
    fi
    
    # If a package failed, the logs remain on screen, so we don't clear those lines later.
    # However, 'lines_to_clear' only tracks successful DONE lines.
  done
  
  if [ "$total_err" -eq 0 ]; then
    # Wipe the "Installing missing packages..." line + all "DONE" lines
    for ((i=0; i<lines_to_clear; i++)); do
      clear_previous_line
    done
    logger done "All packages installed successfully"
    return 0
  else
    # If errors occurred, we keep the logs for context
    logger warn "$total_err package(s) failed to install"
    return 1
  fi
}

# MAIN ENTRY POINT
manage_packages() {
  [[ "$PACKAGES_MANAGED" == "true" ]] && return 0
  export PACKAGES_MANAGED="true"

  install_with_rollback "package list" "sudo apt-get update" "updated" || return 1
  
  check_package_status
  
  if [ ${#to_install[@]} -gt 0 ]; then
    display_package_table
    install_packages
  else
    logger done "All packages are already installed"
  fi

  echo ""
}

manage_packages