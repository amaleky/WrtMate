#!/bin/bash
# Setup function for OpenWRT

LAN_IPADDR="$(uci get network.lan.ipaddr 2>/dev/null || echo '192.168.1.1')"

check_firmware_version() {
  LATEST_VERSION=$(curl -s "https://downloads.openwrt.org/.versions.json" | jq -r ".stable_version") || error "Failed to fetch latest OpenWrt version."
  echo "$LATEST_VERSION"
}

upgrade_firmware() {
  read -r -p "Enter your router firmware upgrade file (sysupgrade.bin): " FIRMWARE_URL
  if [ -n "$FIRMWARE_URL" ]; then
    curl -s -L -o "/tmp/firmware.bin" "${FIRMWARE_URL}" || error "Failed to download firmware."
    sysupgrade -n -v /tmp/firmware.bin
  fi
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
      uci set wireless.@wifi-iface[$i].encryption='psk2'
    done
    uci commit wireless
    wifi reload
  fi
}

configure_dns() {
  INTERFACES=$(uci show network | grep "proto='dhcp'" | cut -d. -f2 | cut -d= -f1)
  if [ -n "$INTERFACES" ]; then
    for INTERFACE_V4 in $INTERFACES; do
      uci set network.${INTERFACE_V4}.peerdns='0'
      uci add_list network.${INTERFACE_V4}.dns='208.67.220.2'
    done
    uci commit network
  fi
}

install_recommended_packages() {
  ensure_packages "htop nload luci-app-irqbalance zram-swap openssh-sftp-server"
  uci set irqbalance.irqbalance.enabled='1'
  uci commit irqbalance
  /etc/init.d/irqbalance restart
}

remove_ipv6_interfaces() {
  INTERFACES=$(uci show network | grep "proto='dhcpv6'" | cut -d. -f2 | cut -d= -f1)
  if [ -n "$INTERFACES" ]; then
    for INTERFACE_V6 in $INTERFACES; do
      uci del "network.${INTERFACE_V6}"
    done
    uci commit network
  fi
}

configure_lan_ip() {
  echo "Enter Your Router IP [default: $LAN_IPADDR]: "
  read -r -e -i "$LAN_IPADDR" CUSTOM_LAN_IPADDR
  if [[ "$CUSTOM_LAN_IPADDR" != "$LAN_IPADDR" ]]; then
    uci set network.lan.ipaddr="$CUSTOM_LAN_IPADDR"
    uci set network.lan.netmask='255.255.255.0'
    uci commit network
  fi
}

main() {
  if [ -n "${1-}" ]; then
    "$1"
  else
    upgrade
    change_root_password
    configure_timezone
    configure_wifi
    configure_dns
    install_recommended_packages
    remove_ipv6_interfaces
    configure_lan_ip

    /etc/init.d/network reload
  fi

  success "Setup completed successfully"
}

main "$@"
