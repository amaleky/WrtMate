#!/bin/bash
# Multi-WAN configuration for OpenWRT

configure_firewall() {
  local interface_name="$1"
  info "Configuring firewall for interface: $interface_name"

  # Add IPv4 and IPv6 interfaces to firewall zone
  uci add_list firewall.@zone[-1].network="$interface_name"
  uci add_list firewall.@zone[-1].network="${interface_name}6"
  uci commit firewall

  /etc/init.d/firewall restart
  success "Firewall configured for interface: $interface_name"
}

configure_network_metrics() {
  local interface_port="$1"
  info "Configuring network metrics..."

  # Set primary WAN metrics
  uci set network.wan.metric='0'
  uci set network.wan6.metric='0'

  # Update device ports
  local current_ports
  current_ports=$(uci get network.@device[0].ports)
  local new_ports
  new_ports=$(echo "$current_ports" | sed "s/\b$interface_port\b//g" | tr -s ' ')
  uci set network.@device[0].ports="$new_ports"

  success "Network metrics configured"
}

configure_interface() {
  local name="$1"
  local port="$2"
  local ipv6="$3"
  info "Configuring ${ipv6:+IPv6 }interface: $name"

  local suffix="${ipv6:+6}"
  local proto="${ipv6:+dhcpv6}"
  proto="${proto:-dhcp}"

  # Common settings
  uci set "network.${name}${suffix}=interface"
  uci set "network.${name}${suffix}.proto=$proto"
  uci set "network.${name}${suffix}.device=$port"
  uci set "network.${name}${suffix}.metric=1"

  if [ -n "$ipv6" ]; then
    # IPv6-specific settings
    uci set "network.${name}${suffix}.reqaddress=try"
    uci set "network.${name}${suffix}.reqprefix=auto"
    uci set "network.${name}${suffix}.norelease=1"
  else
    # IPv4-specific settings
    uci set "network.globals.packet_steering=1"
  fi

  success "Interface ${name}${suffix} configured"
}

install_load_balancer() {
  ensure_packages "kmod-macvlan mwan3 luci-app-mwan3 iptables-nft ip6tables-nft"
}

validate_input() {
  local interface="$1"
  local port="$2"

  # Validate interface name format
  if ! [[ "$interface" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo error "Invalid interface name format. Use only letters, numbers, underscore, and hyphen"
  fi

  # Check if the port (network device) exists
  if [ ! -d "/sys/class/net/$port" ]; then
    error "Network port '$port' does not exist on this system"
  fi
}

configure_multiwan() {
  local interface_name="$1"
  local interface_port="$2"

  validate_input "$interface_name" "$interface_port"

  # Configure firewall
  configure_firewall "$interface_name"

  # Configure network settings
  configure_network_metrics "$interface_port"
  configure_interface "$interface_name" "$interface_port" # IPv4
  # configure_interface "$interface_name" "$interface_port" "ipv6" # IPv6

  # Apply changes
  uci commit network
  restart_network_services
}

main() {
  # Get interface details
  read -r -p "Enter second interface name: " interface_name
  read -r -p "Enter second interface port: " interface_port

  if [ -n "$interface_name" ] && [ -n "$interface_port" ]; then
    configure_multiwan "$interface_name" "$interface_port"
  fi

  if confirm "Do you want to install load balancer?"; then
    install_load_balancer
  fi

  success "Multi-WAN configuration completed successfully"
}

main "$@"
