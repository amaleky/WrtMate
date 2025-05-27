#!/bin/bash
# WrtMate Installation Script
# Automates OpenWrt setup and configuration
#
# Copyright (c) 2025 Alireza Maleky
# License: MIT
#
# Usage:
#   bash -c "$(wget -cO- https://raw.githubusercontent.com/amaleky/WrtMate/main/install.sh)"
#
# For more information, see the README.md

set -euo pipefail

# Print a formatted message
info() {
  echo -e "\033[1;34m[INFO]\033[0m $1"
}

# Print an error message and exit
error_exit() {
  echo -e "\033[1;31m[ERROR]\033[0m $1" >&2
  exit 1
}

# Prepare environment and source common scripts
prepare() {
  opkg update || error_exit "Failed to update package lists."
  opkg install jq curl || error_exit "Failed to install required packages."
}

menu() {
  PS3="Enter Your Option: "
  OPTIONS=(
    "setup" "upgrade" "passwall" "mwan" "usbwan" "usbstorage" "adguard" "swap" "sqm" "irq" "quit"
  )
  select CHOICE in "${OPTIONS[@]}"; do
    info "Selected: $CHOICE"
    if [[ "$CHOICE" == "quit" ]]; then
      info "Exiting WrtMate installer."
      exit 0
    fi
    wget -qO "/tmp/${CHOICE}.sh" "https://raw.githubusercontent.com/amaleky/WrtMate/main/scripts/${CHOICE}.sh"
    chmod +x "/tmp/${CHOICE}.sh"
    "/tmp/${CHOICE}.sh"
    menu
  done
}

prepare
menu
