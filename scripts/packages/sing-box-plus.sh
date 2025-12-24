#!/bin/bash

main() {
  ARCH="$(grep DISTRIB_ARCH /etc/openwrt_release | cut -d"'" -f2)"
  if [ -f "/etc/openwrt_release" ]; then
    case "$ARCH" in
      x86_64) DETECTED_ARCH="amd64" ;;
      i386|x86) DETECTED_ARCH="386" ;;
      arm_cortex-a53*|*aarch64*) DETECTED_ARCH="arm64" ;;
      arm_cortex-a7*|*armv7*) DETECTED_ARCH="armv7" ;;
      armv6) DETECTED_ARCH="armv6" ;;
      mips64*)
        case "$ARCH" in
          *le) DETECTED_ARCH="mips64le" ;;
          *) DETECTED_ARCH="mips64-softfloat" ;;
        esac ;;
      mips*)
        case "$ARCH" in
          *le) DETECTED_ARCH="mipsle" ;;
          *) DETECTED_ARCH="mips" ;;
        esac ;;
      loong64) DETECTED_ARCH="loong64" ;;
      ppc64le) DETECTED_ARCH="ppc64le" ;;
      riscv64) DETECTED_ARCH="riscv64" ;;
      s390x) DETECTED_ARCH="s390x" ;;
      *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
  else
    case "$(uname -m)" in
      x86_64)
        DETECTED_ARCH="amd64"
        ;;
      aarch64 | arm64)
        DETECTED_ARCH="arm64"
        ;;
      arm*)
        DETECTED_ARCH="armv7"
        ;;
      *)
        echo "Unsupported architecture: $(uname -m)"
        exit 1
        ;;
    esac
  fi
  REMOTE_VERSION="$(curl -s -L "https://api.github.com/repos/kyochikuto/sing-box-plus/releases/latest" | jq -r '.tag_name' | sed 's/^v//')"
  curl -L -o "/tmp/sing-box-plus.tar.gz" "https://github.com/kyochikuto/sing-box-plus/releases/latest/download/sing-box-$REMOTE_VERSION-linux-$DETECTED_ARCH.tar.gz" || error "Failed to download sing-box-plus."
  tar -xvzf /tmp/sing-box-plus.tar.gz -C /tmp
  mv /tmp/sing-box-*/sing-box /usr/bin/sing-box-plus
  chmod +x /usr/bin/sing-box-plus
  rm -rfv /tmp/sing-box-plus.tar.gz /tmp/sing-box-*
}

main "$@"
