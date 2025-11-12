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
#download "$RULESET_DIR/geoip-ir.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geoip-ir.srs"
#download "$RULESET_DIR/geoip-private.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geoip-private.srs"
#download "$RULESET_DIR/geosite-ir.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geosite-ir.srs"
#download "$RULESET_DIR/geosite-private.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geosite-private.srs"

# Block
download "$RULESET_DIR/geoip-malware.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geoip-malware.srs"
download "$RULESET_DIR/geoip-phishing.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geoip-phishing.srs"
download "$RULESET_DIR/geosite-cryptominers.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geosite-cryptominers.srs"
if download "$RULESET_DIR/geosite-adguard-ultimate.txt" "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/ultimate.mini.txt"; then
  sing-box rule-set convert --type adguard --output "$RULESET_DIR/geosite-adguard-ultimate.srs" "$RULESET_DIR/geosite-adguard-ultimate.txt"
fi

# Proxy
download "$RULESET_DIR/geoip-telegram.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geoip-telegram.srs"
download "$RULESET_DIR/geosite-category-ai.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geosite-category-ai-!cn.srs"
download "$RULESET_DIR/geosite-category-anticensorship.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geosite-category-anticensorship.srs"
download "$RULESET_DIR/geosite-category-communication.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geosite-category-communication.srs"
download "$RULESET_DIR/geosite-category-dev.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geosite-category-dev.srs"
download "$RULESET_DIR/geosite-category-entertainment.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geosite-category-entertainment.srs"
download "$RULESET_DIR/geosite-category-media.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geosite-category-media.srs"
download "$RULESET_DIR/geosite-category-porn.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geosite-category-porn.srs"
download "$RULESET_DIR/geosite-category-social-media.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geosite-category-social-media-!cn.srs"
download "$RULESET_DIR/DynX-AntiBan-list.txt" "https://raw.githubusercontent.com/MrDevAnony/DynX-AntiBan-Domains/refs/heads/main/DynX-AntiBan-list.lst"
download "$RULESET_DIR/fod.txt" "https://raw.githubusercontent.com/freedomofdevelopers/fod/master/domains"
download "$RULESET_DIR/ir-blocked-domain.txt" "https://raw.githubusercontent.com/filteryab/ir-blocked-domain/main/data/ir-blocked-domain"
download "$RULESET_DIR/ir-sanctioned-domain.txt" "https://raw.githubusercontent.com/filteryab/ir-sanctioned-domain/main/data/ir-sanctioned-domain"

rm -rfv $RULESET_DIR/*.json $RULESET_DIR/proxy.txt
for RULESET in \
  "$RULESET_DIR/geosite-category-ai.srs" \
  "$RULESET_DIR/geosite-category-anticensorship.srs" \
  "$RULESET_DIR/geosite-category-communication.srs" \
  "$RULESET_DIR/geosite-category-dev.srs" \
  "$RULESET_DIR/geosite-category-entertainment.srs" \
  "$RULESET_DIR/geosite-category-media.srs" \
  "$RULESET_DIR/geosite-category-porn.srs" \
  "$RULESET_DIR/geosite-category-social-media.srs"; do
    sing-box rule-set decompile "$RULESET" -o "$RULESET.json"
    jq -r ".rules[] | (.domain[]?, .domain_suffix[]?)" "$RULESET.json" >> "$RULESET_DIR/proxy.txt"
done

cat "$RULESET_DIR/DynX-AntiBan-list.txt" \
    "$RULESET_DIR/fod.txt" \
    "$RULESET_DIR/ir-blocked-domain.txt" \
    "$RULESET_DIR/ir-sanctioned-domain.txt" \
    "$RULESET_DIR/proxy.txt" \
| sed -E '/^[[:space:]]*$/d; s/[^[:alnum:]\.-]//g; s/^\.*//; s/^www\.//; s/^/||/; s/$/^/' \
| sort -u > "$RULESET_DIR/geosite-proxy.txt"

sing-box rule-set convert --type adguard --output "$RULESET_DIR/geosite-proxy.srs" "$RULESET_DIR/geosite-proxy.txt"
