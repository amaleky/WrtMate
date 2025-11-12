#!/bin/sh

V2RAY_DIR="/usr/share/v2ray"
SINGBOX_DIR="/usr/share/singbox"
RULESET_DIR="$SINGBOX_DIR/rule-set"

if [ ! -d "$V2RAY_DIR" ]; then mkdir -p "$V2RAY_DIR"; fi
if [ ! -d "$SINGBOX_DIR" ]; then mkdir -p "$SINGBOX_DIR"; fi
if [ ! -d "$RULESET_DIR" ]; then mkdir -p "$RULESET_DIR"; fi

download() {
  FILE="$1"
  URL="$2"
  UPDATE="$3"

  if [ "$UPDATE" = "false" ] && [ -f "$FILE" ]; then
    return 0
  fi

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
      mv -f "$TEMP_FILE" "$FILE"
      return 0
    else
      rm -rf "$TEMP_FILE"
    fi
  fi
  return 1
}

# Global
download "$V2RAY_DIR/geoip.dat" "https://github.com/Chocolate4U/Iran-v2ray-rules/releases/latest/download/geoip-lite.dat" "false"
download "$SINGBOX_DIR/geoip.db" "https://github.com/Chocolate4U/Iran-sing-box-rules/releases/latest/download/geoip-lite.db" "false"
download "$V2RAY_DIR/geosite.dat" "https://github.com/Chocolate4U/Iran-v2ray-rules/releases/latest/download/geosite-lite.dat" "false"
download "$SINGBOX_DIR/geosite.db" "https://github.com/Chocolate4U/Iran-sing-box-rules/releases/latest/download/geosite-lite.db" "false"

# Direct
download "$RULESET_DIR/geoip-ir.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geoip-ir.srs"
download "$RULESET_DIR/geoip-private.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geoip-private.srs"
download "$RULESET_DIR/geosite-ir.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geosite-category-ir.srs"
download "$RULESET_DIR/geosite-private.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geosite-private.srs"

# Block
download "$RULESET_DIR/geoip-malware.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geoip-malware.srs"
download "$RULESET_DIR/geoip-phishing.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geoip-phishing.srs"
download "$RULESET_DIR/geosite-cryptominers.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geosite-cryptominers.srs"
if download "$RULESET_DIR/geosite-adguard-ultimate.txt" "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/ultimate.mini.txt"; then
  sing-box rule-set convert --type adguard --output "$RULESET_DIR/geosite-adguard-ultimate.srs" "$RULESET_DIR/geosite-adguard-ultimate.txt"
fi
