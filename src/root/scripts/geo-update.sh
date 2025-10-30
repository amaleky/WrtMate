#!/bin/sh

# Create necessary directories
if [ ! -d "/usr/share/v2ray" ]; then mkdir -p "/usr/share/v2ray"; fi
if [ ! -d "/usr/share/singbox/rule-set" ]; then mkdir -p "/usr/share/singbox/rule-set"; fi

# Download a file if it's outdated
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
      return 0
    else
      rm -rf "$TEMP_FILE"
    fi
  fi
  return 1
}

# Download and convert AdGuard blocklist
download_adguard() {
  local list_name="$1"
  local url="$2"
  local txt_file="/usr/share/singbox/rule-set/${list_name}.txt"
  local srs_file="/usr/share/singbox/rule-set/${list_name}.srs"

  if download "$txt_file" "$url"; then
    sing-box rule-set convert --type adguard --output "$srs_file" "$txt_file"
  fi
}

download "/usr/share/v2ray/geoip.dat" "https://github.com/Chocolate4U/Iran-v2ray-rules/releases/latest/download/geoip-lite.dat"
download "/usr/share/singbox/geoip.db" "https://github.com/Chocolate4U/Iran-sing-box-rules/releases/latest/download/geoip-lite.db"
download "/usr/share/v2ray/geosite.dat" "https://github.com/Chocolate4U/Iran-v2ray-rules/releases/latest/download/geosite-lite.dat"
download "/usr/share/singbox/geosite.db" "https://github.com/Chocolate4U/Iran-sing-box-rules/releases/latest/download/geosite-lite.db"
download "/usr/share/singbox/rule-set/geoip-ir.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geoip-ir.srs"
download "/usr/share/singbox/rule-set/geoip-malware.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geoip-malware.srs"
download "/usr/share/singbox/rule-set/geoip-phishing.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geoip-phishing.srs"
download "/usr/share/singbox/rule-set/geoip-private.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geoip-private.srs"
download "/usr/share/singbox/rule-set/geosite-cryptominers.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geosite-cryptominers.srs"
download "/usr/share/singbox/rule-set/geosite-ir.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geosite-ir.srs"
download "/usr/share/singbox/rule-set/geosite-malware.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geosite-malware.srs"
download "/usr/share/singbox/rule-set/geosite-phishing.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geosite-phishing.srs"
download "/usr/share/singbox/rule-set/geosite-private.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geosite-private.srs"
download "/usr/share/singbox/rule-set/geosite-category-anticensorship.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geosite-category-anticensorship.srs"
download "/usr/share/singbox/rule-set/geosite-category-communication.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geosite-category-communication.srs"
download "/usr/share/singbox/rule-set/geosite-category-entertainment.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geosite-category-entertainment.srs"
download "/usr/share/singbox/rule-set/geosite-category-media.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geosite-category-media.srs"
download "/usr/share/singbox/rule-set/geosite-category-porn.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geosite-category-porn.srs"
download "/usr/share/singbox/rule-set/geosite-sanctioned.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geosite-sanctioned.srs"
download "/usr/share/singbox/rule-set/geosite-telegram.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geosite-telegram.srs"
download "/usr/share/singbox/rule-set/geoip-telegram.srs" "https://github.com/Chocolate4U/Iran-sing-box-rules/raw/rule-set/geoip-telegram.srs"
download_adguard "geosite-adguard-ultimate" "https://github.com/hagezi/dns-blocklists/raw/main/adblock/ultimate.txt"
