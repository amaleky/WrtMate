#!/bin/bash
# Setup function for WrtMate

# Global variables
IPV4_DNS="208.67.222.2"
IPV6_DNS="2620:0:ccc::2"
NTP_SERVER="216.239.35.0"
LAN_IPADDR="$(uci get network.lan.ipaddr 2>/dev/null || echo '192.168.1.1')"

setup() {
  echo "Do You Want To Change Root Password? (yes/no)"
  read -e -i "no" CHANGE_PASSWORD
  if [[ "$CHANGE_PASSWORD" == "yes" ]]; then
    passwd root
  fi

  if [ "$(uci get system.@system[0].timezone)" != "<+0330>-3:30" ]; then
    uci set system.@system[0].zonename='Asia/Tehran'
    uci set system.@system[0].timezone='<+0330>-3:30'
    uci set system.@system[0].hostname="$(awk '{print $1}' /tmp/sysinfo/model)"
    uci commit system
    /etc/init.d/system reload
  fi

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

  if [ "$(uci get dhcp.lan.dhcp_option)" != "6,${IPV4_DNS} 42,${NTP_SERVER}" ]; then
    uci set dhcp.lan.leasetime='12h'
    uci del dhcp.lan.dhcp_option
    uci add_list dhcp.lan.dhcp_option="6,${IPV4_DNS}"
    uci add_list dhcp.lan.dhcp_option="42,${NTP_SERVER}"
    uci commit dhcp
    /etc/init.d/dnsmasq restart
  fi

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

  echo "Enter Your Router IP [default: $LAN_IPADDR]: "
  read -e -i "$LAN_IPADDR" CUSTOM_LAN_IPADDR
  if [[ "$CUSTOM_LAN_IPADDR" != "$LAN_IPADDR" ]]; then
    uci set network.lan.ipaddr="$CUSTOM_LAN_IPADDR"
    uci set network.lan.netmask='255.255.255.0'
    uci commit network
    /etc/init.d/network restart
  fi

  CRONTAB_JOB="30 5 * * * sleep 70 && touch /etc/banner && reboot"
  if ! grep -qxF "$CRONTAB_JOB" /etc/crontabs/root; then
    echo "$CRONTAB_JOB" >> /etc/crontabs/root
  fi
}

recommended() {
  # Define packages and their display names
  declare -A PACKAGES=(
    ["openssh-sftp-server"]="SFTP server"
    ["iperf3"]="iperf3"
    ["htop"]="htop"
    ["nload"]="nload"
  )

  # Ask for each package installation
  for PKG in "${!PACKAGES[@]}"; do
    echo "Do you want to install ${PACKAGES[$PKG]}? (yes/no)"
    read -e -i "yes" INSTALL
    if [[ "$INSTALL" != "no" ]]; then
      opkg install "$PKG" || error_exit "Failed to install $PKG."
    fi
  done
}


setup
recommended