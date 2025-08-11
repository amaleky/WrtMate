#!/bin/sh

if [ ! -d "/usr/share/v2ray" ]; then mkdir -p "/usr/share/v2ray"; fi
if [ ! -d "/usr/share/singbox" ]; then mkdir -p "/usr/share/singbox"; fi

if curl -I --max-time 1 --retry 3 --socks5-hostname "127.0.0.1:22335" --silent --output "/dev/null" "https://1.1.1.1/cdn-cgi/trace/"; then
  PROXY_OPTION="--socks5-hostname 127.0.0.1:22335"
fi

download() {
  FILE="$1"
  URL="$2"
  REMOTE_SIZE=$(curl -s -I -L "$URL" | grep -i Content-Length | tail -n1 | awk '{print $2}' | tr -d '\r')

  if [ -f "$FILE" ]; then
    LOCAL_SIZE=$(wc -c < "$FILE" | tr -d ' ')
  else
    LOCAL_SIZE=0
  fi

  if [ "$REMOTE_SIZE" != "$LOCAL_SIZE" ] && [ "$REMOTE_SIZE" -gt 0 ]; then
    echo "Downloading $URL REMOTE_SIZE: $REMOTE_SIZE LOCAL_SIZE: $LOCAL_SIZE"
    TEMP_FILE="$(mktemp)"
    if curl -L $PROXY_OPTION -o "$TEMP_FILE" "$URL"; then
      mv "$TEMP_FILE" "$FILE"
    fi
  fi
}

# ip
download "/usr/share/v2ray/geoip.dat" "https://github.com/Chocolate4U/Iran-v2ray-rules/releases/latest/download/geoip-lite.dat"
download "/usr/share/singbox/geoip.db" "https://github.com/Chocolate4U/Iran-sing-box-rules/releases/latest/download/geoip-lite.db"

# domain
download "/usr/share/v2ray/geosite.dat" "https://github.com/Chocolate4U/Iran-v2ray-rules/releases/latest/download/geosite-lite.dat"
download "/usr/share/singbox/geosite.db" "https://github.com/Chocolate4U/Iran-sing-box-rules/releases/latest/download/geosite-lite.db"
