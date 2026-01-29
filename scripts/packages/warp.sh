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
        echo "Unsupported CPU architecture: $(uname -m)"
        exit
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

  DOWNLOAD_URL="https://github.com/voidr3aper-anon/Vwarp/releases/latest/download/vwarp_linux-${DETECTED_ARCH}.zip"
  REMOTE_SIZE=$(curl -sI -L "$DOWNLOAD_URL" | grep -i Content-Length | tail -n1 | awk '{print $2}' | tr -d '\r')
  LOCAL_FILE="$HOME/warp-plus"
  if [ -f "/etc/openwrt_release" ]; then
    LOCAL_FILE="/usr/bin/warp-plus"
  elif [ "$DETECTED_OS" = "darwin" ]; then
    LOCAL_FILE="${PREFIX:-$HOME/.local}/bin/warp-plus"
  fi
  mkdir -p "$(dirname "$LOCAL_FILE")"

  if [ -f "$LOCAL_FILE" ]; then
    LOCAL_SIZE=$(wc -c <"$LOCAL_FILE" | tr -d ' ')
  else
    LOCAL_SIZE=0
  fi

  if [ "$REMOTE_SIZE" != "$LOCAL_SIZE" ] || [ "$LOCAL_SIZE" -eq 0 ]; then
    unzip -o "/tmp/warp.zip" -d "/tmp"
    mv "/tmp/vwarp" "$LOCAL_FILE"
    chmod +x "$LOCAL_FILE"
    rm -rfv "/tmp/warp.zip" "/tmp/README.md" /tmp/LICENSE*
  fi
}

main "$@"
