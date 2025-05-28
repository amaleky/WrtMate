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

info() {
  echo -e "\033[1;34m[INFO]\033[0m $1"
}

warning() {
  echo -e "\033[1;33m[WARNING]\033[0m $1" >&2
}

error() {
  echo -e "\033[1;31m[ERROR]\033[0m $1" >&2
  exit 1
}

check_openwrt() {
  if [ ! -f "/etc/openwrt_release" ]; then
    error "This script must be run on an OpenWrt system."
  fi
}

prepare() {
  info "Preparing environment..."
  if ! opkg update; then
    error "Failed to update package lists. Please check your internet connection."
  fi
  if ! opkg install jq curl; then
    error "Failed to install required packages. Please check available storage space."
  fi
}

menu() {
  PS3="Enter Your Option: "
  OPTIONS=(
    "setup" "adguard" "mwan" "passwall" "usb" "quit"
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

check_openwrt
prepare
menu
