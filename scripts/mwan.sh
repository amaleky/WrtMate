#!/bin/bash
# Multi-WAN configuration for OpenWRT

configure_firewall() {
  local interface_name="$1"
  uci add_list firewall.@zone[-1].network="${interface_name}"
  uci add_list firewall.@zone[-1].network="${interface_name}6"
  uci commit firewall
  /etc/init.d/firewall restart
}

configure_network_metrics() {
  local interface_port="$1"
  uci set network.wan.metric='0'
  uci set network.wan6.metric='0'
  uci set network.@device[0].ports="$(uci get network.@device[0].ports | sed "s/\b$interface_port\b//g" | tr -s ' ')"
}

configure_ipv4_interface() {
  local interface_name="$1"
  local interface_port="$2"

  uci set network.${interface_name}=interface
  uci set network.${interface_name}.proto='dhcp'
  uci set network.${interface_name}.device="$interface_port"
  uci set network.globals.packet_steering='1'
  uci set network.${interface_name}.metric='1'
  uci set network.${interface_name}.peerdns='0'
  uci set network.${interface_name}.dns="$(uci get network.wan.dns)"
}

configure_ipv6_interface() {
  local interface_name="$1"
  local interface_port="$2"

  uci set network.${interface_name}6=interface
  uci set network.${interface_name}6.proto='dhcpv6'
  uci set network.${interface_name}6.device="$interface_port"
  uci set network.${interface_name}6.reqaddress='try'
  uci set network.${interface_name}6.reqprefix='auto'
  uci set network.${interface_name}6.norelease='1'
  uci set network.${interface_name}6.metric='1'
  uci set network.${interface_name}6.peerdns='0'
  uci set network.${interface_name}6.dns="$(uci get network.wan6.dns)"
}

install_load_balancer() {
  opkg install kmod-macvlan mwan3 luci-app-mwan3 iptables-nft ip6tables-nft || error "Failed to install load balancer packages."
}

mwan() {
  read -r -p "Enter Your Second Interface: " SECOND_INTERFACE_NAME
  if [ -n "$SECOND_INTERFACE_NAME" ]; then
    read -r -p "Enter Second Interface PORT: " SECOND_INTERFACE_PORT
    if [ -n "$SECOND_INTERFACE_PORT" ]; then
      configure_firewall "$SECOND_INTERFACE_NAME"
      configure_network_metrics "$SECOND_INTERFACE_PORT"
      configure_ipv4_interface "$SECOND_INTERFACE_NAME" "$SECOND_INTERFACE_PORT"
      configure_ipv6_interface "$SECOND_INTERFACE_NAME" "$SECOND_INTERFACE_PORT"

      uci commit network
      /etc/init.d/network restart
    fi
  fi

  echo "Do You Need a Load Balancer? (y/n)"
  read -r -e -i "n" INSTALL_LOAD_BALANCER
  if [[ "$INSTALL_LOAD_BALANCER" =~ ^[Yy] ]]; then
    install_load_balancer
  fi
}

mwan
