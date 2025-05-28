#!/bin/bash
# Setup function for OpenWRT

IPV4_DNS="208.67.222.2"
IPV6_DNS="2620:0:ccc::2"
NTP_SERVER="216.239.35.0"
LAN_IPADDR="$(uci get network.lan.ipaddr 2>/dev/null || echo '192.168.1.1')"

check_firmware_version() {
  . /etc/openwrt_release
  LATEST_VERSION=$(curl -s "https://downloads.openwrt.org/.versions.json" | jq -r ".stable_version") || error "Failed to fetch latest OpenWrt version."
  echo "$LATEST_VERSION"
}

download_firmware() {
  local latest_version="$1"
  DEVICE_ID=$(awk '{print tolower($0)}' /tmp/sysinfo/model | tr ' ' '_')
  FILE_NAME=$(curl -s "https://downloads.openwrt.org/releases/${latest_version}/targets/${DISTRIB_TARGET}/profiles.json" | jq -r --arg id "$DEVICE_ID" '.profiles[$id].images | map(select(.type == "sysupgrade")) | sort_by((.name | contains("squashfs")) | not) | .[0].name') || error "Failed to fetch device profile."
  DOWNLOAD_URL="https://downloads.openwrt.org/releases/${latest_version}/targets/${DISTRIB_TARGET}/${FILE_NAME}"
  curl -L -o /tmp/firmware.bin "${DOWNLOAD_URL}" || error "Failed to download firmware."
}

upgrade_firmware() {
  sysupgrade -n -v /tmp/firmware.bin || error "Failed to upgrade firmware."
}

upgrade_packages() {
  UPGRADABLE_PACKAGES=$(opkg list-upgradable | cut -f 1 -d ' ')
  if [ -n "$UPGRADABLE_PACKAGES" ]; then
    for PACKAGE in $UPGRADABLE_PACKAGES; do
      opkg upgrade "$PACKAGE" || error "Failed to upgrade package $PACKAGE."
    done
  fi
}

upgrade() {
  . /etc/openwrt_release
  LATEST_VERSION=$(check_firmware_version)

  if [[ "$LATEST_VERSION" != "$DISTRIB_RELEASE" ]]; then
    echo "Do You Want To Upgrade Firmware? (y/n)"
    read -r -e -i "n" FIRMWARE_UPGRADE
    if [[ "$FIRMWARE_UPGRADE" =~ ^[Yy] ]]; then
      download_firmware "$LATEST_VERSION"
      upgrade_firmware
    fi
  fi

  echo "Do You Want To Upgrade Packages? (y/n)"
  read -r -e -i "n" FIRMWARE_UPGRADE
  if [[ "$FIRMWARE_UPGRADE" =~ ^[Yy] ]]; then
    upgrade_packages
  fi
}

change_root_password() {
  echo "Do You Want To Change Root Password? (y/n)"
  read -r -e -i "n" CHANGE_PASSWORD
  if [[ "$CHANGE_PASSWORD" =~ ^[Yy] ]]; then
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
  if [ "$(uci get network.lan.dns)" != "$IPV4_DNS" ]; then
    uci del network.lan.dns
    uci add_list network.lan.dns="$IPV4_DNS"
    for INTERFACE_V4 in $(uci show network | grep "proto='dhcp'" | cut -d. -f2 | cut -d= -f1); do
      uci set network.${INTERFACE_V4}.peerdns='0'
      uci set network.${INTERFACE_V4}.dns="$IPV4_DNS"
    done
    for INTERFACE_V6 in $(uci show network | grep "proto='dhcpv6'" | cut -d. -f2 | cut -d= -f1); do
      uci set network.${INTERFACE_V6}.peerdns='0'
      uci set network.${INTERFACE_V6}.dns="$IPV6_DNS"
    done
    uci commit network
    /etc/init.d/network restart
  fi
}

configure_dhcp() {
  if [ "$(uci get dhcp.lan.dhcp_option)" != "6,${IPV4_DNS} 42,${NTP_SERVER}" ]; then
    uci set dhcp.lan.leasetime='12h'
    uci del dhcp.lan.dhcp_option
    uci add_list dhcp.lan.dhcp_option="6,${IPV4_DNS}"
    uci add_list dhcp.lan.dhcp_option="42,${NTP_SERVER}"
    uci commit dhcp
    /etc/init.d/dnsmasq restart
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
    /etc/init.d/network restart
  fi
}

configure_crontab() {
  CRONTAB_JOB="30 5 * * * sleep 70 && touch /etc/banner && reboot"
  if ! grep -qxF "$CRONTAB_JOB" /etc/crontabs/root; then
    echo "$CRONTAB_JOB" >>/etc/crontabs/root
  fi
}

install_recommended_packages() {
  declare -A PACKAGES=(
    ["openssh-sftp-server"]="SFTP server"
    ["iperf3"]="iperf3"
    ["htop"]="htop"
    ["nload"]="nload"
    ["luci-app-irqbalance"]="IRQ Balance"
    ["luci-app-sqm"]="Smart Queue Management (SQM)"
    ["zram-swap"]="ZRAM Swap"
  )

  for PKG in "${!PACKAGES[@]}"; do
    echo "Do you want to install ${PACKAGES[$PKG]}? (y/n)"
    read -r INSTALL
    if [[ "$INSTALL" =~ ^[Yy] ]]; then
      opkg install "$PKG" || error "Failed to install $PKG."
    fi
  done
}

setup() {
  upgrade
  change_root_password
  configure_timezone
  configure_network_dns
  configure_dhcp
  configure_wifi
  configure_lan_ip
  configure_crontab
  install_recommended_packages
}

setup
