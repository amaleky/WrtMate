#!/bin/bash

main() {
  if [ -f "/etc/openwrt_release" ]; then
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
  else
    case "$(uname -m)" in
      x86_64)
        DETECTED_ARCH="amd64"
        ;;
      i386 | i686)
        DETECTED_ARCH="386"
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
  curl -L -o /tmp/hiddify.tar.gz "https://github.com/hiddify/hiddify-core/releases/latest/download/hiddify-cli-linux-${DETECTED_ARCH}.tar.gz" || error "Failed to download Hiddify."
  tar -xvzf /tmp/hiddify.tar.gz -C /tmp
  mv /tmp/HiddifyCli /usr/bin/hiddify-cli
  chmod +x /usr/bin/hiddify-cli
  rm -rfv /tmp/hiddify.tar.gz /tmp/webui
}

main "$@"
