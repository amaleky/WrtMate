#!/bin/bash

main() {
  if [ -f "/etc/openwrt_release" ]; then
    case "$(grep DISTRIB_ARCH /etc/openwrt_release | cut -d"'" -f2)" in
      mipsel_24kc | mipsel*)
        DETECTED_ARCH="mipslesoftfloat"
        ;;
      mips64el*)
        DETECTED_ARCH="mips64lesoftfloat"
        ;;
      mips64*)
        DETECTED_ARCH="mips64softfloat"
        ;;
      mips*)
        DETECTED_ARCH="mipssoftfloat"
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
  else
    case "$(uname -m)" in
      x86_64)
        DETECTED_ARCH="amd64"
        ;;
      aarch64 | arm64)
        DETECTED_ARCH="arm64"
        ;;
      arm*)
        DETECTED_ARCH="arm7"
        ;;
      *)
        echo "Unsupported architecture: $(uname -m)"
        exit 1
        ;;
    esac
  fi
  curl -L -o "/usr/bin/scanner" "https://github.com/amaleky/WrtMate/releases/latest/download/scanner_linux-${DETECTED_ARCH}" || error "Failed to download scanner."
  chmod +x "/usr/bin/scanner"
}

main "$@"
