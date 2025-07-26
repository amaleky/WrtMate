#!/bin/sh

if [ ! -d "/usr/share/v2ray" ]; then mkdir -p "/usr/share/v2ray"; fi
if [ ! -d "/usr/share/singbox" ]; then mkdir -p "/usr/share/singbox"; fi

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
    curl -L -o "$FILE" "$URL"
  fi
}


# ip
download "/usr/share/v2ray/geoip.dat" "https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/geoip.dat"
download "/usr/share/singbox/geoip.db" "https://cdn.jsdelivr.net/gh/chocolate4u/Iran-sing-box-rules@release/geoip.db"

# domain
download "/usr/share/v2ray/geosite.dat" "https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/geosite.dat"
download "/usr/share/singbox/geosite.db" "https://cdn.jsdelivr.net/gh/chocolate4u/Iran-sing-box-rules@release/geosite.db"
