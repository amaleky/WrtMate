#!/bin/bash
# Passwall configuration for OpenWRT

MIN_RAM_MB=400
TOTAL_RAM=$(($(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024))

if [ ! -d /root/scripts/ ]; then mkdir /root/scripts/; fi

hiddify() {
  info "hiddify"

  REMOTE_VERSION="$(curl -s "https://api.github.com/repos/hiddify/hiddify-core/releases/latest" | jq -r '.tag_name')"
  LOCAL_VERSION="$(cat "/root/.hiddify_version" 2>/dev/null || echo 'none')"

  if [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]; then
    source <(wget -qO- "${REPO_URL}/scripts/packages/hiddify.sh")
    if [ -n "$REMOTE_VERSION" ]; then
      echo "$REMOTE_VERSION" >"/root/.hiddify_version"
    fi
  fi
}

balancer() {
  info "balancer"
  if [ ! -d /root/balancer/ ]; then mkdir /root/balancer/; fi

  if [[ -f "/root/balancer/run.sh" ]]; then
    SUBSCRIPTION_URL=$(grep -E "^SUBSCRIPTION_URL=" "/root/balancer/run.sh" | cut -d'=' -f2-)
  fi

  if [[ -f "/etc/init.d/balancer" ]] && /etc/init.d/balancer running; then
    /etc/init.d/balancer stop
  fi

  curl -s -L -o "/etc/init.d/balancer" "${REPO_URL}/src/etc/init.d/balancer" || error "Failed to download balancer init script."
  chmod +x /etc/init.d/balancer

  curl -s -L -o "/root/balancer/run.sh" "${REPO_URL}/src/root/balancer/run.sh" || error "Failed to download balancer run.sh configs."
  chmod +x /root/balancer/run.sh

  if [ -z "$SUBSCRIPTION_URL" ] || [ "$SUBSCRIPTION_URL" = '""' ]; then
    read -r -p "Enter Your Sing-Box Subscription: " SUBSCRIPTION_URL
  fi
  if [ -n "$SUBSCRIPTION_URL" ]; then
    sed -i "s|^SUBSCRIPTION_URL=.*|SUBSCRIPTION_URL=${SUBSCRIPTION_URL}|" "/root/balancer/run.sh"
    /etc/init.d/balancer enable
    /etc/init.d/balancer start
  fi
}

ghost() {
  info "ghost"

  curl -s -L -o "/root/scripts/scanner.sh" "${REPO_URL}/src/root/scripts/scanner.sh" || error "Failed to download scanner.sh."
  chmod +x /root/scripts/scanner.sh

  if [[ -f "/etc/init.d/scanner" ]] && /etc/init.d/scanner running; then
    /etc/init.d/scanner stop
  fi

  curl -s -L -o "/etc/init.d/scanner" "${REPO_URL}/src/etc/init.d/scanner" || error "Failed to download scanner init script."
  chmod +x /etc/init.d/scanner

  /etc/init.d/scanner disable

  if [ "$TOTAL_RAM" -ge "$MIN_RAM_MB" ]; then
    if [ ! -f "/root/ghost/configs.conf" ] || [ "$(wc -l <"/root/ghost/configs.conf")" -eq 0 ]; then
      /etc/init.d/scanner start
    fi
  fi

  add_cron_job "0 * * * * /etc/init.d/scanner start"

  if [ ! -d /root/ghost/ ]; then mkdir /root/ghost/; fi

  if [[ ! -f "/root/ghost/configs.conf" ]]; then
    curl -s -L -o "/root/ghost/configs.conf" "${REPO_URL}/src/root/ghost/configs.conf" || error "Failed to download ghost configs."
  fi

  if [[ -f "/etc/init.d/ghost" ]] && /etc/init.d/ghost running; then
    /etc/init.d/ghost stop
  fi

  curl -s -L -o "/etc/init.d/ghost" "${REPO_URL}/src/etc/init.d/ghost" || error "Failed to download ghost init script."
  chmod +x /etc/init.d/ghost

  curl -s -L -o "/root/ghost/run.sh" "${REPO_URL}/src/root/ghost/run.sh" || error "Failed to download ghost run.sh configs."
  chmod +x /root/ghost/run.sh

  curl -s -L -o "/root/scripts/logwatch.sh" "${REPO_URL}/src/root/scripts/logwatch.sh" || error "Failed to download logwatch.sh."
  chmod +x /root/scripts/logwatch.sh
  curl -s -L -o "/etc/init.d/logwatch" "${REPO_URL}/src/etc/init.d/logwatch" || error "Failed to download logwatch init script."
  chmod +x /etc/init.d/logwatch

  /etc/init.d/logwatch enable
  /etc/init.d/logwatch start
  /etc/init.d/ghost enable
  /etc/init.d/ghost start
}

warp() {
  info "warp"

  REMOTE_VERSION="$(curl -s "https://api.github.com/repos/bepass-org/warp-plus/releases/latest" | jq -r '.tag_name')"
  LOCAL_VERSION="$(cat "/root/.vwarp_version" 2>/dev/null || echo 'none')"

  if [[ -f "/etc/init.d/warp-plus" ]] && /etc/init.d/warp-plus running; then
    /etc/init.d/warp-plus stop
  fi

  if [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]; then
    source <(wget -qO- "${REPO_URL}/scripts/packages/warp.sh")
    if [ -n "$REMOTE_VERSION" ]; then
      echo "$REMOTE_VERSION" >"/root/.vwarp_version"
    fi
  fi

  curl -s -L -o "/etc/init.d/warp-plus" "${REPO_URL}/src/etc/init.d/warp-plus" || error "Failed to download warp-plus init script."
  chmod +x /etc/init.d/warp-plus

  if [ "$TOTAL_RAM" -ge "$MIN_RAM_MB" ]; then
    /etc/init.d/warp-plus enable
    /etc/init.d/warp-plus start
  fi
}

psiphon() {
  info "psiphon"
  if [ ! -d /root/psiphon/ ]; then mkdir /root/psiphon/; fi

  REMOTE_VERSION="$(curl -s "https://api.github.com/amaleky/WrtMate/releases/latest" | jq -r '.tag_name')"
  LOCAL_VERSION="$(cat "/root/.psiphon_version" 2>/dev/null || echo 'none')"

  if [[ -f "/etc/init.d/psiphon" ]] && /etc/init.d/psiphon running; then
    /etc/init.d/psiphon stop
  fi

  if [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]; then
    source <(wget -qO- "${REPO_URL}/scripts/packages/psiphon.sh")
    if [ -n "$REMOTE_VERSION" ]; then
      echo "$REMOTE_VERSION" >"/root/.psiphon_version"
    fi
  fi

  curl -s -L -o "/etc/init.d/psiphon" "${REPO_URL}/src/etc/init.d/psiphon" || error "Failed to download psiphon init script."
  chmod +x /etc/init.d/psiphon

  curl -s -L -o "/root/psiphon/client.config" "https://raw.githubusercontent.com/amaleky/WrtMate/main/src/root/psiphon/client.config" || error "Failed to download psiphon configs."

  if [ "$TOTAL_RAM" -ge "$MIN_RAM_MB" ]; then
    /etc/init.d/psiphon enable
    /etc/init.d/psiphon start
  fi
}

tor() {
  info "tor"

  ensure_packages "tor tor-geoip obfs4proxy"

  grep '^Bridge' /etc/tor/torrc >/etc/tor/torrc.back
  curl -s -L -o "/etc/tor/torrc" "${REPO_URL}/src/etc/tor/torrc" || error "Failed to download tor config."
  cat /etc/tor/torrc.back >>/etc/tor/torrc

  if ! grep -q '^Bridge' /etc/tor/torrc; then
    echo "Please paste your Bridges from https://bridges.torproject.org/bridges?transport=obfs4 (press Ctrl+D when done):"
    {
      awk 'NF { if ($1 != "Bridge") print "Bridge", $0; else print $0 }'
    } >>/etc/tor/torrc
  fi

  if [ "$TOTAL_RAM" -ge "$MIN_RAM_MB" ]; then
    /etc/init.d/tor enable
    /etc/init.d/tor start
  fi
}

ssh_proxy() {
  info "ssh_proxy"
  if [ ! -d /root/.ssh/ ]; then mkdir /root/.ssh/; fi
  ensure_packages "openssh-client"

  if [ -f "/etc/init.d/ssh-proxy" ]; then
    SSH_HOST=$(grep -E "^SSH_HOST=" "/etc/init.d/ssh-proxy" | cut -d'=' -f2-)
    SSH_PORT=$(grep -E "^SSH_PORT=" "/etc/init.d/ssh-proxy" | cut -d'=' -f2-)
  fi

  if [ -z "$SSH_HOST" ] || [ "$SSH_HOST" = '""' ]; then
    read -r -p "Enter SSH hostname: " SSH_HOST
  fi
  if [ -z "$SSH_PORT" ] || [ "$SSH_PORT" = '""' ]; then
    read -r -p "Enter SSH port: " SSH_PORT
  fi

  if [[ -f "/etc/init.d/ssh-proxy" ]] && /etc/init.d/ssh-proxy running; then
    /etc/init.d/ssh-proxy stop
  fi

  curl -s -L -o "/etc/init.d/ssh-proxy" "${REPO_URL}/src/etc/init.d/ssh-proxy" || error "Failed to download ssh-proxy init script."
  chmod +x "/etc/init.d/ssh-proxy"

  if [[ ! -f "/root/.ssh/id_rsa" ]]; then
    info "Please paste your SSH private key (press Ctrl+D when done):"
    cat >"/root/.ssh/id_rsa"
    chmod 600 "/root/.ssh/id_rsa"
  fi

  if [ -n "$SSH_HOST" ]; then
    sed -i "s|^SSH_HOST=.*|SSH_HOST=${SSH_HOST}|" "/etc/init.d/ssh-proxy"
    if [ -n "$SSH_PORT" ]; then
      sed -i "s|^SSH_PORT=.*|SSH_PORT=${SSH_PORT}|" "/etc/init.d/ssh-proxy"
      if [[ -f "/root/.ssh/id_rsa" ]]; then
        /etc/init.d/ssh-proxy enable
        /etc/init.d/ssh-proxy start
      fi
    fi
  fi
}

server_less() {
  info "server_less"
  if [ ! -d /root/xray/ ]; then mkdir /root/xray/; fi

  if [[ -f "/etc/init.d/serverless" ]] && /etc/init.d/serverless running; then
    /etc/init.d/ssh-proxy stop
  fi

  curl -s -L -o "/etc/init.d/serverless" "${REPO_URL}/src/etc/init.d/serverless" || error "Failed to download serverless init script."
  chmod +x /etc/init.d/serverless

  curl -s -L -o "/root/xray/subscription.json" "https://raw.githubusercontent.com/voidr3aper-anon/GFW-slayer/main/configs/general/V-force.json" || error "Failed to download ServerLess configs list."

  if [ "$TOTAL_RAM" -ge "$MIN_RAM_MB" ]; then
    /etc/init.d/serverless enable
    /etc/init.d/serverless start
  fi
}

url_test() {
  info "url_test"
  curl -s -L -o "/root/scripts/url-test.sh" "${REPO_URL}/src/root/scripts/url-test.sh" || error "Failed to download url-test.sh."
  chmod +x /root/scripts/url-test.sh
  add_cron_job "*/5 * * * * /root/scripts/url-test.sh"

  curl -s -L -o "/etc/hotplug.d/iface/99-url-test" "${REPO_URL}/src/etc/hotplug.d/iface/99-url-test" || error "Failed to download 99-url-test hotplug script."
  chmod +x /etc/hotplug.d/iface/99-url-test
}

geo_update() {
  info "geo_update"
  curl -s -L -o "/root/scripts/geo-update.sh" "${REPO_URL}/src/root/scripts/geo-update.sh" || error "Failed to download geo-update.sh."
  chmod +x /root/scripts/geo-update.sh
  add_cron_job "0 6 * * 0 /root/scripts/geo-update.sh"
  /root/scripts/geo-update.sh
}

passwall() {
  info "passwall"
  LATEST_TAG="$(curl -s "https://api.github.com/repos/xiaorouji/openwrt-passwall2/releases/latest")"
  REMOTE_VERSION="$(echo "$LATEST_TAG" | jq -r '.tag_name')"
  LOCAL_VERSION="$(cat "/root/.passwall2_version" 2>/dev/null || echo 'none')"

  if [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]; then
    opkg remove dnsmasq
    ensure_packages "dnsmasq-full kmod-nft-socket kmod-nft-tproxy binutils"

    curl -s -L -o "/tmp/packages.zip" "https://github.com/xiaorouji/openwrt-passwall2/releases/latest/download/passwall_packages_ipk_$(grep DISTRIB_ARCH /etc/openwrt_release | cut -d"'" -f2).zip" || error "Failed to download Passwall packages."
    unzip -o /tmp/packages.zip -d /tmp/passwall >/dev/null 2>&1
    for pkg in /tmp/passwall/*.ipk; do opkg install "$pkg"; done

    curl -s -L -o "/tmp/passwall2.ipk" "$(echo "$LATEST_TAG" | jq -r '.assets[].browser_download_url | select(contains("luci-app-passwall2_") and endswith("_all.ipk"))')" || error "Failed to download Passwall2 package."
    opkg install /tmp/passwall2.ipk || error "Failed to install Passwall2."

    if [ -n "$REMOTE_VERSION" ]; then
      echo "$REMOTE_VERSION" >"/root/.passwall2_version"
    fi
  fi

  curl -s -L -o "/etc/config/passwall2" "${REPO_URL}/src/etc/config/passwall2" || error "Failed to download passwall2 config."

  uci commit passwall2
  /etc/init.d/passwall2 restart
}

main() {
  if [ -n "${1-}" ]; then
    "$1"
  else
    check_min_requirements 200 500 2
    hiddify
    balancer
    ghost
    warp
    psiphon
    tor
    ssh_proxy
    server_less
    url_test
    geo_update
    passwall
  fi

  success "PassWall configuration completed successfully"
}

main "$@"
