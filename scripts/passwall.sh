#!/bin/bash
# Passwall configuration for OpenWRT

install_passwall() {
  info "install_passwall"
  REMOTE_VERSION="$(curl -s "https://api.github.com/repos/xiaorouji/openwrt-passwall2/releases/latest" | grep "browser_download_url" | grep -o 'https://[^"]*luci-[^_]*_luci-app-passwall2_[^_]*_all\.ipk' | head -n1 | sed -n 's/.*luci-app-passwall2_\([^_]*\)_all\.ipk.*/\1/p')" || error "Failed to detect openwrt version."
  LOCAL_VERSION=$(opkg list-installed | grep "^luci-app-passwall2" | awk '{print $3}')
  if [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]; then
    opkg remove dnsmasq
    ensure_packages "dnsmasq-full kmod-nft-socket kmod-nft-tproxy binutils"

    curl -s -L -o "/tmp/packages.zip" "https://github.com/xiaorouji/openwrt-passwall2/releases/latest/download/passwall_packages_ipk_$(grep DISTRIB_ARCH /etc/openwrt_release | cut -d"'" -f2).zip" || error "Failed to download Passwall packages."
    unzip -o /tmp/packages.zip -d /tmp/passwall
    for pkg in /tmp/passwall/*.ipk; do opkg install "$pkg"; done

    curl -s -L -o "/tmp/passwall2.ipk" "$(curl -s "https://api.github.com/repos/xiaorouji/openwrt-passwall2/releases/latest" | grep "browser_download_url" | grep -o 'https://[^"]*luci-[^_]*_luci-app-passwall2_[^_]*_all\.ipk' | head -n1)" || error "Failed to download Passwall2 package."
    opkg install /tmp/passwall2.ipk || error "Failed to install Passwall2."
  fi

  curl -s -L -o "/etc/config/passwall2" "${REPO_URL}/src/etc/config/passwall2" || error "Failed to download passwall2 config."

  uci commit passwall2
  /etc/init.d/passwall2 restart
}

setup_geo_update() {
  info "setup_geo_update"
  if [ ! -d /root/scripts/ ]; then mkdir /root/scripts/; fi
  curl -s -L -o "/root/scripts/geo-update.sh" "${REPO_URL}/src/root/scripts/geo-update.sh" || error "Failed to download geo-update.sh."
  chmod +x /root/scripts/geo-update.sh
  add_cron_job "0 6 * * 0 /root/scripts/geo-update.sh"
  /root/scripts/geo-update.sh
}

setup_url_test() {
  info "setup_url_test"
  if [ ! -d /root/scripts/ ]; then mkdir /root/scripts/; fi
  curl -s -L -o "/root/scripts/url-test.sh" "${REPO_URL}/src/root/scripts/url-test.sh" || error "Failed to download url-test.sh."
  chmod +x /root/scripts/url-test.sh
  add_cron_job "*/5 * * * * /root/scripts/url-test.sh"

  curl -s -L -o "/etc/hotplug.d/iface/99-url-test" "${REPO_URL}/src/etc/hotplug.d/iface/99-url-test" || error "Failed to download 99-url-test hotplug script."
  chmod +x /etc/hotplug.d/iface/99-url-test
}

setup_balancer() {
  info "setup_balancer"
  if [ ! -d /root/balancer/ ]; then mkdir /root/balancer/; fi

  if [[ ! -f /root/balancer/configs.conf ]]; then
    curl -s -L -o "/root/balancer/configs.conf" "${REPO_URL}/src/root/balancer/configs.conf" || error "Failed to download balancer configs."
  fi

  curl -s -L -o "/etc/init.d/balancer" "${REPO_URL}/src/etc/init.d/balancer" || error "Failed to download balancer init script."
  chmod +x /etc/init.d/balancer

  curl -s -L -o "/root/balancer/run.sh" "${REPO_URL}/src/root/balancer/run.sh" || error "Failed to download balancer run.sh configs."
  chmod +x /root/balancer/run.sh

  /etc/init.d/balancer enable
  /etc/init.d/balancer start
}

install_ghost() {
  info "install_ghost"
  if [ ! -d /root/scripts/ ]; then mkdir /root/scripts/; fi

  curl -s -L -o "/root/scripts/scanner.sh" "${REPO_URL}/src/root/scripts/scanner.sh" || error "Failed to download scanner.sh."
  chmod +x /root/scripts/scanner.sh

  curl -s -L -o "/etc/init.d/scanner" "${REPO_URL}/src/etc/init.d/scanner" || error "Failed to download scanner init script."
  chmod +x /etc/init.d/scanner

  /etc/init.d/scanner disable

  add_cron_job "0 * * * * /etc/init.d/scanner start"

  if [ ! -d /root/ghost/ ]; then mkdir /root/ghost/; fi

  if [[ ! -f /root/ghost/configs.conf ]]; then
    curl -s -L -o "/root/ghost/configs.conf" "${REPO_URL}/src/root/ghost/configs.conf" || error "Failed to download ghost configs."
  fi

  curl -s -L -o "/etc/init.d/ghost" "${REPO_URL}/src/etc/init.d/ghost" || error "Failed to download ghost init script."
  chmod +x /etc/init.d/ghost

  curl -s -L -o "/root/ghost/run.sh" "${REPO_URL}/src/root/ghost/run.sh" || error "Failed to download ghost run.sh configs."
  chmod +x /root/ghost/run.sh

  /etc/init.d/ghost enable
  /etc/init.d/ghost start
}

install_tor() {
  info "install_tor"

  ensure_packages "tor tor-geoip obfs4proxy"

  if ! grep -q '^Bridge obfs4' /etc/tor/torrc; then
  echo "Please paste your Bridges from https://bridges.torproject.org/bridges?transport=obfs4 (press Ctrl+D when done):"
    {
      echo "Log notice syslog"
      echo "DataDirectory /var/lib/tor"
      echo "SOCKSPort 9050"
      echo "User tor"
      echo "UseBridges 1"
      echo "ClientTransportPlugin obfs4 exec /usr/bin/obfs4proxy"
      awk 'NF { if ($1 != "Bridge") print "Bridge", $0; else print $0 }'
    } > /etc/tor/torrc
  fi

  /etc/init.d/tor enable
  /etc/init.d/tor start
}

install_warp() {
  info "install_warp"
  if [ ! -d /root/.config/warp-plus ]; then mkdir -p /root/.config/warp-plus; fi

  REMOTE_VERSION="$(curl -s "https://api.github.com/repos/bepass-org/warp-plus/releases/latest" | jq -r '.tag_name')" || error "Failed to detect warp-plus version."
  LOCAL_VERSION="$(cat /root/.config/warp-plus/version 2>/dev/null || echo 'none')"

  if [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]; then
    echo "$REMOTE_VERSION" > /root/.config/warp-plus/version
    case "$(grep DISTRIB_ARCH /etc/openwrt_release | cut -d"'" -f2)" in
      mipsel_24kc)
        DETECTED_ARCH="mipslesoftfloat"
        ;;
      mips_24kc)
        DETECTED_ARCH="mipssoftfloat"
        ;;
      mipsel*)
        DETECTED_ARCH="mipsle"
        ;;
      mips64el*)
        DETECTED_ARCH="mips64le"
        ;;
      mips64*)
        DETECTED_ARCH="mips64"
        ;;
      mips*)
        DETECTED_ARCH="mips"
        ;;
      aarch64* | arm64* | armv8*)
        DETECTED_ARCH="arm64"
        ;;
      arm*)
        DETECTED_ARCH="arm7"
        ;;
      x86_64)
        DETECTED_ARCH="amd64"
        ;;
      riscv64*)
        DETECTED_ARCH="riscv64"
        ;;
      *)
        error "Unsupported CPU architecture: $(uname -m)"
        ;;
      esac

      curl -s -L -o "/tmp/warp.zip" "https://github.com/bepass-org/warp-plus/releases/latest/download/warp-plus_linux-${DETECTED_ARCH}.zip" || error "Failed to download WARP zip."
      unzip -o /tmp/warp.zip -d /tmp
      mv /tmp/warp-plus /usr/bin/warp-plus
      chmod +x /usr/bin/warp-plus
  fi

  curl -s -L -o "/etc/init.d/warp-plus" "${REPO_URL}/src/etc/init.d/warp-plus" || error "Failed to download warp-plus init script."
  chmod +x /etc/init.d/warp-plus

  /etc/init.d/warp-plus enable
  /etc/init.d/warp-plus start

  curl -s -L -o "/etc/init.d/psiphon" "${REPO_URL}/src/etc/init.d/psiphon" || error "Failed to download psiphon init script."
  chmod +x /etc/init.d/psiphon

  /etc/init.d/psiphon enable
  /etc/init.d/psiphon start
}

install_hiddify() {
  info "install_hiddify"
  if [ ! -d /root/.config/hiddify-cli ]; then mkdir -p /root/.config/hiddify-cli; fi

  REMOTE_VERSION="$(curl -s "https://api.github.com/repos/hiddify/hiddify-core/releases/latest" | jq -r '.tag_name')" || error "Failed to detect hiddify-core version."
  LOCAL_VERSION="$(cat /root/.config/hiddify-cli/version 2>/dev/null || echo 'none')"

  if [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]; then
    echo "$REMOTE_VERSION" > /root/.config/hiddify-cli/version
    case "$(grep DISTRIB_ARCH /etc/openwrt_release | cut -d"'" -f2)" in
    x86_64)
      DETECTED_ARCH="amd64"
      ;;
    i386 | i686)
      DETECTED_ARCH="386"
      ;;
    aarch64* | arm64* | armv8*)
      DETECTED_ARCH="arm64"
      ;;
    armv5* | arm926ej-s)
      DETECTED_ARCH="armv5"
      ;;
    armv6*)
      DETECTED_ARCH="armv6"
      ;;
    arm*)
      DETECTED_ARCH="armv7"
      ;;
    mips_24kc)
      DETECTED_ARCH="mips-softfloat"
      ;;
    mipsel_24kc)
      DETECTED_ARCH="mipsel-softfloat"
      ;;
    mips64el*)
      DETECTED_ARCH="mips64el"
      ;;
    mipsel*)
      DETECTED_ARCH="mipsel-hardfloat"
      ;;
    mips64*)
      DETECTED_ARCH="mips64"
      ;;
    mips*)
      DETECTED_ARCH="mips-hardfloat"
      ;;
    s390x)
      DETECTED_ARCH="s390x"
      ;;
    *)
      echo "Unsupported architecture: $(uname -m)"
      exit 1
      ;;
    esac

    curl -L -o /tmp/hiddify.tar.gz "https://github.com/hiddify/hiddify-core/releases/latest/download/hiddify-cli-linux-${DETECTED_ARCH}.tar.gz" || error "Failed to download Hiddify."
    tar -xvzf /tmp/hiddify.tar.gz -C /tmp
    mv /tmp/HiddifyCli /usr/bin/hiddify-cli
    chmod +x /usr/bin/hiddify-cli
  fi
}

install_ssh_proxy() {
  info "install_ssh_proxy"
  if [ ! -d /root/.ssh/ ]; then mkdir /root/.ssh/; fi

  if [ ! -e "/etc/init.d/ssh-proxy" ]; then
    curl -s -L -o "/etc/init.d/ssh-proxy" "${REPO_URL}/src/etc/init.d/ssh-proxy" || error "Failed to download ssh-proxy init script."
    chmod +x /etc/init.d/ssh-proxy
  fi

  if ! is_package_installed "openssh-client"; then
    ensure_packages "openssh-client"

    info "Please paste your SSH private key (press Ctrl+D when done):"
    cat >/root/.ssh/id_rsa
    chmod 600 /root/.ssh/id_rsa

    read -r -p "Enter SSH hostname: " SSH_HOST
    if [ -n "$SSH_HOST" ]; then
      sed -i "s/^SSH_HOST=.*/SSH_HOST=${SSH_HOST}/" "/etc/init.d/ssh-proxy"
    fi

    read -r -p "Enter SSH port: " SSH_PORT
    if [ -n "$SSH_PORT" ]; then
      sed -i "s/^SSH_PORT=.*/SSH_PORT=${SSH_PORT}/" "/etc/init.d/ssh-proxy"
    fi

    /etc/init.d/ssh-proxy enable
    /etc/init.d/ssh-proxy start
  fi
}

install_server_less() {
  info "install_server_less"
  if [ ! -d /root/xray/ ]; then mkdir /root/xray/; fi

  curl -s -L -o "/etc/init.d/serverless" "${REPO_URL}/src/etc/init.d/serverless" || error "Failed to download serverless init script."
  chmod +x /etc/init.d/serverless

  curl -s -L -o "/root/xray/serverless.json" "https://cdn.jsdelivr.net/gh/GFW-knocker/gfw_resist_HTTPS_proxy@main/ServerLess_TLSFrag_with_google_DOH.json" || error "Failed to download ServerLess configs."

  /etc/init.d/serverless enable
  /etc/init.d/serverless start
}

main() {
  check_min_requirements 200 100 2

  install_warp
  install_hiddify
  install_server_less
  install_ghost
  install_tor
  install_ssh_proxy
  setup_balancer
  setup_url_test
  setup_geo_update
  install_passwall

  success "PassWall configuration completed successfully"
}

main "$@"
