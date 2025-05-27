#!/bin/bash
# WrtMate Installation Script
# Automates OpenWrt setup and configuration
#
# Copyright (c) 2025 Alireza Maleky
# License: MIT
#
# Usage:
#   bash -c "$(wget -cO- https://cdn.jsdelivr.net/gh/amaleky/WrtMate@main/install.sh)"
#
# For more information, see the README.md

prepare() {
  opkg update
  opkg install jq curl
  IPV4_DNS="208.67.222.2"
  IPV6_DNS="2620:0:ccc::2"
  NTP_SERVER="216.239.35.0"
  LAN_IPADDR="$(uci get network.lan.ipaddr)"
}

run_commands() {
  echo "Step $1"
  case $1 in
    "Setup")
      read -r -p "Do You Want To Change Root Password? (yes/No): " CHANGE_PASSWORD
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

      read -r -p "Enter Your Router IP [$LAN_IPADDR]: " CUSTOM_LAN_IPADDR
      if [ -n "$CUSTOM_LAN_IPADDR" ]; then
        uci set network.lan.ipaddr="$CUSTOM_LAN_IPADDR"
        uci set network.lan.netmask='255.255.255.0'
        uci commit network
        /etc/init.d/network restart
      fi
      ;;
    "Upgrade")
      . /etc/openwrt_release
      LATEST_VERSION=$(curl -s "https://downloads.openwrt.org/.versions.json" | jq -r ".stable_version")
      if [[ "$LATEST_VERSION" != "$DISTRIB_RELEASE" ]]; then
        read -r -p "Do You Want To Upgrade Firmware? (yes/No): " FIRMWARE_UPGRADE
        if [[ "$FIRMWARE_UPGRADE" == "yes" ]]; then
          DEVICE_ID=$(awk '{print tolower($0)}' /tmp/sysinfo/model | tr ' ' '_')
          FILE_NAME=$(curl -s "https://downloads.openwrt.org/releases/${LATEST_VERSION}/targets/${DISTRIB_TARGET}/profiles.json" | jq -r --arg id "$DEVICE_ID" '.profiles[$id].images | map(select(.type == "sysupgrade")) | sort_by((.name | contains("squashfs")) | not) | .[0].name')
          DOWNLOAD_URL="https://downloads.openwrt.org/releases/${LATEST_VERSION}/targets/${DISTRIB_TARGET}/${FILE_NAME}"
          curl -L -o /tmp/firmware.bin "${DOWNLOAD_URL}" && sysupgrade -n -v /tmp/firmware.bin
        fi
      fi

      UPGRADABLE_PACKAGES=$(opkg list-upgradable | cut -f 1 -d ' ')
      if [ -n "$UPGRADABLE_PACKAGES" ]; then
        for PACKAGE in $UPGRADABLE_PACKAGES; do
          opkg upgrade "$PACKAGE"
        done
      fi
      ;;
    "Recommended")
      opkg install openssh-sftp-server iperf3 htop nload
      ;;
    "Passwall")
      read -r -p "Do You Want To Install Hiddify? (Yes/no): " HIDDIFY_INSTALL
      read -r -p "Do You Want To Install WARP? (Yes/no): " WARP_INSTALL
      opkg remove dnsmasq
      opkg install dnsmasq-full kmod-nft-socket kmod-nft-tproxy unzip
      curl -L -o /tmp/packages.zip "https://github.com/xiaorouji/openwrt-passwall2/releases/latest/download/passwall_packages_ipk_$(grep DISTRIB_ARCH /etc/openwrt_release | cut -d"'" -f2).zip"
      unzip -o /tmp/packages.zip -d /tmp/passwall
      for pkg in /tmp/passwall/*.ipk; do opkg install "$pkg"; done
      curl -L -o /tmp/passwall2.ipk "$(curl -s "https://api.github.com/repos/xiaorouji/openwrt-passwall2/releases/latest" | grep "browser_download_url" | grep -o 'https://[^"]*luci-[^_]*_luci-app-passwall2_[^_]*_all\.ipk' | head -n1)"
      opkg install /tmp/passwall2.ipk
      curl -L -o /etc/config/passwall2 "https://cdn.jsdelivr.net/gh/amaleky/WrtMate@main/src/etc/config/passwall2"

      if [ ! -f "/usr/share/v2ray/geo-update.sh" ]; then
        curl -L -o /usr/share/v2ray/geo-update.sh "https://cdn.jsdelivr.net/gh/amaleky/WrtMate@main/src/usr/share/v2ray/geo-update.sh"
        chmod +x /usr/share/v2ray/geo-update.sh
        /usr/share/v2ray/geo-update.sh
        curl -L -o /etc/crontabs/root "https://cdn.jsdelivr.net/gh/amaleky/WrtMate@main/src/etc/crontabs/root"
      fi

      if [[ "$WARP_INSTALL" != "no" ]]; then
        opkg install unzip
        case "$(uname -m)" in
          x86_64) DETECTED_ARCH=amd64 ;;
          aarch64) DETECTED_ARCH=arm64 ;;
          armv7l|armv7) DETECTED_ARCH=arm7 ;;
          mips) DETECTED_ARCH=mips ;;
          mipsel) DETECTED_ARCH=mipsle ;;
          mips64) DETECTED_ARCH=mips64 ;;
          mips64el) DETECTED_ARCH=mips64le ;;
          riscv64) DETECTED_ARCH=riscv64 ;;
          *) echo "Unsupported cpu architecture"; exit 1 ;;
        esac
        curl -L -o /tmp/warp.zip "https://github.com/bepass-org/warp-plus/releases/latest/download/warp-plus_linux-$DETECTED_ARCH.zip"
        unzip -o /tmp/warp.zip -d /tmp
        mv /tmp/warp-plus /usr/bin/warp-plus
        chmod +x /usr/bin/warp-plus

        curl -L -o /etc/init.d/warp-plus "https://cdn.jsdelivr.net/gh/amaleky/WrtMate@main/src/etc/init.d/warp-plus"
        chmod +x /etc/init.d/warp-plus

        curl -L -o /etc/init.d/warp-psiphon "https://cdn.jsdelivr.net/gh/amaleky/WrtMate@main/src/etc/init.d/warp-psiphon"
        chmod +x /etc/init.d/warp-psiphon

        curl -L -o /etc/hotplug.d/iface/99-warp "https://cdn.jsdelivr.net/gh/amaleky/WrtMate@main/src/etc/hotplug.d/iface/99-warp"
        chmod +x /etc/hotplug.d/iface/99-warp

        /etc/init.d/warp-plus enable
        /etc/init.d/warp-plus restart
        /etc/init.d/warp-psiphon enable
        /etc/init.d/warp-psiphon restart
      fi

      if [[ "$HIDDIFY_INSTALL" != "no" ]]; then
        arch=$(uname -m)
        case "$arch" in
          i386|i686) DETECTED_ARCH="386" ;;
          x86_64) DETECTED_ARCH="amd64" ;;
          aarch64) DETECTED_ARCH="arm64" ;;
          armv5l) DETECTED_ARCH="armv5" ;;
          armv6l) DETECTED_ARCH="armv6" ;;
          armv7l|armv7) DETECTED_ARCH="armv7" ;;
          mips*) DETECTED_ARCH="$arch" ;;
          s390x) DETECTED_ARCH="s390x" ;;
          *) echo "Unsupported cpu architecture"; exit 1 ;;
        esac
        curl -L -o /tmp/hiddify.tar.gz "https://github.com/hiddify/hiddify-core/releases/latest/download/hiddify-cli-linux-$DETECTED_ARCH.tar.gz"
        tar -xvzf /tmp/hiddify.tar.gz -C /tmp
        mv /tmp/HiddifyCli /usr/bin/hiddify-cli
        chmod +x /usr/bin/hiddify-cli
        mkdir /root/hiddify/

        curl -L -o /etc/init.d/hiddify-cli "https://cdn.jsdelivr.net/gh/amaleky/WrtMate@main/src/etc/init.d/hiddify-cli"
        chmod +x /etc/init.d/hiddify-cli

        curl -L -o /etc/hotplug.d/iface/99-hiddify "https://cdn.jsdelivr.net/gh/amaleky/WrtMate@main/src/etc/hotplug.d/iface/99-hiddify"
        chmod +x /etc/hotplug.d/iface/99-hiddify

        if [[ ! -e /root/hiddify/configs.conf ]]; then
          curl -L -o /root/hiddify/configs.conf "https://cdn.jsdelivr.net/gh/amaleky/WrtMate@main/src/root/hiddify/configs.conf"
        fi

        curl -L -o /root/hiddify/settings.conf "https://cdn.jsdelivr.net/gh/amaleky/WrtMate@main/src/root/hiddify/settings.conf"

        /etc/init.d/hiddify-cli enable
        /etc/init.d/hiddify-cli restart
      fi
      uci commit passwall2
      /etc/init.d/passwall2 restart
      ;;
    "Multi-WAN")
      read -r -p "Enter Your Second Interface: " SECOND_INTERFACE_NAME
      if [ -n "$SECOND_INTERFACE_NAME" ]; then
        read -r -p "Enter Second Interface PORT: " SECOND_INTERFACE_PORT
        if [ -n "$SECOND_INTERFACE_PORT" ]; then
          uci add_list firewall.@zone[-1].network="${SECOND_INTERFACE_NAME}"
          uci add_list firewall.@zone[-1].network="${SECOND_INTERFACE_NAME}6"
          uci commit firewall
          /etc/init.d/firewall restart
          uci set network.wan.metric='0'
          uci set network.wan6.metric='0'
          uci set network.@device[0].ports="$(uci get network.@device[0].ports | sed "s/\b$SECOND_INTERFACE_PORT\b//g" | tr -s ' ')"
          uci set network.${SECOND_INTERFACE_NAME}=interface
          uci set network.${SECOND_INTERFACE_NAME}.proto='dhcp'
          uci set network.${SECOND_INTERFACE_NAME}.device="$SECOND_INTERFACE_PORT"
          uci set network.globals.packet_steering='1'
          uci set network.${SECOND_INTERFACE_NAME}.metric='1'
          uci set network.${SECOND_INTERFACE_NAME}.peerdns='0'
          uci set network.${SECOND_INTERFACE_NAME}.dns="$IPV4_DNS"
          uci set network.${SECOND_INTERFACE_NAME}6=interface
          uci set network.${SECOND_INTERFACE_NAME}6.proto='dhcpv6'
          uci set network.${SECOND_INTERFACE_NAME}6.device="$SECOND_INTERFACE_PORT"
          uci set network.${SECOND_INTERFACE_NAME}6.reqaddress='try'
          uci set network.${SECOND_INTERFACE_NAME}6.reqprefix='auto'
          uci set network.${SECOND_INTERFACE_NAME}6.norelease='1'
          uci set network.${SECOND_INTERFACE_NAME}6.metric='1'
          uci set network.${SECOND_INTERFACE_NAME}6.peerdns='0'
          uci set network.${SECOND_INTERFACE_NAME}6.dns="$IPV6_DNS"
          uci commit network
          /etc/init.d/network restart
        fi
      fi
      read -r -p "Do You Need a Load Balancer? (yes/No): " INSTALL_LOAD_BALANCER
      if [[ "$INSTALL_LOAD_BALANCER" == "yes" ]]; then
        opkg install kmod-macvlan mwan3 luci-app-mwan3 iptables-nft ip6tables-nft
      fi
      ;;
    "USB-WAN")
      opkg install comgt-ncm kmod-usb-net-huawei-cdc-ncm usb-modeswitch kmod-usb-serial kmod-usb-serial-option kmod-usb-serial-wwan comgt-ncm luci-proto-3g luci-proto-ncm luci-proto-qmi kmod-usb-net-huawei-cdc-ncm usb-modeswitch
      ;;
    "USB-Storage")
      opkg install kmod-usb-storage kmod-usb-storage-uas usbutils block-mount e2fsprogs kmod-fs-ext4 libblkid kmod-fs-exfat exfat-fsck
      mkfs.ext4 /dev/sda1
      block detect | uci import fstab
      uci set fstab.@mount[-1].enabled='1'
      uci set fstab.@global[0].check_fs='1'
      uci commit fstab
      /etc/init.d/fstab boot
      read -r -p "Do You Want To Access USB Data Using SMB? (Yes/no): " SMB_CONFIG
      if [[ "$SMB_CONFIG" != "no" ]]; then
        opkg install luci-app-samba4
        uci add samba4 sambashare
        uci set samba4.@sambashare[-1].name='Share'
        uci set samba4.@sambashare[-1].path='/mnt/sda1'
        uci set samba4.@sambashare[-1].read_only='no'
        uci set samba4.@sambashare[-1].guest_ok='yes'
        uci set samba4.@sambashare[-1].create_mask='0666'
        uci set samba4.@sambashare[-1].dir_mask='0777'
        uci commit samba4
        /etc/init.d/samba4 restart
        chmod -R 777 /mnt/sda1
      fi
      read -r -p "Do You Want To Use USB as Router Storage? (yes/No): " EXTEND_STORAGE
      if [[ "$EXTEND_STORAGE" == "yes" ]]; then
        opkg install block-mount kmod-fs-ext4 e2fsprogs parted
        parted -s /dev/sda -- mklabel gpt mkpart extroot 2048s -2048s
        DEVICE="$(block info | sed -n -e '/MOUNT="\S*\/overlay"/s/:\s.*$//p')"
        uci -q delete fstab.rwm
        uci set fstab.rwm="mount"
        uci set fstab.rwm.device="${DEVICE}"
        uci set fstab.rwm.target="/rwm"
        uci commit fstab
        DEVICE="/dev/sda1"
        mkfs.ext4 -L extroot ${DEVICE}
        eval $(block info ${DEVICE} | grep -o -e 'UUID="\S*"')
        eval $(block info | grep -o -e 'MOUNT="\S*/overlay"')
        uci -q delete fstab.extroot
        uci set fstab.extroot="mount"
        uci set fstab.extroot.uuid="${UUID}"
        uci set fstab.extroot.target="${MOUNT}"
        uci commit fstab
        mount ${DEVICE} /mnt
        tar -C ${MOUNT} -cvf - . | tar -C /mnt -xf -
      fi
      reboot
      ;;
    "AdGuard")
      opkg install adguardhome
      /etc/init.d/adguardhome enable
      /etc/init.d/adguardhome restart
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
      /etc/init.d/dnsmasq restart
      /etc/init.d/odhcpd restart
      ;;
    "Swap")
      opkg install zram-swap
      ;;
    "SQM")
      opkg install luci-app-sqm
      ;;
    "IRQ")
      opkg install luci-app-irqbalance
      uci set irqbalance.irqbalance.enabled='1'
      uci commit irqbalance
      /etc/init.d/irqbalance enable
      /etc/init.d/irqbalance restart
      ;;
    *)
      exit 0
      ;;
  esac
  menu
}

menu() {
  PS3="Enter Your Option: "
  OPTIONS=(
    "Setup" "Upgrade" "Recommended" "Passwall" "Multi-WAN" "USB-WAN" "USB-Storage" "AdGuard" "Swap" "SQM" "IRQ" "Quit"
  )
  select CHOICE in "${OPTIONS[@]}"; do
    run_commands "$CHOICE"
  done
}

prepare
menu
