#!/bin/bash
# AdGuard Home configuration for OpenWRT

install_adguard() {
  opkg install adguardhome || error "Failed to install AdGuard Home."
  /etc/init.d/adguardhome enable
  /etc/init.d/adguardhome restart
}

configure_dns_settings() {
  NET_ADDR=$(/sbin/ip -o -4 addr list br-lan | awk 'NR==1{ split($4, ip_addr, "/"); print ip_addr[1]; exit }')
  NET_ADDR6=$(/sbin/ip -o -6 addr list br-lan scope global | awk '$4 ~ /^fd|^fc/ { split($4, ip_addr, "/"); print ip_addr[1]; exit }')
  uci set dhcp.@dnsmasq[0].port="54"
  uci set dhcp.@dnsmasq[0].domain="lan"
  uci set dhcp.@dnsmasq[0].local="/lan/"
  uci set dhcp.@dnsmasq[0].expandhosts="1"
  uci set dhcp.@dnsmasq[0].cachesize="0"
  uci set dhcp.@dnsmasq[0].noresolv="1"
  uci -q del dhcp.@dnsmasq[0].server
  uci -q del dhcp.lan.dhcp_option
  uci -q del dhcp.lan.dns
  uci add_list dhcp.lan.dhcp_option='3,'"${NET_ADDR}"
  uci add_list dhcp.lan.dhcp_option='6,'"${NET_ADDR}"
  uci add_list dhcp.lan.dhcp_option='15,'"lan"
  uci add_list dhcp.lan.dns="$NET_ADDR6"
  uci commit dhcp
}

adguard() {
  install_adguard

  echo "Do You Want To Set AdGuard as Default DNS Server? (y/n)"
  read -r -e -i "n" SET_DEFAULT_DNS
  if [[ "$SET_DEFAULT_DNS" =~ ^[Yy] ]]; then
    configure_dns_settings
    /etc/init.d/dnsmasq restart
    /etc/init.d/odhcpd restart
  fi
}

adguard
