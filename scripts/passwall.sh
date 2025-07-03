#!/bin/bash
# Passwall configuration for OpenWRT

install_base_packages() {
  opkg remove dnsmasq
  ensure_packages "dnsmasq-full kmod-nft-socket kmod-nft-tproxy binutils"
}

install_passwall() {
  curl -L -o /tmp/packages.zip "https://github.com/xiaorouji/openwrt-passwall2/releases/latest/download/passwall_packages_ipk_$(grep DISTRIB_ARCH /etc/openwrt_release | cut -d"'" -f2).zip" || error "Failed to download Passwall packages."
  unzip -o /tmp/packages.zip -d /tmp/passwall
  for pkg in /tmp/passwall/*.ipk; do opkg install "$pkg"; done

  curl -L -o /tmp/passwall2.ipk "$(curl -s "https://api.github.com/repos/xiaorouji/openwrt-passwall2/releases/latest" | grep "browser_download_url" | grep -o 'https://[^"]*luci-[^_]*_luci-app-passwall2_[^_]*_all\.ipk' | head -n1)" || error "Failed to download Passwall2 package."
  opkg install /tmp/passwall2.ipk || error "Failed to install Passwall2."
  curl -s -L -o /etc/config/passwall2 "${REPO_URL}/src/etc/config/passwall2" || error "Failed to download passwall2 config."
}

setup_geo_update() {
  if [ ! -d /root/scripts/ ]; then mkdir /root/scripts/; fi
  curl -s -L -o /root/scripts/geo-update.sh "${REPO_URL}/src/root/scripts/geo-update.sh" || error "Failed to download geo-update.sh."
  chmod +x /root/scripts/geo-update.sh
  /root/scripts/geo-update.sh || error "Failed to update geo data."
  add_cron_job "0 6 * * 0 /root/scripts/geo-update.sh"
}

setup_url_test() {
  if [ ! -d /root/scripts/ ]; then mkdir /root/scripts/; fi
  curl -s -L -o /root/scripts/url-test.sh "${REPO_URL}/src/root/scripts/url-test.sh" || error "Failed to download url-test.sh."
  chmod +x /root/scripts/url-test.sh
  add_cron_job "* * * * * /root/scripts/url-test.sh"

  curl -s -L -o /etc/hotplug.d/iface/99-url-test "${REPO_URL}/src/etc/hotplug.d/iface/99-url-test" || error "Failed to download 99-url-test hotplug script."
  chmod +x /etc/hotplug.d/iface/99-url-test
}

install_warp() {
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

  info "Detected architecture: $DETECTED_ARCH"

  curl -L -o /tmp/warp.zip "https://github.com/bepass-org/warp-plus/releases/latest/download/warp-plus_linux-${DETECTED_ARCH}.zip" || error "Failed to download WARP zip."
  unzip -o /tmp/warp.zip -d /tmp
  mv /tmp/warp-plus /usr/bin/warp-plus
  chmod +x /usr/bin/warp-plus

  curl -s -L -o /etc/init.d/warp-plus "${REPO_URL}/src/etc/init.d/warp-plus" || error "Failed to download warp-plus init script."
  chmod +x /etc/init.d/warp-plus

  /etc/init.d/warp-plus enable
  /etc/init.d/warp-plus restart
}

install_hiddify() {
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

  info "Detected architecture: $DETECTED_ARCH"

  curl -L -o /tmp/hiddify.tar.gz "https://github.com/hiddify/hiddify-core/releases/latest/download/hiddify-cli-linux-${DETECTED_ARCH}.tar.gz" || error "Failed to download Hiddify."
  tar -xvzf /tmp/hiddify.tar.gz -C /tmp
  mv /tmp/HiddifyCli /usr/bin/hiddify-cli
  chmod +x /usr/bin/hiddify-cli

  if [ ! -d /root/hiddify/ ]; then mkdir /root/hiddify/; fi

  curl -s -L -o /etc/init.d/hiddify-cli "${REPO_URL}/src/etc/init.d/hiddify-cli" || error "Failed to download hiddify-cli init script."
  chmod +x /etc/init.d/hiddify-cli

  if [[ ! -e /root/hiddify/configs.conf ]]; then
    curl -s -L -o /root/hiddify/configs.conf "${REPO_URL}/src/root/hiddify/configs.conf" || error "Failed to download hiddify configs."
  fi

  curl -s -L -o /root/hiddify/settings.json "${REPO_URL}/src/root/hiddify/settings.json" || error "Failed to download hiddify settings."

  /etc/init.d/hiddify-cli enable
  /etc/init.d/hiddify-cli restart
}

install_ssh_proxy() {
  ensure_packages "openssh-client"
  if [ ! -d /root/.ssh/ ]; then mkdir /root/.ssh/; fi

  if [ ! -e "/root/.ssh/id_rsa" ]; then
    info "Please paste your SSH private key (press Ctrl+D when done):"
    cat >/root/.ssh/id_rsa
    chmod 600 /root/.ssh/id_rsa
  fi

  if [ ! -e "/etc/init.d/ssh-proxy" ]; then
    curl -s -L -o /etc/init.d/ssh-proxy "${REPO_URL}/src/etc/init.d/ssh-proxy" || error "Failed to download ssh-proxy init script."
    chmod +x /etc/init.d/ssh-proxy
  fi

  /etc/init.d/ssh-proxy enable
  /etc/init.d/ssh-proxy restart
}

main() {
  check_min_requirements 200 100 2

  if confirm "Do you want to install WARP?" "y"; then
    install_warp
  fi

  if confirm "Do you want to install Hiddify?" "y"; then
    install_hiddify
  fi

  if confirm "Do you want to install SSH-Proxy?" "y"; then
    install_ssh_proxy
  fi

  install_base_packages
  install_passwall
  setup_geo_update
  setup_url_test

  uci commit passwall2
  /etc/init.d/passwall2 restart
  success "PassWall configuration completed successfully"
}

main "$@"
