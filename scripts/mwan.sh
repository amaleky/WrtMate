#!/bin/bash
# Multi-WAN configuration for WrtMate

mwan() {
  read -r -p "Enter Your Second Interface: " SECOND_INTERFACE_NAME
  if [ -n "$SECOND_INTERFACE_NAME" ]; then
    read -r -p "Enter Second Interface PORT: " SECOND_INTERFACE_PORT
    if [ -n "$SECOND_INTERFACE_PORT" ]; then
      # Configure firewall
      uci add_list firewall.@zone[-1].network="${SECOND_INTERFACE_NAME}"
      uci add_list firewall.@zone[-1].network="${SECOND_INTERFACE_NAME}6"
      uci commit firewall
      /etc/init.d/firewall restart

      # Configure network metrics
      uci set network.wan.metric='0'
      uci set network.wan6.metric='0'
      uci set network.@device[0].ports="$(uci get network.@device[0].ports | sed "s/\b$SECOND_INTERFACE_PORT\b//g" | tr -s ' ')"

      # Configure second interface IPv4
      uci set network.${SECOND_INTERFACE_NAME}=interface
      uci set network.${SECOND_INTERFACE_NAME}.proto='dhcp'
      uci set network.${SECOND_INTERFACE_NAME}.device="$SECOND_INTERFACE_PORT"
      uci set network.globals.packet_steering='1'
      uci set network.${SECOND_INTERFACE_NAME}.metric='1'
      uci set network.${SECOND_INTERFACE_NAME}.peerdns='0'
      uci set network.${SECOND_INTERFACE_NAME}.dns="$(uci get network.wan.dns)"

      # Configure second interface IPv6
      uci set network.${SECOND_INTERFACE_NAME}6=interface
      uci set network.${SECOND_INTERFACE_NAME}6.proto='dhcpv6'
      uci set network.${SECOND_INTERFACE_NAME}6.device="$SECOND_INTERFACE_PORT"
      uci set network.${SECOND_INTERFACE_NAME}6.reqaddress='try'
      uci set network.${SECOND_INTERFACE_NAME}6.reqprefix='auto'
      uci set network.${SECOND_INTERFACE_NAME}6.norelease='1'
      uci set network.${SECOND_INTERFACE_NAME}6.metric='1'
      uci set network.${SECOND_INTERFACE_NAME}6.peerdns='0'
      uci set network.${SECOND_INTERFACE_NAME}6.dns="$(uci get network.wan6.dns)"

      uci commit network
      /etc/init.d/network restart
    fi
  fi

  # Install load balancer if needed
  echo "Do You Need a Load Balancer? (yes/no)"
  read -e -i "no" INSTALL_LOAD_BALANCER
  if [[ "$INSTALL_LOAD_BALANCER" == "yes" ]]; then
    opkg install kmod-macvlan mwan3 luci-app-mwan3 iptables-nft ip6tables-nft || error_exit "Failed to install load balancer packages."
  fi
}

mwan