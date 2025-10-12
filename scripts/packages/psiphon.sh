#!/bin/bash

main() {
  if [ -f "/etc/openwrt_release" ]; then
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
  else
    DETECTED_ARCH="amd64"
  fi
  curl -L -o "/usr/bin/psiphon" "https://github.com/amaleky/WrtMate/releases/latest/download/psiphon_linux-${DETECTED_ARCH}" || error "Failed to download psiphon."
  chmod +x "/usr/bin/psiphon"
}

main "$@"
