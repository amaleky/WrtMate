#!/bin/bash
# WrtMate Installation Script
# Automates OpenWrt setup and configuration
#
# Copyright (c) 2025 Alireza Maleky
# License: MIT
#
# Usage:
#   bash -c "$(wget -qO- https://raw.githubusercontent.com/amaleky/WrtMate/main/install.sh)"
#
# For more information, see the README.md

readonly REPO_URL="https://raw.githubusercontent.com/amaleky/WrtMate/main"
export REPO_URL

check_environment() {
  [ "$(id -u)" -eq 0 ] || error "This script must be run as root (use sudo)"
  [ -f "/etc/openwrt_release" ] || error "This script must be run on an OpenWrt system"
  check_min_requirements 500 100 2
}

install_dependencies() {
  update_package_lists
  ensure_packages "jq curl unzip"
}

show_menu() {
  local PS3="Enter your choice [1-8]: "
  local options=("Setup System" "Install AdGuard" "Configure Multi-WAN" "Install PassWall" "Configure USB" "Factory Reset" "Exit")

  select opt in "${options[@]}"; do
    case "$REPLY" in
    1) source <(wget -qO- "${REPO_URL}/scripts/setup.sh") ;;
    2) source <(wget -qO- "${REPO_URL}/scripts/adguard.sh") ;;
    3) source <(wget -qO- "${REPO_URL}/scripts/mwan.sh") ;;
    4) source <(wget -qO- "${REPO_URL}/scripts/passwall.sh") ;;
    5) source <(wget -qO- "${REPO_URL}/scripts/usb.sh") ;;
    6) source <(wget -qO- "${REPO_URL}/scripts/setup.sh") upgrade_firmware ;;
    7)
      success "Exiting WrtMate installer. Thank you for using WrtMate!"
      exit 0
      ;;
    *) warning "Invalid option $REPLY" ;;
    esac
    echo # Add a blank line for readability
    show_menu
  done
}

main() {
  source <(wget -qO- "${REPO_URL}/scripts/utils.sh")
  check_environment
  install_dependencies
  show_menu
}

main "$@"
