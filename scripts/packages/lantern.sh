#!/bin/bash

main() {
  local DETECTED_OS SYSTEM_ARCH DETECTED_ARCH

  DETECTED_OS="$(uname -s)"
  case "$DETECTED_OS" in
    Darwin) DETECTED_OS="darwin" ;;
    *) DETECTED_OS="linux" ;;
  esac

  if [ -f "/etc/openwrt_release" ]; then
    SYSTEM_ARCH="$(grep DISTRIB_ARCH /etc/openwrt_release | cut -d"'" -f2 || true)"
    case "$SYSTEM_ARCH" in
      mipsel_24kc|mipsel*)
        DETECTED_ARCH="mipsle-softfloat"
        ;;
      mips64el*)
        DETECTED_ARCH="mips64le-softfloat"
        ;;
      mips64*)
        DETECTED_ARCH="mips64-softfloat"
        ;;
      mips*)
        DETECTED_ARCH="mips-softfloat"
        ;;
      aarch64*|arm64*|armv8*)
        DETECTED_ARCH="arm64"
        ;;
      arm*)
        DETECTED_ARCH="armv7"
        ;;
      x86_64)
        DETECTED_ARCH="amd64"
        ;;
      riscv64*)
        DETECTED_ARCH="riscv64"
        ;;
      *)
        echo "Unsupported CPU SYSTEM_ARCHitecture (OpenWrt): $SYSTEM_ARCH"
        exist
        ;;
    esac
  else
    SYSTEM_ARCH="$(uname -m)"
    case "$SYSTEM_ARCH" in
      x86_64)
        DETECTED_ARCH="amd64"
        ;;
      aSYSTEM_ARCH64|arm64)
        DETECTED_ARCH="arm64"
        ;;
      armv7*|armhf|arm)
        DETECTED_ARCH="armv7"
        ;;
      riscv64)
        DETECTED_ARCH="riscv64"
        ;;
      mips64el*)
        DETECTED_ARCH="mips64le-softfloat"
        ;;
      mips64*)
        DETECTED_ARCH="mips64-softfloat"
        ;;
      mipsel*)
        DETECTED_ARCH="mipsle-softfloat"
        ;;
      mips*)
        DETECTED_ARCH="mips-softfloat"
        ;;
      *)
        echo "Unsupported SYSTEM_ARCHitecture: $SYSTEM_ARCH"
        exit
        ;;
    esac
  fi

  if [ "$DETECTED_OS" = "darwin" ]; then
    curl -L -o "$HOME/lantern" "https://github.com/amaleky/WrtMate/releases/latest/download/lantern_${DETECTED_OS}-${DETECTED_ARCH}" || echo "Failed to download lantern."
    xattr -d com.apple.quarantine "$HOME/lantern"
    chmod +x "$HOME/lantern"
  else
    curl -L -o "/usr/bin/lantern" "https://github.com/amaleky/WrtMate/releases/latest/download/lantern_${DETECTED_OS}-${DETECTED_ARCH}" || echo "Failed to download lantern."
    chmod +x "/usr/bin/lantern"
  fi
}

main "$@"
