#!/bin/bash
# AdGuard Home configuration for OpenWRT

# AdGuard configuration constants
readonly ADGUARD_PORT=54
readonly ADGUARD_DOMAIN="lan"
readonly ADGUARD_LOCAL_ZONE="/lan/"
readonly ADGUARD_SERVICES=(
  "adguardhome"
  "dnsmasq"
  "odhcpd"
)

get_network_addresses() {
  local -n addr4_ref=$1
  local -n addr6_ref=$2

  addr4_ref=$(/sbin/ip -o -4 addr list br-lan | awk 'NR==1{ split($4, ip_addr, "/"); print ip_addr[1]; exit }')
  addr6_ref=$(/sbin/ip -o -6 addr list br-lan scope global | awk '$4 ~ /^fd|^fc/ { split($4, ip_addr, "/"); print ip_addr[1]; exit }')

  if [ -z "$addr4_ref" ]; then
    error "Failed to get IPv4 address for br-lan interface"
  fi
}

install_adguard() {
  ensure_packages "adguardhome"
  for service in "${ADGUARD_SERVICES[@]}"; do
    /etc/init.d/"$service" enable
  done
}

configure_dns_settings() {
  info "Configuring DNS settings..."
  local ipv4_addr ipv6_addr
  get_network_addresses ipv4_addr ipv6_addr

  # Configure dnsmasq
  local dnsmasq_config=(
    "port=$ADGUARD_PORT"
    "domain=$ADGUARD_DOMAIN"
    "local=$ADGUARD_LOCAL_ZONE"
    "expandhosts=1"
    "cachesize=0"
    "noresolv=1"
  )

  # Apply dnsmasq settings
  for setting in "${dnsmasq_config[@]}"; do
    local key="${setting%%=*}"
    local value="${setting#*=}"
    uci set "dhcp.@dnsmasq[0].$key=$value"
  done

  # Clear existing DNS settings
  uci -q del dhcp.@dnsmasq[0].server

  # Configure DHCP options
  uci set dhcp.lan.dhcp_option="3,$ipv4_addr 6,$ipv4_addr 15,lan"
  [ -n "$ipv6_addr" ] && uci set dhcp.lan.dns="$ipv6_addr"

  uci commit dhcp
  success "DNS settings configured successfully"
}

restart_services() {
  info "Restarting DNS services..."
  for service in "${ADGUARD_SERVICES[@]}"; do
    /etc/init.d/"$service" restart
  done
  success "DNS services restarted successfully"
}

main() {
  install_adguard

  if confirm "Do you want to set AdGuard as the default DNS server?"; then
    configure_dns_settings
    restart_services
  fi

  success "AdGuard Home setup completed successfully"
}

main "$@"
