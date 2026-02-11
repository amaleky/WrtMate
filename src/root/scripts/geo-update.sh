#!/bin/sh

XRAY_DIR="/usr/bin/"
V2RAY_DIR="/usr/share/v2ray"
SINGBOX_DIR="/usr/share/singbox"
RULESET_DIR="$SINGBOX_DIR/rule-set"
BASE_URL="https://cdn.jsdelivr.net/gh/v2ray/domain-list-community@master/data"

if [ ! -d "$V2RAY_DIR" ]; then mkdir -p "$V2RAY_DIR"; fi
if [ ! -d "$SINGBOX_DIR" ]; then mkdir -p "$SINGBOX_DIR"; fi
if [ ! -d "$RULESET_DIR" ]; then mkdir -p "$RULESET_DIR"; fi

if [ ! -f "/usr/bin/sing-box" ]; then
  opkg update
  opkg install sing-box
fi

download() {
  FILE="$1"
  URL="$2"
  UPDATE="$3"
  AMEND="$4"

  if [ "$UPDATE" = "false" ] && [ -f "$FILE" ]; then
    return 0
  fi

  echo "Downloading $URL"
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
  fi
  rm -rf "$TEMP_FILE"
}

# Global
download "$V2RAY_DIR/geoip.dat" "https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/geoip-lite.dat" "false"
download "$SINGBOX_DIR/geoip.db" "https://cdn.jsdelivr.net/gh/chocolate4u/Iran-sing-box-rules@release/geoip-lite.db" "false"
download "$V2RAY_DIR/geosite.dat" "https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/geosite-lite.dat" "false"
download "$SINGBOX_DIR/geosite.db" "https://cdn.jsdelivr.net/gh/chocolate4u/Iran-sing-box-rules@release/geosite-lite.db" "false"

# Direct
CURRENT_SIZE=$(wc -c <"$RULESET_DIR/geosite-direct.txt" | tr -d ' ')
download "$RULESET_DIR/geoip-ir.srs" "https://cdn.jsdelivr.net/gh/Chocolate4U/Iran-sing-box-rules@rule-set/geoip-ir.srs"
download "$RULESET_DIR/geoip-private.srs" "https://cdn.jsdelivr.net/gh/Chocolate4U/Iran-sing-box-rules@rule-set/geoip-private.srs"
download "$RULESET_DIR/domains-ir.txt" "https://github.com/bootmortis/iran-hosted-domains/releases/latest/download/domains.txt"
download "$RULESET_DIR/iran_domains_direct.txt" "https://cdn.jsdelivr.net/gh/liketolivefree/iran_domain-ip@main/iran_domains_direct.txt"

cat "$RULESET_DIR/domains-ir.txt" \
  "$RULESET_DIR/iran_domains_direct.txt" \
| grep -vE "(##|/|^[[:space:]\!\?\[\.\*\$\-]|include:|.+\.ir$| @ads)" \
| sed 's/^www\./\^/; s/$websocket.*//; s/$third-party.*//; s/$script.*//; s/\^.*$/\^/; s/#.*//g; /^||/! s/^/||/; /[^ ^]$/ s/$/^/; s/full://g; s/domain://g; s/geoip://g; s/geosite://g; s/ @cn//g' \
| grep -vF '||^' \
| grep -vE '([0-9]{1,3}\.){3}[0-9]{1,3}' \
| sort -u > "$RULESET_DIR/geosite-direct.txt"

for DOMAIN in "ir" "local" "localhost"; do
  echo "||$DOMAIN^" >> "$RULESET_DIR/geosite-direct.txt"
done

if [ "$(wc -c <"$RULESET_DIR/geosite-direct.txt" | tr -d ' ')" != "$CURRENT_SIZE" ]; then
  sing-box rule-set convert --type adguard --output "$RULESET_DIR/geosite-direct.srs" "$RULESET_DIR/geosite-direct.txt"
fi

CURRENT_SIZE=$(wc -c <"$RULESET_DIR/linkedin.txt" | tr -d ' ')
download "$RULESET_DIR/linkedin.txt" "$BASE_URL/linkedin" "false"
cat "$RULESET_DIR/linkedin.txt" \
| grep -vE "(##|/|^[[:space:]\!\?\[\.\*\$\-]|include:|.+\.ir$| @ads)" \
| sed 's/^www\./\^/; s/$websocket.*//; s/$third-party.*//; s/$script.*//; s/\^.*$/\^/; s/#.*//g; /^||/! s/^/||/; /[^ ^]$/ s/$/^/; s/full://g; s/domain://g; s/geoip://g; s/geosite://g; s/ @cn//g' \
| grep -vF '||^' \
| grep -vE '([0-9]{1,3}\.){3}[0-9]{1,3}' \
| sort -u > "$RULESET_DIR/linkedin.txt"
if [ "$(wc -c <"$RULESET_DIR/linkedin.txt" | tr -d ' ')" != "$CURRENT_SIZE" ]; then
  sing-box rule-set convert --type adguard --output "$RULESET_DIR/linkedin.srs" "$RULESET_DIR/linkedin.txt"
fi

CURRENT_SIZE=$(wc -c <"$RULESET_DIR/game.txt" | tr -d ' ')
for DOMAIN in "historyofdota.com" "historyofdota.net" "historyofdota.org" "instituteofwar.org" "molesports.com" "rgpub.io" "riot-games.com" "riot.com" "riot.net" "riotcdn.net" "riotgames.co.kr" "riotgames.com" "riotgames.info" "riotgames.jp" "riotgames.net" "riotgames.tv" "riotpin.com" "riotpoints.com" "rstatic.net" "supremacy.com" "supremacy.net" "championshipseriesleague.com" "lcsmerch.com" "leaguehighschool.com" "leagueoflegends.ca" "leagueoflegends.cn" "leagueoflegends.co.kr" "leagueoflegends.com" "leagueoflegends.info" "leagueoflegends.kr" "leagueoflegends.net" "leagueoflegends.org" "leagueoflegendsscripts.com" "leaguesharp.info" "leaguoflegends.com" "learnwithleague.com" "lol-europe.com" "lolclub.org" "lolespor.com" "lolesports.com" "lolfanart.net" "lolpcs.com" "lolshop.co.kr" "lolstatic.com" "lolusercontent.com" "lpl.com.cn" "pvp.net" "pvp.tv" "ulol.com" "lolstatic-a.akamaihd.net" "playvalorant.com" "riotforgegames.com" "ruinedking.com" "convrgencegame.com" "lolstatic-a.akamaihd.net" "myqcloud.com" "qq.com" "activisionblizzard.com" "activision.com" "demonware.net" "callofduty.com" "callofdutyleague.com" "codmwest.com" "appsflyersdk.com"; do
  echo "||$DOMAIN^" >> "$RULESET_DIR/game.txt"
done
if [ "$(wc -c <"$RULESET_DIR/game.txt" | tr -d ' ')" != "$CURRENT_SIZE" ]; then
  sing-box rule-set convert --type adguard --output "$RULESET_DIR/game.srs" "$RULESET_DIR/game.txt"
fi

# Block
CURRENT_SIZE=$(wc -c <"$RULESET_DIR/geosite-adguard.txt" | tr -d ' ')
download "$RULESET_DIR/geoip-malware.srs" "https://cdn.jsdelivr.net/gh/Chocolate4U/Iran-sing-box-rules@rule-set/geoip-malware.srs"
download "$RULESET_DIR/geoip-phishing.srs" "https://cdn.jsdelivr.net/gh/Chocolate4U/Iran-sing-box-rules@rule-set/geoip-phishing.srs"
download "$RULESET_DIR/blocklistproject.txt" "https://cdn.jsdelivr.net/gh/blocklistproject/Lists@master/adguard/tracking-ags.txt"
download "$RULESET_DIR/d3host.txt" "https://cdn.jsdelivr.net/gh/Turtlecute33/toolz@master/src/d3host.adblock"
download "$RULESET_DIR/goodbyeads.txt" "https://cdn.jsdelivr.net/gh/8680/GOODBYEADS@master/data/mod/adblock.txt"
download "$RULESET_DIR/hagezi.txt" "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@main/adblock/ultimate.mini.txt"
download "$RULESET_DIR/hoshsadiq.txt" "https://cdn.jsdelivr.net/gh/hoshsadiq/adblock-nocoin-list@master/nocoin.txt"

cat "$RULESET_DIR/blocklistproject.txt" \
    "$RULESET_DIR/d3host.txt" \
    "$RULESET_DIR/goodbyeads.txt" \
    "$RULESET_DIR/hagezi.txt" \
    "$RULESET_DIR/hoshsadiq.txt" \
| grep -vE "(##|/|^[[:space:]\!\?\[\.\*\$\-]|include:|airbrake|bugsnag|clarity|datadoghq|doubleclick|errorreporting|fastclick|freshmarketer|tagmanager|honeybadger|hotjar|logrocket|luckyorange|mouseflow|newrelic|openreplay|raygun|rollbar|sentry|siftscience|webengage|yandex|analytics|metrics)" \
| sed 's/^www\./\^/; s/$websocket.*//; s/$third-party.*//; s/$script.*//; s/\^.*$/\^/; s/#.*//g' \
| grep -vF '||^' \
| grep -vF 'redirect-rule' \
| grep -vE '([0-9]{1,3}\.){3}[0-9]{1,3}' \
| sort -u > "$RULESET_DIR/geosite-adguard.txt"

echo "/(airbrake|bugsnag|clarity|datadoghq|doubleclick|errorreporting|fastclick|freshmarketer|tagmanager|honeybadger|hotjar|logrocket|luckyorange|mouseflow|newrelic|openreplay|raygun|rollbar|sentry|siftscience|webengage|yandex|analytics|metrics)/" >> "$RULESET_DIR/geosite-adguard.txt"

if [ "$(wc -c <"$RULESET_DIR/geosite-adguard.txt" | tr -d ' ')" != "$CURRENT_SIZE" ]; then
  sing-box rule-set convert --type adguard --output "$RULESET_DIR/geosite-adguard.srs" "$RULESET_DIR/geosite-adguard.txt"
fi
