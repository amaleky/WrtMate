#!/bin/bash
# Passwall configuration for OpenWRT

if [ ! -d /root/scripts/ ]; then mkdir /root/scripts/; fi
if [ ! -d /root/.cache/ ]; then mkdir /root/.cache/; fi

scanner() {
  info "scanner"

  REMOTE_VERSION="$(curl -s -L "https://api.github.com/repos/amaleky/WrtMate/releases/latest" | jq -r '.tag_name')"
  LOCAL_VERSION="$(cat "/root/.cache/.scanner_version" 2>/dev/null || echo 'none')"

  if [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]; then
    if [[ -f "/etc/init.d/scanner" ]] && /etc/init.d/scanner running; then
      /etc/init.d/scanner stop
    fi
    source <(wget -qO- "${REPO_URL}/scripts/packages/scanner.sh")
    if [ -n "$REMOTE_VERSION" ]; then
      echo "$REMOTE_VERSION" >"/root/.cache/.scanner_version"
    fi
  fi

  curl -s -L -o "/etc/init.d/scanner" "${REPO_URL}/src/etc/init.d/scanner" || error "Failed to download scanner init script."
  chmod +x /etc/init.d/scanner

  /etc/init.d/scanner enable
  /etc/init.d/scanner start
}

warp() {
  info "warp"

  REMOTE_VERSION="$(curl -s -L "https://api.github.com/repos/bepass-org/warp-plus/releases/latest" | jq -r '.tag_name')"
  LOCAL_VERSION="$(cat "/root/.cache/.warp_version" 2>/dev/null || echo 'none')"
  if [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]; then
    if [[ -f "/etc/init.d/warp-plus" ]] && /etc/init.d/warp-plus running; then
      /etc/init.d/warp-plus stop
    fi
    source <(wget -qO- "${REPO_URL}/scripts/packages/warp.sh")
    if [ -n "$REMOTE_VERSION" ]; then
      echo "$REMOTE_VERSION" >"/root/.cache/.warp_version"
    fi
  fi

  curl -s -L -o "/etc/init.d/warp-plus" "${REPO_URL}/src/etc/init.d/warp-plus" || error "Failed to download warp-plus init script."
  chmod +x /etc/init.d/warp-plus

  /etc/init.d/warp-plus enable
}

psiphon() {
  info "psiphon"
  if [ ! -d /root/psiphon/ ]; then mkdir /root/psiphon/; fi

  REMOTE_VERSION="$(curl -s -L "https://api.github.com/repos/amaleky/WrtMate/releases/latest" | jq -r '.tag_name')"
  LOCAL_VERSION="$(cat "/root/.cache/.psiphon_version" 2>/dev/null || echo 'none')"

  if [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]; then
    if [[ -f "/etc/init.d/psiphon" ]] && /etc/init.d/psiphon running; then
      /etc/init.d/psiphon stop
    fi
    source <(wget -qO- "${REPO_URL}/scripts/packages/psiphon.sh")
    if [ -n "$REMOTE_VERSION" ]; then
      echo "$REMOTE_VERSION" >"/root/.cache/.psiphon_version"
    fi
  fi

  curl -s -L -o "/etc/init.d/psiphon" "${REPO_URL}/src/etc/init.d/psiphon" || error "Failed to download psiphon init script."
  chmod +x /etc/init.d/psiphon

  curl -s -L -o "/root/psiphon/client.config" "https://raw.githubusercontent.com/amaleky/WrtMate/main/src/root/psiphon/client.config" || error "Failed to download psiphon configs."

  /etc/init.d/psiphon enable
}

lantern() {
  info "lantern"

  REMOTE_VERSION="$(curl -s -L "https://api.github.com/repos/amaleky/WrtMate/releases/latest" | jq -r '.tag_name')"
  LOCAL_VERSION="$(cat "/root/.cache/.lantern_version" 2>/dev/null || echo 'none')"

  if [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]; then
    if [[ -f "/etc/init.d/lantern" ]] && /etc/init.d/lantern running; then
      /etc/init.d/lantern stop
    fi
    source <(wget -qO- "${REPO_URL}/scripts/packages/lantern.sh")
    if [ -n "$REMOTE_VERSION" ]; then
      echo "$REMOTE_VERSION" >"/root/.cache/.lantern_version"
    fi
  fi

  curl -s -L -o "/etc/init.d/lantern" "${REPO_URL}/src/etc/init.d/lantern" || error "Failed to download lantern init script."
  chmod +x /etc/init.d/lantern

  /etc/init.d/lantern enable
}

tor() {
  info "tor"

  ensure_packages "tor tor-geoip obfs4proxy"

  grep '^Bridge' /etc/tor/torrc >/etc/tor/torrc.back
  curl -s -L -o "/etc/tor/torrc" "${REPO_URL}/src/etc/tor/torrc"
  cat /etc/tor/torrc.back >>/etc/tor/torrc

  if ! grep -q '^Bridge' /etc/tor/torrc; then
    echo "Please paste your Bridges from https://bridges.torproject.org/bridges?transport=obfs4 (press Ctrl+D when done):"
    {
      awk 'NF { if ($1 != "Bridge") print "Bridge", $0; else print $0 }'
    } >>/etc/tor/torrc
  fi

  /etc/init.d/tor enable
}

ssh_proxy() {
  info "ssh_proxy"
  if [ ! -d /root/.ssh/ ]; then mkdir /root/.ssh/; fi
  ensure_packages "openssh-client"

  if [[ ! -f "/etc/init.d/ssh-proxy" ]]; then
    SSH_USER=$(grep -E "^SSH_USER=" "/etc/init.d/ssh-proxy" | cut -d'=' -f2-)
    SSH_HOST=$(grep -E "^SSH_HOST=" "/etc/init.d/ssh-proxy" | cut -d'=' -f2-)
    SSH_PORT=$(grep -E "^SSH_PORT=" "/etc/init.d/ssh-proxy" | cut -d'=' -f2-)

    read -r -p "Enter SSH user " -e -i "$SSH_USER" NEW_SSH_USER
    read -r -p "Enter SSH host: " -e -i "$SSH_HOST" NEW_SSH_HOST
    read -r -p "Enter SSH port: " -e -i "$SSH_PORT" NEW_SSH_PORT

    curl -s -L -o "/etc/init.d/ssh-proxy" "${REPO_URL}/src/etc/init.d/ssh-proxy" || error "Failed to download ssh-proxy init script."
    chmod +x "/etc/init.d/ssh-proxy"

    if [[ ! -f "/root/.ssh/id_rsa" ]]; then
      info "Please paste your SSH private key (press Ctrl+D when done):"
      cat >"/root/.ssh/id_rsa"
      chmod 600 "/root/.ssh/id_rsa"
    fi

    sed -i "s|^SSH_USER=.*|SSH_USER=${NEW_SSH_USER}|" "/etc/init.d/ssh-proxy"
    sed -i "s|^SSH_HOST=.*|SSH_HOST=${NEW_SSH_HOST}|" "/etc/init.d/ssh-proxy"
    sed -i "s|^SSH_PORT=.*|SSH_PORT=${NEW_SSH_PORT}|" "/etc/init.d/ssh-proxy"
  fi

  if [[ -f "/root/.ssh/id_rsa" ]]; then
    /etc/init.d/ssh-proxy enable
    /etc/init.d/ssh-proxy start
  fi
}

server_less() {
  info "server_less"
  if [ ! -d /root/xray/ ]; then mkdir /root/xray/; fi

  curl -s -L -o "/etc/init.d/serverless" "${REPO_URL}/src/etc/init.d/serverless" || error "Failed to download serverless init script."
  chmod +x /etc/init.d/serverless

  curl -s -L -o "/root/xray/subscription.json" "https://raw.githubusercontent.com/voidr3aper-anon/GFW-slayer/main/configs/general/V-force.json" || error "Failed to download ServerLess configs list."

  /etc/init.d/serverless enable
}

url_test() {
  info "url_test"
  curl -s -L -o "/root/scripts/url-test.sh" "${REPO_URL}/src/root/scripts/url-test.sh" || error "Failed to download url-test.sh."
  chmod +x /root/scripts/url-test.sh
  add_cron_job "*/10 * * * * /root/scripts/url-test.sh"
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
  RELEASES="$(curl -s -L "https://api.github.com/repos/Openwrt-Passwall/openwrt-passwall2/releases")"
  REMOTE_VERSION="$(echo "$RELEASES" | jq -r '.[0].tag_name')"
  LOCAL_VERSION="$(cat "/root/.cache/.passwall_version" 2>/dev/null || echo 'none')"

  if [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]; then
    opkg remove --autoremove dnsmasq luci-app-passwall
    ensure_packages "dnsmasq-full kmod-nft-socket kmod-nft-tproxy binutils"

    curl -L -o "/tmp/packages.zip" "$(echo "$RELEASES" | jq -r ".[] | .assets[].browser_download_url | select(endswith(\"passwall_packages_ipk_$(grep DISTRIB_ARCH /etc/openwrt_release | cut -d"'" -f2).zip\"))" | head -n1)" || error "Failed to download passwall packages."
    unzip -o /tmp/packages.zip -d /tmp/passwall >/dev/null 2>&1
    for pkg in /tmp/passwall/*.ipk; do opkg install "$pkg"; done

    curl -L -o "/tmp/passwall.ipk" "$(echo "$RELEASES" | jq -r '.[] | .assets[].browser_download_url | select(contains("luci-app-passwall2_") and endswith("_all.ipk"))' | head -n1)" || error "Failed to download passwall package."
    opkg install /tmp/passwall.ipk || error "Failed to install Passwall."

    if [ -n "$REMOTE_VERSION" ]; then
      echo "$REMOTE_VERSION" >"/root/.cache/.passwall_version"
    fi
  fi

  curl -s -L -o "/usr/lib/lua/luci/view/passwall2/global/status.htm" "${REPO_URL}/src/usr/lib/lua/luci/view/passwall2/global/status.htm" || error "Failed to download passwall status header."
  curl -s -L -o "/etc/config/passwall2" "${REPO_URL}/src/etc/config/passwall2" || error "Failed to download passwall config."
  uci commit passwall2

  /etc/init.d/passwall2 restart

  if ! top -bn1 | grep -v 'grep' | grep '/tmp/etc/passwall2/bin/' | grep 'default' | grep 'global' >/dev/null; then
    info "Restarting passwall service..."
    /etc/init.d/passwall2 restart
  fi

  rm -rfv /tmp/packages.zip /tmp/passwall /tmp/passwall.ipk
}

cleanup() {
  for SERVICE in "hiddify" "hiddify-cli" "balancer" "ghost" "logwatch"; do
    if [ -f "/etc/init.d/${SERVICE}" ]; then
      /etc/init.d/${SERVICE} disable
      /etc/init.d/${SERVICE} stop
      rm -rfv "/etc/init.d/${SERVICE}"
    fi
  done
  rm -rfv "/root/warp" "/root/scripts/scanner.sh" "/root/ghost" "/usr/bin/hiddify-cli" "/usr/bin/hiddify" "/usr/bin/sing-box-plus" "/root/scripts/scanner.sh" "/root/.cache/subscriptions" "/root/.hiddify_version" "/root/.sing_box_plus_version" "/root/balancer" "/root/scripts/logwatch.sh" "/etc/hotplug.d/iface/99-url-test" /root/.*_version
  del_cron_job "/etc/init.d/scanner start"
}

main() {
  touch "/tmp/passwall_install.lock"

  check_min_requirements 200 500 2
  cleanup
  scanner
  warp
  psiphon
  lantern
  server_less
  url_test
  geo_update
  passwall
  ssh_proxy
  tor

  success "PassWall configuration completed successfully"
  reboot
}

main "$@"
