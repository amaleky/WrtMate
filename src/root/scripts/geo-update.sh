#!/bin/sh

if [ ! -d "/usr/share/v2ray" ]; then mkdir -p "/usr/share/v2ray"; fi
if [ ! -d "/usr/share/singbox/rule-set" ]; then mkdir -p "/usr/share/singbox/rule-set"; fi

download() {
  FILE="$1"
  URL="$2"
  REMOTE_SIZE=$(curl -s -I -L "$URL" | grep -i Content-Length | tail -n1 | awk '{print $2}' | tr -d '\r')

  if [ -f "$FILE" ]; then
    LOCAL_SIZE=$(wc -c <"$FILE" | tr -d ' ')
  else
    LOCAL_SIZE=0
  fi

  if [ "$REMOTE_SIZE" != "$LOCAL_SIZE" ] && [ "$REMOTE_SIZE" -gt 0 ]; then
    echo "Downloading $URL REMOTE_SIZE: $REMOTE_SIZE LOCAL_SIZE: $LOCAL_SIZE"
    TEMP_FILE="$(mktemp)"
    if curl -L -o "$TEMP_FILE" "$URL"; then
      mv "$TEMP_FILE" "$FILE"
    else
      rm -rf "$TEMP_FILE"
    fi
  fi
}

# ip
download "/usr/share/v2ray/geoip.dat" "https://github.com/Chocolate4U/Iran-v2ray-rules/releases/latest/download/geoip-lite.dat"
download "/usr/share/singbox/geoip.db" "https://github.com/Chocolate4U/Iran-sing-box-rules/releases/latest/download/geoip-lite.db"

# domain
download "/usr/share/v2ray/geosite.dat" "https://github.com/Chocolate4U/Iran-v2ray-rules/releases/latest/download/geosite-lite.dat"
download "/usr/share/singbox/geosite.db" "https://github.com/Chocolate4U/Iran-sing-box-rules/releases/latest/download/geosite-lite.db"

# rule-set
download "/usr/share/singbox/rule-set/geoip-ir.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geoip-ir.srs"
download "/usr/share/singbox/rule-set/geoip-malware.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geoip-malware.srs"
download "/usr/share/singbox/rule-set/geoip-phishing.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geoip-phishing.srs"
download "/usr/share/singbox/rule-set/geoip-private.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geoip-private.srs"
download "/usr/share/singbox/rule-set/geosite-category-ads-all.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geosite-category-ads-all.srs"
download "/usr/share/singbox/rule-set/geosite-category-public-tracker.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geosite-category-public-tracker.srs"
download "/usr/share/singbox/rule-set/geosite-cryptominers.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geosite-cryptominers.srs"
download "/usr/share/singbox/rule-set/geosite-ir.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geosite-ir.srs"
download "/usr/share/singbox/rule-set/geosite-malware.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geosite-malware.srs"
download "/usr/share/singbox/rule-set/geosite-phishing.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geosite-phishing.srs"
download "/usr/share/singbox/rule-set/geosite-private.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geosite-private.srs"
