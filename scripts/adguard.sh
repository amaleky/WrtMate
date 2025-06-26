#!/bin/bash
# AdGuard Home configuration for OpenWRT

install_adguard() {
  ensure_packages "adguardhome"
}

configure_adguard() {
  NET_ADDR=$(/sbin/ip -o -4 addr list br-lan | awk 'NR==1{ split($4, ip_addr, "/"); print ip_addr[1]; exit }')
  NET_ADDR6=$(/sbin/ip -o -6 addr list br-lan scope global | awk '$4 ~ /^fd|^fc/ { split($4, ip_addr, "/"); print ip_addr[1]; exit }')

  # 1. Move dnsmasq to port 54.
  # 2. Set local domain to "lan".
  # 3. Add local '/lan/' to make sure all queries *.lan are resolved in dnsmasq;
  # 4. Add expandhosts '1' to make sure non-expanded hosts are expanded to ".lan";
  # 5. Disable dnsmasq cache size as it will only provide PTR/rDNS info, making sure queries are always up to date (even if a device internal IP change after a DHCP lease renew).
  # 6. Disable reading /tmp/resolv.conf.d/resolv.conf.auto file (which are your ISP nameservers by default), you don't want to leak any queries to your ISP.
  # 7. Delete all forwarding servers from dnsmasq config.
  uci set dhcp.@dnsmasq[0].port="54"
  uci set dhcp.@dnsmasq[0].domain="lan"
  uci set dhcp.@dnsmasq[0].local="/lan/"
  uci set dhcp.@dnsmasq[0].expandhosts="1"
  uci set dhcp.@dnsmasq[0].cachesize="0"
  uci set dhcp.@dnsmasq[0].noresolv="1"
  uci -q del dhcp.@dnsmasq[0].server

  # Delete existing config ready to install new options.
  uci -q del dhcp.lan.dhcp_option
  uci -q del dhcp.lan.dns

  # DHCP option 3: Specifies the gateway the DHCP server should send to DHCP clients.
  uci add_list dhcp.lan.dhcp_option='3,'"${NET_ADDR}"

  # DHCP option 6: Specifies the DNS server the DHCP server should send to DHCP clients.
  uci add_list dhcp.lan.dhcp_option='6,'"${NET_ADDR}"

  # DHCP option 15: Specifies the domain suffix the DHCP server should send to DHCP clients.
  uci add_list dhcp.lan.dhcp_option='15,'"lan"

  # Set IPv6 Announced DNS
  uci add_list dhcp.lan.dns="$NET_ADDR6"

  uci commit dhcp
  /etc/init.d/adguardhome enable
  /etc/init.d/adguardhome restart
  /etc/init.d/dnsmasq restart
  /etc/init.d/odhcpd restart
}

main() {
  install_adguard
  configure_adguard

  success "AdGuard Home setup completed successfully"
}

main "$@"
