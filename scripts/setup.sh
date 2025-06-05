#!/bin/bash
# Setup function for OpenWRT

IPV4_DNS="94.140.15.15"
IPV6_DNS="2a10:50c0::ad2:ff"
LAN_IPADDR="$(uci get network.lan.ipaddr 2>/dev/null || echo '192.168.1.1')"

check_firmware_version() {
  LATEST_VERSION=$(curl -s "https://downloads.openwrt.org/.versions.json" | jq -r ".stable_version") || error "Failed to fetch latest OpenWrt version."
  echo "$LATEST_VERSION"
}

upgrade_firmware() {
  if ! confirm "Do you want to upgrade firmware?"; then
    return 0
  fi
  LATEST_VERSION=$(check_firmware_version)
  DEVICE_ID=$(awk '{print tolower($0)}' /tmp/sysinfo/model | tr ' ' '_')
  DIST_TARGET=$(grep DISTRIB_TARGET /etc/openwrt_release | cut -d"'" -f2)
  FILE_NAME=$(curl -s "https://downloads.openwrt.org/releases/${LATEST_VERSION}/targets/$DIST_TARGET/profiles.json" | jq -r --arg id "$DEVICE_ID" '.profiles[$id].images | map(select(.type == "sysupgrade")) | sort_by((.name | contains("squashfs")) | not) | .[0].name') || error "Failed to fetch device profile."
  DOWNLOAD_URL="https://downloads.openwrt.org/releases/${LATEST_VERSION}/targets/$DIST_TARGET/${FILE_NAME}"
  curl -L -o /tmp/firmware.bin "${DOWNLOAD_URL}" || error "Failed to download firmware."
  sysupgrade -n -v /tmp/firmware.bin
}

upgrade_packages() {
  UPGRADABLE_PACKAGES=$(opkg list-upgradable | cut -f 1 -d ' ')
  if [ -n "$UPGRADABLE_PACKAGES" ]; then
    if confirm "Do you want to upgrade packages?"; then
      for PACKAGE in $UPGRADABLE_PACKAGES; do
        opkg upgrade "$PACKAGE" || error "Failed to upgrade package $PACKAGE."
      done
    fi
  fi
}

upgrade() {
  LATEST_VERSION=$(check_firmware_version)
  DIST_RELEASE=$(grep DISTRIB_RELEASE /etc/openwrt_release | cut -d"'" -f2)

  if [[ "$LATEST_VERSION" != "$DIST_RELEASE" ]]; then
    upgrade_firmware
  fi

  upgrade_packages
}

change_root_password() {
  if confirm "Do you want to change root password?"; then
    passwd root
  fi
}

configure_timezone() {
  if [ "$(uci get system.@system[0].timezone)" != "<+0330>-3:30" ]; then
    uci set system.@system[0].zonename='Asia/Tehran'
    uci set system.@system[0].timezone='<+0330>-3:30'
    uci set system.@system[0].hostname="$(awk '{print $1}' /tmp/sysinfo/model)"
    uci commit system
    /etc/init.d/system reload
  fi
}

configure_network_dns() {
  for INTERFACE_V4 in $(uci show network | grep "proto='dhcp'" | cut -d. -f2 | cut -d= -f1); do
    uci set network.${INTERFACE_V4}.peerdns='0'
    uci set network.${INTERFACE_V4}.dns="$IPV4_DNS"
  done
  for INTERFACE_V6 in $(uci show network | grep "proto='dhcpv6'" | cut -d. -f2 | cut -d= -f1); do
    uci set network.${INTERFACE_V6}.peerdns='0'
    uci set network.${INTERFACE_V6}.dns="$IPV6_DNS"
  done
  uci commit network
  /etc/init.d/network reload
}

configure_wifi() {
  if uci get wireless >/dev/null 2>&1 && [ "$(uci get wireless.radio0.channel)" != "auto" ]; then
    read -r -p "Enter Your WIFI SSID: " WIFI_SSID
    read -r -p "Enter Your WIFI Password: " WIFI_PASSWORD
    for device in $(uci show wireless | grep device= | awk -F"'" '{print $2}'); do
      uci set wireless.${device}.disabled='0'
      wifi up ${device}
      uci set wireless.${device}.channel='auto'
    done
    for i in $(seq 0 $(($(uci show wireless | grep -c 'wifi-iface') - 1))); do
      uci set wireless.@wifi-iface[$i].ssid="$WIFI_SSID"
      uci set wireless.@wifi-iface[$i].key="$WIFI_PASSWORD"
      uci set wireless.@wifi-iface[$i].encryption='psk-mixed'
    done
    uci commit wireless
    wifi reload
  fi
}

configure_lan_ip() {
  echo "Enter Your Router IP [default: $LAN_IPADDR]: "
  read -r -e -i "$LAN_IPADDR" CUSTOM_LAN_IPADDR
  if [[ "$CUSTOM_LAN_IPADDR" != "$LAN_IPADDR" ]]; then
    uci set network.lan.ipaddr="$CUSTOM_LAN_IPADDR"
    uci set network.lan.netmask='255.255.255.0'
    uci commit network
    /etc/init.d/network reload
  fi
}

configure_auto_reboot() {
  add_cron_job "30 5 * * * sleep 70 && touch /etc/banner && reboot"
}

install_recommended_packages() {
  declare -A PACKAGE_DESCRIPTIONS=(
    ["htop"]="htop"
    ["nload"]="nload"
    ["luci-app-irqbalance"]="IRQ Balance"
    ["luci-app-sqm"]="Smart Queue Management (SQM)"
    ["zram-swap"]="ZRAM Swap"
  )

  local package_list=""
  for pkg in "${!PACKAGE_DESCRIPTIONS[@]}"; do
    if ! is_package_installed "$pkg"; then
      if confirm "Do you want to install ${PACKAGE_DESCRIPTIONS[$pkg]}?"; then
        ensure_packages "$pkg"
      fi
    fi
  done
}

main() {
  if [ -n "${1-}" ]; then
    "$1"
  else
    upgrade
    change_root_password
    configure_timezone
    configure_network_dns
    configure_wifi
    configure_lan_ip
    configure_auto_reboot
    install_recommended_packages
  fi

  success "Setup completed successfully"
}

main "$@"
