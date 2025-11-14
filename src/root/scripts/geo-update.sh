#!/bin/sh

V2RAY_DIR="/usr/share/v2ray"
SINGBOX_DIR="/usr/share/singbox"
RULESET_DIR="$SINGBOX_DIR/rule-set"
BASE_URL="https://raw.githubusercontent.com/v2ray/domain-list-community/master/data"

if [ ! -d "$V2RAY_DIR" ]; then mkdir -p "$V2RAY_DIR"; fi
if [ ! -d "$SINGBOX_DIR" ]; then mkdir -p "$SINGBOX_DIR"; fi
if [ ! -d "$RULESET_DIR" ]; then mkdir -p "$RULESET_DIR"; fi

download() {
  FILE="$1"
  URL="$2"
  UPDATE="$3"
  AMEND="$4"

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
      if [ "$AMEND" = "true" ]; then
        cat "$TEMP_FILE" >> "$FILE"
      else
        cp -f "$TEMP_FILE" "$FILE"
      fi
      grep '^include:' "$TEMP_FILE" | while IFS= read -r line; do
        download "$FILE" "$BASE_URL/${line#include:}" "true" "true"
      done
      return 0
    fi
    rm -rf "$TEMP_FILE"
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
download "$RULESET_DIR/domains-ir.txt" "https://github.com/bootmortis/iran-hosted-domains/releases/latest/download/domains.txt"
download "$RULESET_DIR/linkedin.txt" "$BASE_URL/linkedin"
download "$RULESET_DIR/riot.txt" "$BASE_URL/riot"
download "$RULESET_DIR/slack.txt" "$BASE_URL/slack"
download "$RULESET_DIR/whatsapp.txt" "$BASE_URL/whatsapp"

rm -rfv "$RULESET_DIR/geosite-direct.srs" "$RULESET_DIR/geosite-direct.txt"

cat "$RULESET_DIR/domains-ir.txt" \
  "$RULESET_DIR/linkedin.txt" \
  "$RULESET_DIR/riot.txt" \
  "$RULESET_DIR/slack.txt" \
  "$RULESET_DIR/whatsapp.txt" \
| grep -vE "(##|/|^[[:space:]!?]|include:|.+\.ir$| @ads)" \
| sed 's/^www\./\^/; s/$websocket.*//; s/$third-party.*//; s/$script.*//; s/\^.*$/\^/; s/#.*//g; /^||/! s/^/||/; /[^ ^]$/ s/$/^/; s/full://g; s/domain://g; s/geoip://g; s/geosite://g; s/ @cn//g' \
| sort -u > "$RULESET_DIR/geosite-direct.txt"

for DOMAIN in "ir" "pinsvc.net" "snapp.cab" "local" "ptp" "meet.google.com" "dl.playstation.net" "dl.playstation.com"; do
  echo "||$DOMAIN^" >> "$RULESET_DIR/geosite-direct.txt"
done

sing-box rule-set convert --type adguard --output "$RULESET_DIR/geosite-direct.srs" "$RULESET_DIR/geosite-direct.txt"

# Block
download "$RULESET_DIR/geoip-malware.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geoip-malware.srs"
download "$RULESET_DIR/geoip-phishing.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geoip-phishing.srs"
download "$RULESET_DIR/blocklistproject.txt" "https://raw.githubusercontent.com/blocklistproject/Lists/master/adguard/tracking-ags.txt"
download "$RULESET_DIR/d3host.txt" "https://raw.githubusercontent.com/Turtlecute33/toolz/master/src/d3host.adblock"
download "$RULESET_DIR/goodbyeads.txt" "https://raw.githubusercontent.com/8680/GOODBYEADS/master/data/mod/adblock.txt"
download "$RULESET_DIR/hagezi.txt" "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/ultimate.mini.txt"
download "$RULESET_DIR/hoshsadiq.txt" "https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/nocoin.txt"

rm -rfv "$RULESET_DIR/geosite-adguard.srs" "$RULESET_DIR/geosite-adguard.txt"

cat "$RULESET_DIR/blocklistproject.txt" \
    "$RULESET_DIR/d3host.txt" \
    "$RULESET_DIR/goodbyeads.txt" \
    "$RULESET_DIR/hagezi.txt" \
    "$RULESET_DIR/hoshsadiq.txt" \
| grep -vE "(##|/|^[[:space:]!?]|include:|airbrake|bugsnag|clarity|datadoghq|doubleclick|errorreporting|fastclick|freshmarketer|tagmanager|honeybadger|hotjar|logrocket|luckyorange|mouseflow|newrelic|openreplay|raygun|rollbar|sentry|siftscience|webengage|yandex|analytics|metrics)" \
| sed 's/^www\./\^/; s/$websocket.*//; s/$third-party.*//; s/$script.*//; s/\^.*$/\^/; s/#.*//g' \
| sort -u > "$RULESET_DIR/geosite-adguard.txt"

echo "/(airbrake|bugsnag|clarity|datadoghq|doubleclick|errorreporting|fastclick|freshmarketer|tagmanager|honeybadger|hotjar|logrocket|luckyorange|mouseflow|newrelic|openreplay|raygun|rollbar|sentry|siftscience|webengage|yandex|analytics|metrics)/" >> "$RULESET_DIR/geosite-adguard.txt"

sing-box rule-set convert --type adguard --output "$RULESET_DIR/geosite-adguard.srs" "$RULESET_DIR/geosite-adguard.txt"
