#!/bin/bash

main() {
  local DETECTED_OS SYSTEM_ARCH DETECTED_ARCH

  if [ "${PREFIX:-}" = "/data/data/com.termux/files/usr" ] || [ -d "/data/data/com.termux/files/usr" ]; then
    DETECTED_OS="android"
    if ! command -v termux-chroot >/dev/null 2>&1; then
      pkg update
      pkg install -y proot
      termux-chroot
      echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf
    fi
  else
    case "$(uname -s)" in
      Darwin) DETECTED_OS="darwin" ;;
      *)      DETECTED_OS="linux" ;;
    esac
  fi

  if [ "$DETECTED_OS" = "android" ]; then
    SYSTEM_ARCH="$(uname -m)"
    case "$SYSTEM_ARCH" in
      aarch64|arm64)
        DETECTED_ARCH="arm64"
        ;;
      *)
        echo "Unsupported Android architecture: $SYSTEM_ARCH" >&2
        exit 1
        ;;
    esac
  elif [ -f "/etc/openwrt_release" ]; then
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
      aarch64|arm64)
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

  DOWNLOAD_URL="https://github.com/amaleky/WrtMate/releases/latest/download/scanner_${DETECTED_OS}-${DETECTED_ARCH}"
  REMOTE_SIZE=$(curl -sI -L "$DOWNLOAD_URL" | grep -i Content-Length | tail -n1 | awk '{print $2}' | tr -d '\r')
  LOCAL_FILE="${PREFIX:-$HOME/.local}/bin/scanner"
  if [ -f "/etc/openwrt_release" ]; then
    LOCAL_FILE="/usr/bin/scanner"
  fi
  mkdir -p "$(dirname "$LOCAL_FILE")"

  if [ -f "$LOCAL_FILE" ]; then
    LOCAL_SIZE=$(wc -c <"$LOCAL_FILE" | tr -d ' ')
  else
    LOCAL_SIZE=0
  fi

  if [ "$REMOTE_SIZE" != "$LOCAL_SIZE" ] || [ "$LOCAL_SIZE" -eq 0 ]; then
    curl -L -o "$LOCAL_FILE" "$DOWNLOAD_URL" || echo "Failed to download scanner."
    chmod +x "$LOCAL_FILE"
  else
    echo "$LOCAL_FILE is already installed"
  fi

  LINE='export PATH="$HOME/.local/bin:$PATH"'
  if [ -f ~/.bashrc ]; then
    if ! grep -qxF "$LINE" ~/.bashrc; then
      echo "$LINE" >> ~/.bashrc
      source ~/.bashrc
    fi
  fi
  if [ -f ~/.zshrc ]; then
    if ! grep -qxF "$LINE" ~/.zshrc; then
      echo "$LINE" >> ~/.zshrc
      source ~/.zshrc
    fi
  fi
}

main "$@"
