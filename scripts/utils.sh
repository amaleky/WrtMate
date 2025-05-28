#!/bin/bash
# Common utility functions used across scripts

# Colors for terminal output
readonly RED="\033[1;31m"
readonly GREEN="\033[1;32m"
readonly YELLOW="\033[1;33m"
readonly BLUE="\033[1;34m"
readonly NC="\033[0m" # No Color

info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
  exit 1
}

success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

is_package_installed() {
  opkg list-installed | grep "^$1[- ]"
}

ensure_packages() {
  local pkglist="$1"
  for pkgname in $pkglist; do
    if ! is_package_installed "$pkgname"; then
      info "Installing package: $pkgname"
      opkg install "$pkgname" || error "Failed to install $pkgname"
    fi
  done
}

confirm() {
  local prompt="$1"
  local default="${2:-n}"
  local options="[y/N]"
  [ "$default" = "y" ] && options="[Y/n]"

  read -r -p "$prompt $options: " response
  response="${response:-$default}"
  [[ "$response" =~ ^[Yy] ]]
}

update_package_lists() {
  local timestamp_file="/tmp/last_opkg_update"
  local update_interval=3600 # 1 hour in seconds

  # Check if timestamp file exists and is recent enough
  if [ -f "$timestamp_file" ]; then
    local last_update=$(cat "$timestamp_file")
    local current_time=$(date +%s)
    local time_diff=$((current_time - last_update))

    if [ $time_diff -lt $update_interval ]; then
      info "Package lists are up to date (last update was $(($time_diff / 60)) minutes ago)"
      return 0
    fi
  fi

  info "Updating package lists..."
  if opkg update; then
    date +%s >"$timestamp_file"
  else
    error "Failed to update package lists. Check internet connection."
  fi
}

restart_network_services() {
  info "Restarting network services..."
  /etc/init.d/network restart
  /etc/init.d/dnsmasq restart
  /etc/init.d/odhcpd restart
  success "Network services restarted successfully"
}

add_cron_job() {
  local cron_job="$1"
  if ! grep -qF "$cron_job" /etc/crontabs/root; then
    echo "$cron_job" >>/etc/crontabs/root
    /etc/init.d/cron restart
  fi
  /etc/init.d/cron enable
}

check_min_requirements() {
  local min_ram_mb="$1"
  local min_storage_mb="$2"
  local min_cores="$3"

  # Check RAM
  local total_ram=$(($(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024))
  if [ "$total_ram" -lt "$min_ram_mb" ]; then
    error "Insufficient RAM. Required: ${min_ram_mb}MB, Available: ${total_ram}MB"
  fi

  # Check storage
  local available_space=$(($(df /overlay | awk 'NR==2 {print $4}') / 1024))
  if [ "$available_space" -lt "$min_storage_mb" ]; then
    error "Insufficient storage. Required: ${min_storage_mb}MB, Available: ${available_space}MB"
  fi

  # Check CPU cores
  local cpu_cores=$(grep -c processor /proc/cpuinfo)
  if [ "$cpu_cores" -lt "$min_cores" ]; then
    error "Insufficient CPU cores. Required: $min_cores, Available: ${cpu_cores}"
  fi

  success "System requirements check passed"
}
