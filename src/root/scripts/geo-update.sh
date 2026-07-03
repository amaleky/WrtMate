#!/bin/bash

XRAY_DIR="/usr/bin/"
V2RAY_DIR="/usr/share/v2ray"
SINGBOX_DIR="/usr/share/singbox"
RULESET_DIR="$SINGBOX_DIR/rule-set"
RESOURCE_DIRECTORY="/tmp/domain-list-community-master/data"

if [ ! -d "$V2RAY_DIR" ]; then mkdir -p "$V2RAY_DIR"; fi
if [ ! -d "$SINGBOX_DIR" ]; then mkdir -p "$SINGBOX_DIR"; fi
if [ ! -d "$RULESET_DIR" ]; then mkdir -p "$RULESET_DIR"; fi

if [ ! -f "/usr/bin/sing-box" ]; then
  apk update
  apk add sing-box
fi

download() {
  local FILE="$1"
  local URL="$2"
  local UPDATE="$3"

  if [ "$UPDATE" = "false" ] && [ -f "$FILE" ]; then
    return 0
  fi

  echo "Downloading $FILE"

  REMOTE_SIZE=$(curl -s -I -L "$URL" | grep -i Content-Length | tail -n1 | awk '{print $2}' | tr -d '\r')

  if [ -f "$FILE" ]; then
    LOCAL_SIZE=$(wc -c <"$FILE" | tr -d ' ')
  else
    LOCAL_SIZE=0
  fi

  if [ "$REMOTE_SIZE" != "$LOCAL_SIZE" ] || [ "$REMOTE_SIZE" -eq 0 ]; then
    echo "Getting $FILE"
    TEMP_DOWNLOAD_FILE="$(mktemp)"
    if curl -s -L -o "$TEMP_DOWNLOAD_FILE" "$URL"; then
      mv -f "$TEMP_DOWNLOAD_FILE" "$FILE"
    fi
  fi
}

parse() {
  local FILE="$1"
  local OUTPUT="$2"
  local AMEND="$3"

  if [ ! -d "$RESOURCE_DIRECTORY" ]; then
    download "/tmp/v2ray.zip" "https://github.com/v2ray/domain-list-community/archive/master.zip" "false"
    unzip -o "/tmp/v2ray.zip" -d "/tmp"
  fi

  if [ "$AMEND" != "true" ]; then
    rm -f "$OUTPUT"
  fi

  while IFS= read -r LINE; do
    case $LINE in
      include:*)
        parse "${LINE#include:}" "$OUTPUT" "true"
        ;;
      *)
        echo "$LINE" >> "$OUTPUT"
        ;;
    esac
  done < "$RESOURCE_DIRECTORY/$FILE"
}

compile() {
  local FILE="$1"

  echo "Compiling $FILE"

  TEMP_COMPILE_FILE="$(mktemp)"

  cat "$RULESET_DIR/$FILE.txt" \
  | grep -vE "(##|/|^[[:space:]\!\?\[\.\*\$\-]|include:|.+\.ir$)" \
  | sed 's/^www\./\^/; s/$websocket.*//; s/$third-party.*//; s/$script.*//; s/\^.*$/\^/; s/#.*//g; /^||/! s/^/||/; /[^ ^]$/ s/$/^/; s/full://g; s/domain://g; s/geoip://g; s/geosite://g; s/ @ads//g; s/ @cn//g; s/ @!cn//g' \
  | grep -vF '||^' \
  | grep -vE '([0-9]{1,3}\.){3}[0-9]{1,3}' \
  | sort -u > "$TEMP_COMPILE_FILE"
  sing-box rule-set convert --type adguard --output "$RULESET_DIR/$FILE.srs" "$TEMP_COMPILE_FILE"
}

# Global
download "$V2RAY_DIR/geoip.dat" "https://github.com/Chocolate4U/Iran-v2ray-rules/releases/latest/download/geoip-lite.dat" "false"
download "$SINGBOX_DIR/geoip.db" "https://github.com/Chocolate4U/Iran-sing-box-rules/releases/latest/download/geoip-lite.db" "false"
download "$XRAY_DIR/geosite.dat" "https://github.com/Chocolate4U/Iran-v2ray-rules/releases/latest/download/geosite.dat" "false"
download "$V2RAY_DIR/geosite.dat" "https://github.com/Chocolate4U/Iran-v2ray-rules/releases/latest/download/geosite-lite.dat" "false"
download "$SINGBOX_DIR/geosite.db" "https://github.com/Chocolate4U/Iran-sing-box-rules/releases/latest/download/geosite-lite.db" "false"

# Direct
rm -f "$RULESET_DIR/geosite-direct.txt"

download "$RULESET_DIR/geoip-ir.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geoip-ir.srs"
download "$RULESET_DIR/geoip-private.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geoip-private.srs"

download "$RULESET_DIR/domains-ir.txt" "https://github.com/bootmortis/iran-hosted-domains/releases/latest/download/domains.txt"
cat "$RULESET_DIR/domains-ir.txt" >> "$RULESET_DIR/geosite-direct.txt"

download "$RULESET_DIR/iran_domains_direct.txt" "https://raw.githubusercontent.com/liketolivefree/iran_domain-ip/main/iran_domains_direct.txt"
cat "$RULESET_DIR/iran_domains_direct.txt" >> "$RULESET_DIR/geosite-direct.txt"

echo "||ir^" >> "$RULESET_DIR/geosite-direct.txt"
compile  "geosite-direct"

parse "linkedin" "$RULESET_DIR/geosite-linkedin.txt"
compile "geosite-linkedin"

parse "spotify" "$RULESET_DIR/geosite-spotify.txt"
compile "geosite-spotify"

parse "riot" "$RULESET_DIR/geosite-game.txt"
for DOMAIN in "myqcloud.com" "qq.com" "activisionblizzard.com" "activision.com" "demonware.net" "callofduty.com" "callofdutyleague.com" "codmwest.com" "appsflyersdk.com"; do
  echo "||$DOMAIN^" >> "$RULESET_DIR/geosite-game.txt"
done
compile "geosite-game"

# Block
rm -f "$RULESET_DIR/geosite-adguard.txt"

download "$RULESET_DIR/geoip-malware.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geoip-malware.srs"
download "$RULESET_DIR/geoip-phishing.srs" "https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set/geoip-phishing.srs"

download "$RULESET_DIR/blocklistproject.txt" "https://raw.githubusercontent.com/blocklistproject/Lists/master/adguard/tracking-ags.txt"
cat "$RULESET_DIR/blocklistproject.txt" >> "$RULESET_DIR/geosite-adguard.txt"

download "$RULESET_DIR/d3host.txt" "https://raw.githubusercontent.com/Turtlecute33/toolz/master/src/d3host.adblock"
cat "$RULESET_DIR/d3host.txt" >> "$RULESET_DIR/geosite-adguard.txt"

download "$RULESET_DIR/goodbyeads.txt" "https://raw.githubusercontent.com/8680/GOODBYEADS/master/data/mod/adblock.txt"
cat "$RULESET_DIR/goodbyeads.txt" >> "$RULESET_DIR/geosite-adguard.txt"

download "$RULESET_DIR/hagezi.txt" "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/ultimate.mini.txt"
cat "$RULESET_DIR/hagezi.txt" >> "$RULESET_DIR/geosite-adguard.txt"

download "$RULESET_DIR/hoshsadiq.txt" "https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/nocoin.txt"
cat "$RULESET_DIR/hoshsadiq.txt" >> "$RULESET_DIR/geosite-adguard.txt"

echo "/(airbrake|bugsnag|clarity|datadoghq|doubleclick|errorreporting|fastclick|freshmarketer|tagmanager|honeybadger|hotjar|logrocket|luckyorange|mouseflow|newrelic|openreplay|raygun|rollbar|sentry|siftscience|webengage|yandex|analytics|metrics)/" >> "$RULESET_DIR/geosite-adguard.txt"

compile "geosite-adguard"

# Sanction
rm -f "$RULESET_DIR/geosite-sanction.txt"

download "$RULESET_DIR/DynX-AntiBan-list.txt" "https://raw.githubusercontent.com/MrDevAnony/DynX-AntiBan-Domains/main/DynX-AntiBan-list.lst"
cat "$RULESET_DIR/DynX-AntiBan-list.txt" >> "$RULESET_DIR/geosite-sanction.txt"

download "$RULESET_DIR/ir-blocked-domain.txt" "https://raw.githubusercontent.com/filteryab/ir-blocked-domain/main/data/ir-blocked-domain"
cat "$RULESET_DIR/ir-blocked-domain.txt" >> "$RULESET_DIR/geosite-sanction.txt"

download "$RULESET_DIR/ir-sanctioned-domain.txt" "https://raw.githubusercontent.com/filteryab/ir-sanctioned-domain/main/data/ir-sanctioned-domain"
cat "$RULESET_DIR/ir-sanctioned-domain.txt" >> "$RULESET_DIR/geosite-sanction.txt"

parse "category-ai-!cn" "$RULESET_DIR/geosite-sanction.txt" "true"
parse "category-anticensorship" "$RULESET_DIR/geosite-sanction.txt" "true"
parse "category-communication" "$RULESET_DIR/geosite-sanction.txt" "true"
parse "category-entertainment" "$RULESET_DIR/geosite-sanction.txt" "true"
parse "category-forums" "$RULESET_DIR/geosite-sanction.txt" "true"
parse "category-media" "$RULESET_DIR/geosite-sanction.txt" "true"
parse "category-porn" "$RULESET_DIR/geosite-sanction.txt" "true"
parse "category-social-media-!cn" "$RULESET_DIR/geosite-sanction.txt" "true"

compile "geosite-sanction"
