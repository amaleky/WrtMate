#!/bin/bash
# V2ray/Xray Subscription Scanner
#
# Usage:    wget -O "$HOME/scanner.sh" "https://github.com/amaleky/WrtMate/raw/main/src/root/scripts/scanner.sh"; sudo bash "$HOME/scanner.sh" run
#

[ -z "$HOME" ] || [ "$HOME" = "/" ] && HOME="/root"
[ "$(id -u)" -eq 0 ] || error "This script must be run as root (use sudo)"

CONFIGS="$HOME/ghost/configs.conf"
PREV_COUNT=$(wc -l <"$CONFIGS")
CACHE_DIR="$HOME/.cache/subscriptions"
CONFIGS_LIMIT=40

mkdir -p "$CACHE_DIR" "$HOME/ghost"

CONFIG_URLS=(
  "https://github.com/Arashtelr/lab/raw/main/FreeVPN-by-ArashZidi"
  "https://github.com/ALIILAPRO/v2rayNG-Config/raw/main/server.txt"
  "https://github.com/liketolivefree/kobabi/raw/main/sub.txt"
  "https://github.com/hans-thomas/v2ray-subscription/raw/master/servers.txt"
  "https://github.com/Rayan-Config/C-Sub/raw/main/configs/proxy.txt"
  "https://github.com/darkvpnapp/CloudflarePlus/raw/main/proxy"
  "https://github.com/sinavm/SVM/raw/main/subscriptions/xray/normal/mix"
  "https://github.com/VPNforWindowsSub/configs/raw/master/full.txt"
  "https://github.com/mohamadfg-dev/telegram-v2ray-configs-collector/raw/main/category/vless.txt"
  "https://github.com/mohamadfg-dev/telegram-v2ray-configs-collector/raw/main/category/ss.txt"
  "https://github.com/mohamadfg-dev/telegram-v2ray-configs-collector/raw/main/category/wireguard.txt"
  "https://github.com/miladtahanian/V2RayCFGDumper/raw/main/config.txt"
  "https://github.com/Stinsonysm/GO_V2rayCollector/raw/main/mixed_iran.txt"
  "https://github.com/roosterkid/openproxylist/raw/main/V2RAY_RAW.txt"
  "https://github.com/ShatakVPN/ConfigForge-V2Ray/raw/main/configs/all.txt"
  "https://github.com/V2RayRoot/V2RayConfig/raw/main/Config/shadowsocks.txt"
  "https://github.com/V2RayRoot/V2RayConfig/raw/main/Config/trojan.txt"
  "https://github.com/V2RayRoot/V2RayConfig/raw/main/Config/vless.txt"
  "https://github.com/V2RayRoot/V2RayConfig/raw/main/Config/vmess.txt"
  "https://github.com/ermaozi/get_subscribe/raw/main/subscribe/v2ray.txt"
  "https://github.com/Firmfox/Proxify/raw/main/v2ray_configs/seperated_by_protocol/shadowsocks.txt"
  "https://github.com/Firmfox/Proxify/raw/main/v2ray_configs/seperated_by_protocol/warp.txt"
  "https://github.com/Firmfox/Proxify/raw/main/v2ray_configs/seperated_by_protocol/trojan.txt"
  "https://github.com/Firmfox/Proxify/raw/main/v2ray_configs/seperated_by_protocol/vmess.txt"
  "https://github.com/Firmfox/Proxify/raw/main/v2ray_configs/seperated_by_protocol/other.txt"
  "https://github.com/Firmfox/Proxify/raw/main/v2ray_configs/seperated_by_protocol/vless.txt"
  "https://github.com/itsyebekhe/PSG/raw/main/subscriptions/xray/normal/mix"
  "https://github.com/MatinGhanbari/v2ray-CONFIGs/raw/main/subscriptions/v2ray/all_sub.txt"
  "https://github.com/coldwater-10/V2ray-Config-Lite/raw/main/All_Configs_Sub.txt"
  "https://github.com/mahdibland/V2RayAggregator/raw/master/sub/sub_merge.txt"
  "https://github.com/barry-far/V2ray-Config/raw/main/All_Configs_Sub.txt"
  "https://github.com/SoliSpirit/v2ray-configs/raw/main/all_configs.txt"
  "https://github.com/ebrasha/free-v2ray-public-list/raw/main/all_extracted_configs.txt"
  "https://github.com/Kolandone/v2raycollector/raw/main/config.txt"
  "https://github.com/Epodonios/v2ray-CONFIGs/raw/main/All_Configs_Sub.txt"
  "https://github.com/liMilCo/v2r/raw/main/all_configs.txt"
)

BASE64_URLS=(
  "https://github.com/mahsanet/MahsaFreeConfig/raw/main/mci/sub_1.txt"
  "https://github.com/mahsanet/MahsaFreeConfig/raw/main/mtn/sub_1.txt"
  "https://github.com/mahsanet/MahsaFreeConfig/raw/main/segment/test_sub.txt"
  "https://github.com/R-the-coder/V2ray-configs/raw/main/config.txt"
  "https://github.com/Joker-funland/V2ray-configs/raw/main/config.txt"
  "https://github.com/AzadNetCH/Clash/raw/main/AzadNet.txt"
  "https://github.com/DaBao-Lee/V2RayN-NodeShare/raw/main/base64"
  "https://github.com/ripaojiedian/freenode/raw/main/sub"
)

if [[ ! -f "/usr/bin/hiddify-cli" ]]; then
  source <(wget -qO- "https://github.com/amaleky/WrtMate/raw/main/scripts/packages/hiddify.sh")
fi
if [[ ! -f "/usr/bin/sing-box" ]]; then
  source <(wget -qO- "https://github.com/amaleky/WrtMate/raw/main/scripts/packages/sing-box.sh")
fi

cd "/tmp" || true
echo "ℹ️ $PREV_COUNT Previous Configs Found"

if ! ping -c 1 -W 2 "217.218.155.155" >/dev/null 2>&1; then
  echo "ERROR: Connectivity test failed."
  exit 0
fi

throttle() {
  if [ -f "/etc/openwrt_release" ]; then
    local CPU_USAGE MEM_AVAILABLE
    CPU_USAGE=$(top -n 1 | awk '
    /CPU:/ {cpu = 100 - $8; gsub(/%/, "", cpu); print int(cpu); exit}
    /Cpu\(s\):/ {gsub(/%.*/, "", $2); print int($2); exit}
    ')
    MEM_AVAILABLE=$(free -m | awk '/^Mem:/ {print $7}')
    if [ "$CPU_USAGE" -gt 90 ] || [ "$MEM_AVAILABLE" -lt 100000 ]; then
      wait
    fi
  fi
}

get_random_port() {
  for i in $(seq 1 100); do
    port=$(((RANDOM % 16384) + 49152))
    nc -z 127.0.0.1 "$port" 2>/dev/null
    if [ $? -ne 0 ]; then
      echo "$port"
      return 0
    fi
  done
  echo "❌ Could not find free port after 100 tries" >&2
  return 1
}

process_config() {
  local CONFIG SOCKS_PORT RAW_CONFIG PARSED_CONFIG FINAL_CONFIG
  CONFIG="$1"
  SOCKS_PORT="$(get_random_port)"
  RAW_CONFIG="/tmp/scanner.raw.${SOCKS_PORT}"
  PARSED_CONFIG="/tmp/scanner.parsed.${SOCKS_PORT}"
  FINAL_CONFIG="/tmp/scanner.final.${SOCKS_PORT}"

  if [[ -z "$CONFIG" ]] || [[ "$CONFIG" == \#* ]] || [ "$(wc -l <"$CONFIGS")" -ge "$CONFIGS_LIMIT" ]; then
    return
  fi

  echo "$CONFIG" >"$RAW_CONFIG"

  if grep -qxF "$CONFIG" "$CONFIGS" || /usr/bin/hiddify-cli parse "$RAW_CONFIG" -o "$PARSED_CONFIG" 2>&1 | grep -qiE "error|fatal"; then
    rm -rf "$RAW_CONFIG" "$PARSED_CONFIG"
    return
  fi

  /usr/bin/jq --argjson port "$SOCKS_PORT" '{
    "inbounds": [
      {
        "type": "mixed",
        "tag": "mixed-in",
        "listen": "127.0.0.1",
        "listen_port": $port
      }
    ],
    "dns": {
      "servers": [
        {
          "tag": "remote",
          "type": "tls",
          "server": "208.67.222.2"
        }
      ],
      "strategy": "ipv4_only"
    },
    "route": {
      "rules": [
        {
          "action": "sniff"
        },
        {
          "protocol": "dns",
          "action": "hijack-dns"
        }
      ],
      "default_domain_resolver": "remote",
    },
    "outbounds": .outbounds
  }' "$PARSED_CONFIG" >"$FINAL_CONFIG"

  if [[ ! -f "/tmp/sing-box-$SOCKS_PORT" ]]; then
    ln -s "/usr/bin/sing-box" "/tmp/sing-box-$SOCKS_PORT"
  fi

  /tmp/sing-box-$SOCKS_PORT run -c "$FINAL_CONFIG" 2>&1 | while read -r LINE; do
    if echo "$LINE" | grep -q "sing-box started"; then
      if [ "$(curl -s -L -I --max-time 2 --socks5-hostname "127.0.0.1:$SOCKS_PORT" -o "/dev/null" -w "%{http_code}" "https://developer.android.com/")" -eq 200 ]; then
        echo "✅ Found ($(wc -l <"$CONFIGS"))"
        echo "$CONFIG" >>"$CONFIGS"
      fi
      kill -9 $(pgrep -f "/tmp/sing-box-$SOCKS_PORT run -c .*")
    fi
  done

  rm -rf "$RAW_CONFIG" "$PARSED_CONFIG" "$FINAL_CONFIG" "/tmp/sing-box-$SOCKS_PORT"
}

test_subscriptions_local() {
  BACKUP="$(cat "$CONFIGS")"
  echo -n >"$CONFIGS"
  echo "⏳ Testing $CONFIGS"
  while IFS= read -r CONFIG; do
    throttle
    process_config "$CONFIG" &
  done <<<"$BACKUP"
}

test_subscriptions_raw() {
  for SUBSCRIPTION in "${CONFIG_URLS[@]}"; do
    if [ "$(wc -l <"$CONFIGS")" -ge $CONFIGS_LIMIT ]; then continue; fi
    CACHE_FILE="$CACHE_DIR/$(echo "$SUBSCRIPTION" | md5sum | awk '{print $1}')"
    if curl -L --max-time 60 -o "$CACHE_FILE" "$SUBSCRIPTION"; then
      echo "✅ Downloaded $SUBSCRIPTION"
    elif [ -f "$CACHE_FILE" ]; then
      echo "⚠️ Using cashed $SUBSCRIPTION"
    else
      echo "❌ Failed to download $SUBSCRIPTION"
      continue
    fi
    while IFS= read -r CONFIG; do
      throttle
      process_config "$CONFIG" &
    done <"$CACHE_FILE"
  done
}

test_subscriptions_base64() {
  for SUBSCRIPTION in "${BASE64_URLS[@]}"; do
    if [ "$(wc -l <"$CONFIGS")" -ge $CONFIGS_LIMIT ]; then continue; fi
    CACHE_FILE="$CACHE_DIR/$(echo "$SUBSCRIPTION" | md5sum | awk '{print $1}')"
    if curl -L --max-time 60 -o "$CACHE_FILE" "$SUBSCRIPTION"; then
      echo "✅ Downloaded $SUBSCRIPTION"
    elif [ -f "$CACHE_FILE" ]; then
      echo "⚠️ Using cashed $SUBSCRIPTION"
    else
      echo "❌ Failed to download $SUBSCRIPTION"
      continue
    fi
    base64 --decode "$CACHE_FILE" 2>/dev/null | while IFS= read -r CONFIG; do
      throttle
      process_config "$CONFIG" &
    done
  done
}

run() {
  echo "✅ Running sing-box: $(wc -l <"$CONFIGS") Configs Found"
  PARSED="/tmp/ghost-parsed.json"
  SUBSCRIPTION="/tmp/ghost-subscription.json"

  /usr/bin/hiddify-cli parse "$CONFIGS" -o "$PARSED" >/dev/null 2>&1|| exit 1

  if [[ ! -f "/usr/share/singbox/rule-set/geosite-private.srs" ]]; then
    source <(wget -qO- "https://github.com/amaleky/WrtMate/raw/main/src/root/scripts/geo-update.sh")
  fi

  jq '{
    "log": {
      "level": "warning"
    },
    "dns": {
      "servers": [
        { "tag": "remote", "type": "tls", "server": "208.67.222.2" },
        { "tag": "local", "type": "local" }
      ],
      "rules": [
        { "rule_set": "geosite-ir", "server": "local" },
        { "rule_set": "geosite-private", "server": "local" }
      ],
      "strategy": "ipv4_only",
      "independent_cache": true
    },
    "inbounds": [
      { "type": "mixed", "tag": "mixed-in", "listen": "0.0.0.0", "listen_port": 9802, "set_system_proxy": true }
    ],
    "outbounds": (
      [
        {
          "type": "urltest",
          "tag": "Auto",
          "outbounds": [.outbounds[] | select(.type | IN("selector","urltest","direct") | not) | .tag],
          "url": "https://1.1.1.1/cdn-cgi/trace/",
          "interval": "1m",
          "tolerance": 50,
          "interrupt_exist_connections": false
        },
        { "type": "direct", "tag": "direct" },
        { "type": "block", "tag": "block" }
      ] + [.outbounds[] | select(.type | IN("selector","urltest","direct") | not)]
    ),
    "route": {
      "rules": [
        { "action": "sniff" },
        { "protocol": "dns", "action": "hijack-dns" },
        { "ip_is_private": true, "outbound": "direct" },
        { "rule_set": "geoip-ir", "outbound": "direct" },
        { "rule_set": "geoip-malware", "outbound": "block" },
        { "rule_set": "geoip-phishing", "outbound": "block" },
        { "rule_set": "geoip-private", "outbound": "direct" },
        { "rule_set": "geosite-category-ads-all", "outbound": "block" },
        { "rule_set": "geosite-category-public-tracker", "outbound": "block" },
        { "rule_set": "geosite-cryptominers", "outbound": "block" },
        { "rule_set": "geosite-ir", "outbound": "direct" },
        { "rule_set": "geosite-malware", "outbound": "block" },
        { "rule_set": "geosite-phishing", "outbound": "block" },
        { "rule_set": "geosite-private", "outbound": "direct" }
      ],
      "rule_set": [
        { "type": "local", "tag": "geoip-ir", "format": "binary", "path": "/usr/share/singbox/rule-set/geoip-ir.srs" },
        { "type": "local", "tag": "geoip-malware", "format": "binary", "path": "/usr/share/singbox/rule-set/geoip-malware.srs" },
        { "type": "local", "tag": "geoip-phishing", "format": "binary", "path": "/usr/share/singbox/rule-set/geoip-phishing.srs" },
        { "type": "local", "tag": "geoip-private", "format": "binary", "path": "/usr/share/singbox/rule-set/geoip-private.srs" },
        { "type": "local", "tag": "geosite-category-ads-all", "format": "binary", "path": "/usr/share/singbox/rule-set/geosite-category-ads-all.srs" },
        { "type": "local", "tag": "geosite-category-public-tracker", "format": "binary", "path": "/usr/share/singbox/rule-set/geosite-category-public-tracker.srs" },
        { "type": "local", "tag": "geosite-cryptominers", "format": "binary", "path": "/usr/share/singbox/rule-set/geosite-cryptominers.srs" },
        { "type": "local", "tag": "geosite-ir", "format": "binary", "path": "/usr/share/singbox/rule-set/geosite-ir.srs" },
        { "type": "local", "tag": "geosite-malware", "format": "binary", "path": "/usr/share/singbox/rule-set/geosite-malware.srs" },
        { "type": "local", "tag": "geosite-phishing", "format": "binary", "path": "/usr/share/singbox/rule-set/geosite-phishing.srs" },
        { "type": "local", "tag": "geosite-private", "format": "binary", "path": "/usr/share/singbox/rule-set/geosite-private.srs" }
      ],
      "final": "Auto",
      "default_domain_resolver": "local",
      "auto_detect_interface": true
    }
  }' "$PARSED" >"$SUBSCRIPTION" || exit 0

  /usr/bin/sing-box run -c "$SUBSCRIPTION"
}

main() {
  test_subscriptions_local
  test_subscriptions_raw
  test_subscriptions_base64
  if [ -n "${1-}" ]; then
    "$1"
  fi
}

main "$@"
