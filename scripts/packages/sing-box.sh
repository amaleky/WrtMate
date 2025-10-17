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
        DETECTED_ARCH="mipsle-softfloat"
        ;;
      mips64el*)
        DETECTED_ARCH="mips64le-softfloat"
        ;;
      mipsel*)
        DETECTED_ARCH="mipsle"
        ;;
      mips64*)
        DETECTED_ARCH="mips64-softfloat"
        ;;
      mips*)
        DETECTED_ARCH="mips-softfloat"
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
  REMOTE_VERSION="$(curl -s "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | jq -r '.tag_name | ltrimstr("v")')"
  curl -L -o /tmp/sing-box.tar.gz "https://github.com/SagerNet/sing-box/releases/latest/download/sing-box-${REMOTE_VERSION}-linux-${DETECTED_ARCH}.tar.gz" || error "Failed to download sing-box."
  tar -xvzf /tmp/sing-box.tar.gz -C /tmp
  mv /tmp/sing-box-*/sing-box /usr/bin/sing-box
  chmod +x /usr/bin/sing-box
  rm -rfv /tmp/sing-box-* /tmp/sing-box.tar.gz
}

main "$@"
