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

menu() {
  local PS3="Enter your choice [1-8]: "
  local options=("Setup System" "Configure Multi-WAN" "Install PassWall" "Install AdGuard" "Configure USB" "Factory Reset" "Exit")

  select opt in "${options[@]}"; do
    case "$REPLY" in
    1) source <(wget -qO- "${REPO_URL}/scripts/setup.sh") ;;
    2) source <(wget -qO- "${REPO_URL}/scripts/mwan.sh") ;;
    3) source <(wget -qO- "${REPO_URL}/scripts/passwall.sh") ;;
    4) source <(wget -qO- "${REPO_URL}/scripts/adguard.sh") ;;
    5) source <(wget -qO- "${REPO_URL}/scripts/usb.sh") ;;
    6) source <(wget -qO- "${REPO_URL}/scripts/setup.sh") upgrade_firmware ;;
    7)
      success "Exiting WrtMate installer. Thank you for using WrtMate!"
      exit 0
      ;;
    *) warning "Invalid option $REPLY" ;;
    esac
    echo # Add a blank line for readability
    menu
  done
}

source <(wget -qO- "${REPO_URL}/scripts/utils.sh")
menu "$@"
