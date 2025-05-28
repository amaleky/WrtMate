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

check_requirements() {
  # Check if running as root
  if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root (use sudo)"
  fi

  # Check if running on OpenWrt
  if [ ! -f "/etc/openwrt_release" ]; then
    error "This script must be run on an OpenWrt system."
  fi

  # Check RAM (500MB minimum)
  total_ram=$(($(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024)) # Convert to MB
  if [ "$total_ram" -lt 500 ]; then
    error "Insufficient RAM. Required: 500 MB, Available: ${total_ram} MB"
  fi

  # Check available storage (100MB minimum)
  available_space=$(($(df /overlay | awk 'NR==2 {print $4}') / 1024)) # Convert to MB
  if [ "$available_space" -lt 100 ]; then
    error "Insufficient storage space. Required: 100 MB, Available: ${available_space} MB"
  fi

  # Check CPU cores (minimum 2 cores)
  cpu_cores=$(grep -c processor /proc/cpuinfo)
  if [ "$cpu_cores" -lt 2 ]; then
    error "Insufficient CPU cores. Required: 2 cores, Available: ${cpu_cores} cores"
  fi

  info "System requirements check passed"
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

check_requirements
prepare
menu
