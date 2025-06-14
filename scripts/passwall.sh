#!/bin/bash
# Passwall configuration for OpenWRT

detect_architecture() {
  ARCH=$(uname -m)
  HAS_HARD_FLOAT=1
  if command -v readelf >/dev/null 2>&1; then
    if ! readelf -A /proc/self/exe | grep -q "Tag_ABI_FP_number_model: VFP"; then
      HAS_HARD_FLOAT=0
    fi
  fi
  HAS_V3=0
  if [ "$ARCH" = "x86_64" ]; then
    if grep -q -E 'avx2|bmi1|bmi2|f16c|fma|abm|movbe|xsave' /proc/cpuinfo; then
      HAS_V3=1
    fi
  fi
}

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
}

detect_warp_arch() {
  case "$ARCH" in
  x86_64) DETECTED_ARCH="amd64" ;;
  aarch64) DETECTED_ARCH="arm64" ;;
  armv7l | armv7) DETECTED_ARCH="arm7" ;;
  mips)
    if [ $HAS_HARD_FLOAT -eq 1 ]; then
      DETECTED_ARCH="mips"
    else
      DETECTED_ARCH="mipssoftfloat"
    fi
    ;;
  mipsel)
    if [ $HAS_HARD_FLOAT -eq 1 ]; then
      DETECTED_ARCH="mipsle"
    else
      DETECTED_ARCH="mipslesoftfloat"
    fi
    ;;
  mips64)
    if [ $HAS_HARD_FLOAT -eq 1 ]; then
      DETECTED_ARCH="mips64"
    else
      DETECTED_ARCH="mips64softfloat"
    fi
    ;;
  mips64el)
    if [ $HAS_HARD_FLOAT -eq 1 ]; then
      DETECTED_ARCH="mips64le"
    else
      DETECTED_ARCH="mips64lesoftfloat"
    fi
    ;;
  riscv64) DETECTED_ARCH="riscv64" ;;
  *) error "Unsupported CPU architecture: $ARCH" ;;
  esac
}

install_warp() {
  detect_warp_arch

  curl -L -o /tmp/warp.zip "https://github.com/bepass-org/warp-plus/releases/latest/download/warp-plus_linux-${DETECTED_ARCH}.zip" || error "Failed to download WARP zip."
  unzip -o /tmp/warp.zip -d /tmp
  mv /tmp/warp-plus /usr/bin/warp-plus
  chmod +x /usr/bin/warp-plus

  curl -s -L -o /etc/init.d/warp-plus "${REPO_URL}/src/etc/init.d/warp-plus" || error "Failed to download warp-plus init script."
  chmod +x /etc/init.d/warp-plus

  curl -s -L -o /etc/hotplug.d/iface/99-warp "${REPO_URL}/src/etc/hotplug.d/iface/99-warp" || error "Failed to download 99-warp hotplug script."
  chmod +x /etc/hotplug.d/iface/99-warp

  /etc/init.d/warp-plus enable
  /etc/init.d/warp-plus restart
}

detect_hiddify_arch() {
  case "$ARCH" in
  i386 | i686) DETECTED_ARCH="386" ;;
  x86_64)
    if [ $HAS_V3 -eq 1 ]; then
      DETECTED_ARCH="amd64-v3"
    else
      DETECTED_ARCH="amd64"
    fi
    ;;
  aarch64) DETECTED_ARCH="arm64" ;;
  armv5*) DETECTED_ARCH="armv5" ;;
  armv6*) DETECTED_ARCH="armv6" ;;
  armv7* | armv7) DETECTED_ARCH="armv7" ;;
  mips)
    if [ $HAS_HARD_FLOAT -eq 1 ]; then
      DETECTED_ARCH="mips-hardfloat"
    else
      DETECTED_ARCH="mips-softfloat"
    fi
    ;;
  mipsel)
    if [ $HAS_HARD_FLOAT -eq 1 ]; then
      DETECTED_ARCH="mipsel-hardfloat"
    else
      DETECTED_ARCH="mipsel-softfloat"
    fi
    ;;
  mips64) DETECTED_ARCH="mips64" ;;
  mips64el) DETECTED_ARCH="mips64el" ;;
  s390x) DETECTED_ARCH="s390x" ;;
  *) error "Unsupported CPU architecture: $ARCH" ;;
  esac
}

install_hiddify() {
  detect_hiddify_arch

  curl -L -o /tmp/hiddify.tar.gz "https://github.com/hiddify/hiddify-core/releases/latest/download/hiddify-cli-linux-${DETECTED_ARCH}.tar.gz" || error "Failed to download Hiddify."
  tar -xvzf /tmp/hiddify.tar.gz -C /tmp
  mv /tmp/HiddifyCli /usr/bin/hiddify-cli
  chmod +x /usr/bin/hiddify-cli

  if [ ! -d /root/hiddify/ ]; then mkdir /root/hiddify/; fi

  curl -s -L -o /etc/init.d/hiddify-cli "${REPO_URL}/src/etc/init.d/hiddify-cli" || error "Failed to download hiddify-cli init script."
  chmod +x /etc/init.d/hiddify-cli

  curl -s -L -o /etc/hotplug.d/iface/99-hiddify "${REPO_URL}/src/etc/hotplug.d/iface/99-hiddify" || error "Failed to download 99-hiddify hotplug script."
  chmod +x /etc/hotplug.d/iface/99-hiddify

  if [[ ! -e /root/hiddify/configs.conf ]]; then
    curl -s -L -o /root/hiddify/configs.conf "${REPO_URL}/src/root/hiddify/configs.conf" || error "Failed to download hiddify configs."
  fi

  curl -s -L -o /root/hiddify/settings.conf "${REPO_URL}/src/root/hiddify/settings.conf" || error "Failed to download hiddify settings."

  /etc/init.d/hiddify-cli enable
  /etc/init.d/hiddify-cli restart
}

install_ssh_proxy() {
  ensure_packages "openssh-keygen openssh-client sshtunnel"
  if [ ! -d /root/.ssh/ ]; then mkdir /root/.ssh/; fi
  if [ ! -f /root/.ssh/id_rsa ]; then ssh-keygen -b 4096 -t rsa -f /root/.ssh/id_rsa -P ""; fi

  info "Please add this public key to your SSH server's authorized_keys file:"
  cat /root/.ssh/id_rsa.pub

  curl -s -L -o /etc/init.d/ssh-proxy "${REPO_URL}/src/etc/init.d/ssh-proxy" || error "Failed to download ssh-proxy init script."
  chmod +x /etc/init.d/ssh-proxy

  curl -s -L -o /etc/hotplug.d/iface/99-ssh-proxy "${REPO_URL}/src/etc/hotplug.d/iface/99-ssh-proxy" || error "Failed to download 99-ssh-proxy hotplug script."
  chmod +x /etc/hotplug.d/iface/99-ssh-proxy

  /etc/init.d/ssh-proxy enable
  /etc/init.d/ssh-proxy restart
}

main() {
  detect_architecture
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
