#!/bin/bash

prepare() {
  opkg update
  IPV4_DNS="208.67.222.2"
  IPV6_DNS="2620:0:ccc::2"
  REMOTE_DNS="208.67.220.2"
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
      opkg install jq curl
      . /etc/openwrt_release
      LATEST_VERSION=$(curl -s "https://downloads.openwrt.org/.versions.json" | jq -r ".stable_version")
      if [[ "$LATEST_VERSION" != "$DISTRIB_RELEASE" ]]; then
        read -r -p "Do You Want To Upgrade Firmware? (yes/No): " FIRMWARE_UPGRADE
        if [[ "$FIRMWARE_UPGRADE" == "yes" ]]; then
          DEVICE_ID=$(awk '{print tolower($0)}' /tmp/sysinfo/model | tr ' ' '_')
          FILE_NAME=$(curl -s "https://downloads.openwrt.org/releases/${LATEST_VERSION}/targets/${DISTRIB_TARGET}/profiles.json" | jq -r --arg id "$DEVICE_ID" '.profiles[$id].images | map(select(.type == "sysupgrade")) | sort_by((.name | contains("squashfs")) | not) | .[0].name')
          DOWNLOAD_URL="https://downloads.openwrt.org/releases/${LATEST_VERSION}/targets/${DISTRIB_TARGET}/${FILE_NAME}"
          wget -O /tmp/firmware.bin "${DOWNLOAD_URL}" && sysupgrade -n -v /tmp/firmware.bin
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
      opkg install openssh-sftp-server curl iperf3 htop nload
      ;;
    "Passwall")
      read -r -p "Do You Want To Install Hiddify? (Yes/no): " HIDDIFY_INSTALL
      read -r -p "Do You Want To Install WARP? (Yes/no): " WARP_INSTALL
      opkg remove dnsmasq
      opkg install dnsmasq-full kmod-nft-socket kmod-nft-tproxy curl unzip
      wget -O /tmp/packages.zip https://github.com/xiaorouji/openwrt-passwall2/releases/latest/download/passwall_packages_ipk_$(grep DISTRIB_ARCH /etc/openwrt_release | cut -d"'" -f2).zip
      unzip -o /tmp/packages.zip -d /tmp/passwall
      for pkg in /tmp/passwall/*.ipk; do opkg install "$pkg"; done
      wget -O /tmp/passwall2.ipk "$(curl -s "https://api.github.com/repos/xiaorouji/openwrt-passwall2/releases/latest" | grep "browser_download_url" | grep -o 'https://[^"]*luci-[^_]*_luci-app-passwall2_[^_]*_all\.ipk' | head -n1)"
      opkg install /tmp/passwall2.ipk
      cat << EOF > /etc/config/passwall2
config nodes 'Splitter'
	option remarks 'Splitter'
	option type 'Xray'
	option protocol '_shunt'
	option Block '_blackhole'
	option Sanction 'Hiddify'
	option Censor 'WarpPlus'
	option default_node '_direct'
	option domainStrategy 'IPOnDemand'
	option domainMatcher 'hybrid'
	option preproxy_enabled '0'

config nodes 'Hiddify'
	option remarks 'Hiddify'
	option type 'Xray'
	option protocol 'socks'
	option address '127.0.0.1'
	option port '12334'
	option tls '0'
	option transport 'raw'
	option tcp_guise 'none'
	option tcpMptcp '0'
	option tcpNoDelay '0'

config nodes 'WarpPlus'
	option remarks 'WarpPlus'
	option type 'Xray'
	option protocol 'socks'
	option address '127.0.0.1'
	option port '8086'
	option tls '0'
	option transport 'raw'
	option tcp_guise 'none'
	option tcpMptcp '0'
	option tcpNoDelay '0'

config nodes 'WarpPsiphon'
	option remarks 'WarpPsiphon'
	option type 'Xray'
	option protocol 'socks'
	option address '127.0.0.1'
	option port '8087'
	option tls '0'
	option transport 'raw'
	option tcp_guise 'none'
	option tcpMptcp '0'
	option tcpNoDelay '0'

config global
	option enabled '1'
	option node_socks_port '1070'
	option localhost_proxy '0'
	option client_proxy '1'
	option socks_enabled '0'
	option acl_enable '0'
	option node 'Splitter'
	option direct_dns_protocol 'auto'
	option direct_dns_query_strategy 'UseIP'
	option remote_dns_protocol 'tcp'
	option remote_dns "$REMOTE_DNS"
	option remote_dns_query_strategy 'UseIPv4'
	option dns_hosts 'cloudflare-dns.com 1.1.1.1
dns.google.com 8.8.8.8'
	option log_node '0'
	option loglevel 'error'
	option write_ipset_direct '1'
	option remote_dns_detour 'remote'
	option remote_fakedns '0'
	option dns_redirect '1'

config global_haproxy
	option balancing_enable '0'

config global_delay
	option start_daemon '1'
	option start_delay '10'

config global_forwarding
	option tcp_no_redir_ports 'disable'
	option udp_no_redir_ports 'disable'
	option tcp_redir_ports '22,25,53,143,465,587,853,993,995,80,443,9339'
	option udp_redir_ports '53'
	option accept_icmp '0'
	option use_nft '1'
	option tcp_proxy_way 'redirect'
	option ipv6_tproxy '0'

config global_xray
	option sniffing_override_dest '0'
	option fragment '0'
	option noise '0'

config global_other
	option auto_detection_time 'tcping'
	option show_node_info '1'

config global_rules
	option auto_update '0'
	option geosite_update '1'
	option geoip_update '1'
	option v2ray_location_asset '/usr/share/v2ray/'
	option enable_geoview '1'
	option geoip_url 'https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/geoip.dat'
	option geosite_url 'https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/geosite.dat'

config global_app
	option xray_file '/usr/bin/xray'
	option hysteria_file '/usr/bin/hysteria'
	option singbox_file '/usr/bin/sing-box'

config global_subscribe
	option filter_keyword_mode '1'
	option ss_type 'sing-box'
	option trojan_type 'sing-box'
	option vmess_type 'xray'
	option vless_type 'xray'
	option hysteria2_type 'hysteria2'

config global_singbox
	option sniff_override_destination '0'
	option geoip_path '/usr/share/singbox/geoip.db'
	option geoip_url 'https://cdn.jsdelivr.net/gh/chocolate4u/Iran-sing-box-rules@release/geoip.db'
	option geosite_path '/usr/share/singbox/geosite.db'
	option geosite_url 'https://cdn.jsdelivr.net/gh/chocolate4u/Iran-sing-box-rules@release/geosite.db'

config shunt_rules 'Block'
	option remarks 'Block'
	option network 'tcp,udp'
	option domain_list 'ext:geosite.dat:category-ads-all
ext:geosite.dat:malware
ext:geosite.dat:phishing
ext:geosite.dat:cryptominers
domain:googletagmanager.com
domain:webengage.com
domain:yandex.ru
domain:analytics.google.com
domain:bugsnag.com
domain:getsentry.com
domain:sentry-cdn.com
domain:doubleclick.net
domain:adservice.google.com
domain:analytics.pinterest.com'
	option ip_list 'ext:security-ip.dat:malware
ext:security-ip.dat:phishing'

config shunt_rules 'Sanction'
	option remarks 'Sanction'
	option network 'tcp,udp'
	option domain_list 'ext:geosite.dat:sanctioned
domain:io
domain:dev
domain:googleapis.com
domain:youtube.com
domain:googlevideo.com
domain:ggpht.com
domain:ytimg.com'
	option ip_list 'ext:geoip-services.dat:openai'

config shunt_rules 'Censor'
	option remarks 'Censor'
	option network 'tcp,udp'
	option domain_list 'ext:geosite.dat:nsfw
ext:geosite.dat:social
domain:v2ray.com
domain:hiddify.com
domain:leakfa.com
domain:radiojavan.com
domain:rjassets.com
domain:rjapp-content.app
domain:30nama.com
domain:digimoviez.com
domain:zarfilm.com'
	option ip_list 'ext:geoip-services.dat:netflix
ext:geoip-services.dat:telegram'
EOF

      if [ ! -f "/usr/share/v2ray/geo-update.sh" ]; then
        curl -L -o /tmp/geoip.dat https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/geoip.dat && mv /tmp/geoip.dat /usr/share/v2ray/geoip.dat
        cat << EOF > /usr/share/v2ray/geo-update.sh
curl -L -o /tmp/security-ip.dat https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/security-ip.dat && mv /tmp/security-ip.dat /usr/share/v2ray/security-ip.dat
curl -L -o /tmp/geoip-services.dat https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/geoip-services.dat && mv /tmp/geoip-services.dat /usr/share/v2ray/geoip-services.dat
curl -L -o /tmp/geosite.dat https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/geosite.dat && mv /tmp/geosite.dat /usr/share/v2ray/geosite.dat
EOF
        chmod +x /usr/share/v2ray/geo-update.sh
        echo "0 6 * * 0 /usr/share/v2ray/geo-update.sh" >> /etc/crontabs/root
        /usr/share/v2ray/geo-update.sh
      fi

      if [[ "$WARP_INSTALL" != "no" ]]; then
        opkg install unzip
        case "$(uname -m)" in
          x86_64)
            DETECTED_ARCH="amd64"
            ;;
          aarch64)
            DETECTED_ARCH="arm64"
            ;;
          armv7l|armv7)
            DETECTED_ARCH="arm7"
            ;;
          mips)
            DETECTED_ARCH="mips"
            ;;
          mipsel)
            DETECTED_ARCH="mipsle"
            ;;
          mips64)
            DETECTED_ARCH="mips64"
            ;;
          mips64el)
            DETECTED_ARCH="mips64le"
            ;;
          riscv64)
            DETECTED_ARCH="riscv64"
            ;;
          *)
            echo "Unsupported cpu architecture"
            exit 1
            ;;
        esac
        wget -O /tmp/warp.zip https://github.com/bepass-org/warp-plus/releases/latest/download/warp-plus_linux-$DETECTED_ARCH.zip
        unzip -o /tmp/warp.zip -d /tmp
        mv /tmp/warp-plus /usr/bin/warp-plus
        chmod +x /usr/bin/warp-plus

        cat << EOF > /etc/init.d/warp-plus
#!/bin/sh /etc/rc.common
START=91
USE_PROCD=1

start_service() {
    procd_open_instance
    procd_set_param command /usr/bin/warp-plus --scan --dns $IPV4_DNS --bind 0.0.0.0:8086
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_set_param respawn
    procd_close_instance
}
EOF
        chmod +x /etc/init.d/warp-plus

        cat << EOF > /etc/init.d/warp-psiphon
#!/bin/sh /etc/rc.common
START=91
USE_PROCD=1

start_service() {
    procd_open_instance
    procd_set_param command /usr/bin/warp-plus --scan --cfon --country GB --dns $IPV4_DNS --bind 0.0.0.0:8087
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_set_param respawn
    procd_close_instance
}
EOF
        chmod +x /etc/init.d/warp-psiphon

        cat << 'EOF' > /etc/hotplug.d/iface/99-warp
#!/bin/sh
[ "$INTERFACE" = "wan" ] || [ "$INTERFACE" = "wan6" ] || exit 0
/etc/init.d/warp-plus restart
/etc/init.d/warp-psiphon restart
EOF
        chmod +x /etc/hotplug.d/iface/99-warp

        /etc/init.d/warp-plus enable
        /etc/init.d/warp-plus restart
        /etc/init.d/warp-psiphon enable
        /etc/init.d/warp-psiphon restart
      fi

      if [[ "$HIDDIFY_INSTALL" != "no" ]]; then
        case "$(uname -m)" in
          i386|i686)
            DETECTED_ARCH="386"
            ;;
          x86_64)
            DETECTED_ARCH="amd64"
            ;;
          aarch64)
            DETECTED_ARCH="arm64"
            ;;
          armv5l)
            DETECTED_ARCH="armv5"
            ;;
          armv6l)
            DETECTED_ARCH="armv6"
            ;;
          armv7l|armv7)
            DETECTED_ARCH="armv7"
            ;;
          mips)
            DETECTED_ARCH="mips"
            ;;
          mipsel)
            DETECTED_ARCH="mipsel"
            ;;
          mips64)
            DETECTED_ARCH="mips64"
            ;;
          mips64el)
            DETECTED_ARCH="mips64el"
            ;;
          s390x)
            DETECTED_ARCH="s390x"
            ;;
          *)
            echo "Unsupported cpu architecture"
            exit 1
            ;;
        esac
        wget -O /tmp/hiddify.tar.gz https://github.com/hiddify/hiddify-core/releases/latest/download/hiddify-cli-linux-$DETECTED_ARCH.tar.gz
        tar -xvzf /tmp/hiddify.tar.gz -C /tmp
        mv /tmp/HiddifyCli /usr/bin/hiddify-cli
        chmod +x /usr/bin/hiddify-cli
        mkdir /root/hiddify/

        cat << EOF > /etc/init.d/hiddify-cli
#!/bin/sh /etc/rc.common
START=91
USE_PROCD=1

start_service() {
    procd_open_instance
    procd_set_param command /usr/bin/hiddify-cli run -c /root/hiddify/configs.conf -d /root/hiddify/settings.conf
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_set_param respawn
    procd_close_instance
}
EOF
        chmod +x /etc/init.d/hiddify-cli

        cat << 'EOF' > /etc/hotplug.d/iface/99-hiddify
#!/bin/sh
[ "$INTERFACE" = "wan" ] || [ "$INTERFACE" = "wan6" ] || exit 0
/etc/init.d/hiddify-cli restart
EOF
        chmod +x /etc/hotplug.d/iface/99-hiddify
        if [[ ! -e /root/hiddify/configs.conf ]]; then
          cat << EOF > /root/hiddify/configs.conf
socks://127.0.0.1:8087
EOF
        fi

        cat << EOF > /root/hiddify/settings.conf
{
  "region": "other",
  "block-ads": false,
  "use-xray-core-when-possible": false,
  "execute-config-as-is": false,
  "log-level": "warn",
  "resolve-destination": false,
  "ipv6-mode": "ipv4_only",
  "remote-dns-address": "udp://$REMOTE_DNS",
  "remote-dns-domain-strategy": "",
  "direct-dns-address": "$IPV4_DNS",
  "direct-dns-domain-strategy": "",
  "mixed-port": 12334,
  "tproxy-port": 12335,
  "local-dns-port": 16450,
  "tun-implementation": "gvisor",
  "mtu": 9000,
  "strict-route": true,
  "connection-test-url": "http://www.gstatic.com/generate_204",
  "url-test-interval": 300,
  "enable-clash-api": true,
  "clash-api-port": 16756,
  "enable-tun": false,
  "enable-tun-service": false,
  "set-system-proxy": false,
  "bypass-lan": true,
  "allow-connection-from-lan": true,
  "enable-fake-dns": false,
  "enable-dns-routing": true,
  "independent-dns-cache": true,
  "rules": [],
  "mux": { "enable": false, "padding": false, "max-streams": 8, "protocol": "h2mux" },
  "tls-tricks": { "enable-fragment": false, "fragment-size": "10-30", "fragment-sleep": "2-8", "mixed-sni-case": false, "enable-padding": false, "padding-size": "1-1500" },
  "warp": { "enable": false, "mode": "proxy_over_warp", "clean-ip": "auto", "clean-port": 0, "noise": "1-3", "noise-size": "10-30", "noise-delay": "10-30", "noise-mode": "m4" },
  "warp2": { "enable": false, "mode": "proxy_over_warp", "clean-ip": "auto", "clean-port": 0, "noise": "1-3", "noise-size": "10-30", "noise-delay": "10-30", "noise-mode": "m4" }
}
EOF

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
      opkg install kmod-usb-storage kmod-usb-storage-uas usbutils block-mount e2fsprogs kmod-fs-ext4
      mkfs.ext4 /dev/sda1
      block detect | uci import fstab
      uci set fstab.@mount[-1].enabled='1'
      uci set fstab.@global[0].check_fs='1'
      uci commit fstab
      /etc/init.d/fstab boot
      read -r -p "Do You Want To Extend Storage? (Yes/no): " EXTEND_STORAGE
      if [[ "$EXTEND_STORAGE" != "no" ]]; then
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
        reboot
      fi
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
