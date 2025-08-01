#!/bin/sh

TEST_URL="https://1.1.1.1/cdn-cgi/trace/"

if [ ! -d "/usr/share/v2ray" ]; then mkdir -p "/usr/share/v2ray"; fi
if [ ! -d "/usr/share/singbox" ]; then mkdir -p "/usr/share/singbox"; fi

if curl -I --max-time 3 --retry 1 --socks5 "127.0.0.1:22335" --silent --output "/dev/null" "$TEST_URL"; then
  PROXY_OPTION="--socks5 127.0.0.1:22335"
else
  PROXY_OPTION=""
fi

download() {
  FILE="$1"
  URL="$2"
  REMOTE_SIZE=$(curl -sI "$URL" | grep -i Content-Length | awk '{print $2}' | tr -d '\r')

  if [ -f "$FILE" ]; then
    LOCAL_SIZE=$(wc -c < "$FILE" | tr -d ' ')
  else
    LOCAL_SIZE=0
  fi

  if [ "$REMOTE_SIZE" != "$LOCAL_SIZE" ]; then
    TEMP_FILE="$(mktemp)"
    if curl -fL $PROXY_OPTION --output "$TEMP_FILE" "$URL"; then
      mv "$TEMP_FILE" "$FILE"
    fi
  fi
}

# ip
download "/usr/share/v2ray/geoip.dat" "https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/geoip.dat"
download "/usr/share/singbox/geoip.db" "https://cdn.jsdelivr.net/gh/chocolate4u/Iran-sing-box-rules@release/geoip.db"

# domain
download "/usr/share/v2ray/geosite.dat" "https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/geosite.dat"
download "/usr/share/singbox/geosite.db" "https://cdn.jsdelivr.net/gh/chocolate4u/Iran-sing-box-rules@release/geosite.db"
