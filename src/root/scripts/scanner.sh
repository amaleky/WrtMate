#!/bin/bash
# V2ray/Xray Subscription Scanner
#
# Usage:    sudo bash -c "$(wget -qO- https://github.com/amaleky/WrtMate/raw/main/src/root/scripts/scanner.sh)"
#

[ -z "$HOME" ] || [ "$HOME" = "/" ] && HOME="/root"
[ "$(id -u)" -eq 0 ] || error "This script must be run as root (use sudo)"

CONFIGS="$HOME/ghost/configs.conf"
PREV_COUNT=$(wc -l <"$CONFIGS")
CACHE_DIR="$HOME/.cache/subscriptions"
CONFIGS_LIMIT=100

mkdir -p "$CACHE_DIR" "$HOME/ghost"

CONFIG_URLS=(
  "https://raw.githubusercontent.com/Arashtelr/lab/main/FreeVPN-by-ArashZidi"
  "https://raw.githubusercontent.com/ALIILAPRO/v2rayNG-Config/main/server.txt"
  "https://raw.githubusercontent.com/liketolivefree/kobabi/main/sub.txt"
  "https://raw.githubusercontent.com/hans-thomas/v2ray-subscription/master/servers.txt"
  "https://raw.githubusercontent.com/Rayan-Config/C-Sub/main/configs/proxy.txt"
  "https://raw.githubusercontent.com/darkvpnapp/CloudflarePlus/main/proxy"
  "https://raw.githubusercontent.com/sinavm/SVM/main/subscriptions/xray/normal/mix"
  "https://raw.githubusercontent.com/VPNforWindowsSub/configs/master/full.txt"
  "https://raw.githubusercontent.com/mohamadfg-dev/telegram-v2ray-configs-collector/main/category/vless.txt"
  "https://raw.githubusercontent.com/mohamadfg-dev/telegram-v2ray-configs-collector/main/category/ss.txt"
  "https://raw.githubusercontent.com/mohamadfg-dev/telegram-v2ray-configs-collector/main/category/wireguard.txt"
  "https://raw.githubusercontent.com/miladtahanian/V2RayCFGDumper/main/config.txt"
  "https://raw.githubusercontent.com/Stinsonysm/GO_V2rayCollector/main/mixed_iran.txt"
  "https://raw.githubusercontent.com/roosterkid/openproxylist/main/V2RAY_RAW.txt"
  "https://raw.githubusercontent.com/ShatakVPN/ConfigForge-V2Ray/main/configs/all.txt"
  "https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/shadowsocks.txt"
  "https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/trojan.txt"
  "https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/vless.txt"
  "https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/vmess.txt"
  "https://raw.githubusercontent.com/ermaozi/get_subscribe/main/subscribe/v2ray.txt"
  "https://raw.githubusercontent.com/Firmfox/Proxify/main/v2ray_configs/seperated_by_protocol/shadowsocks.txt"
  "https://raw.githubusercontent.com/Firmfox/Proxify/main/v2ray_configs/seperated_by_protocol/warp.txt"
  "https://raw.githubusercontent.com/Firmfox/Proxify/main/v2ray_configs/seperated_by_protocol/trojan.txt"
  "https://raw.githubusercontent.com/Firmfox/Proxify/main/v2ray_configs/seperated_by_protocol/vmess.txt"
  "https://raw.githubusercontent.com/Firmfox/Proxify/main/v2ray_configs/seperated_by_protocol/other.txt"
  "https://raw.githubusercontent.com/Firmfox/Proxify/main/v2ray_configs/seperated_by_protocol/vless.txt"
  "https://raw.githubusercontent.com/itsyebekhe/PSG/main/subscriptions/xray/normal/mix"
  "https://raw.githubusercontent.com/MatinGhanbari/v2ray-CONFIGs/main/subscriptions/v2ray/all_sub.txt"
  "https://raw.githubusercontent.com/coldwater-10/V2ray-Config-Lite/main/All_Configs_Sub.txt"
  "https://raw.githubusercontent.com/mahdibland/V2RayAggregator/master/sub/sub_merge.txt"
  "https://raw.githubusercontent.com/barry-far/V2ray-Config/main/All_Configs_Sub.txt"
  "https://raw.githubusercontent.com/SoliSpirit/v2ray-configs/main/all_configs.txt"
  "https://raw.githubusercontent.com/ebrasha/free-v2ray-public-list/main/all_extracted_configs.txt"
  "https://raw.githubusercontent.com/Kolandone/v2raycollector/main/config.txt"
  "https://raw.githubusercontent.com/Epodonios/v2ray-CONFIGs/main/All_Configs_Sub.txt"
  "https://raw.githubusercontent.com/liMilCo/v2r/main/all_configs.txt"
)

BASE64_URLS=(
  "https://raw.githubusercontent.com/mahsanet/MahsaFreeConfig/main/mci/sub_1.txt"
  "https://raw.githubusercontent.com/mahsanet/MahsaFreeConfig/main/mtn/sub_1.txt"
  "https://raw.githubusercontent.com/mahsanet/MahsaFreeConfig/main/segment/test_sub.txt"
  "https://raw.githubusercontent.com/R-the-coder/V2ray-configs/main/config.txt"
  "https://raw.githubusercontent.com/Joker-funland/V2ray-configs/main/config.txt"
  "https://raw.githubusercontent.com/AzadNetCH/Clash/main/AzadNet.txt"
  "https://raw.githubusercontent.com/DaBao-Lee/V2RayN-NodeShare/main/base64"
  "https://raw.githubusercontent.com/ripaojiedian/freenode/main/sub"
)

if [[ ! -f "/usr/bin/hiddify-cli" ]]; then
  source <(wget -qO- "https://github.com/amaleky/WrtMate/raw/main/scripts/packages/hiddify.sh")
fi
if [[ ! -f "/usr/bin/sing-box" ]]; then
  source <(wget -qO- "https://github.com/amaleky/WrtMate/raw/main/scripts/packages/sing-box.sh")
fi

cd "/tmp" || true
echo "ℹ️ $PREV_COUNT Previous Configs Found"

if ! ping -c 1 -W 2 "208.67.220.2" >/dev/null 2>&1; then
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
  if [ "$(wc -l <"$CONFIGS")" -ge $CONFIGS_LIMIT ]; then
    echo "🎉 $(wc -l <"$CONFIGS") Configs Found (previous: $PREV_COUNT) in $CONFIGS"
    if [ -f "/etc/init.d/ghost" ]; then
      /etc/init.d/ghost start
    fi
    exit 0
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

  if [[ -z "$CONFIG" ]] || [[ "$CONFIG" == \#* ]]; then
    return
  fi

  echo "$CONFIG" >"$RAW_CONFIG"

  if grep -qxF "$CONFIG" "$CONFIGS" || /usr/bin/hiddify-cli parse "$RAW_CONFIG" -o "$PARSED_CONFIG" 2>&1 | grep -qiE "error|fatal"; then
    rm -rf "$RAW_CONFIG" "$PARSED_CONFIG"
    return
  fi

  jq --argjson port "$SOCKS_PORT" '{
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
        echo "✅ Successfully ($(wc -l <"$CONFIGS")) ${CONFIG}"
        echo "$CONFIG" >>"$CONFIGS"
      fi
      kill -9 $(pgrep -f "/tmp/sing-box-$SOCKS_PORT run -c .*")
    fi
  done

  rm -rf "$RAW_CONFIG" "$PARSED_CONFIG" "$FINAL_CONFIG" "/tmp/sing-box-$SOCKS_PORT"
}

BACKUP="$(cat "$CONFIGS")"
echo -n >"$CONFIGS"

echo "⏳ Testing $CONFIGS"
while IFS= read -r CONFIG; do
  throttle
  process_config "$CONFIG" &
done <<<"$BACKUP"

for SUBSCRIPTION in "${CONFIG_URLS[@]}"; do
  CACHE_FILE="$CACHE_DIR/$(echo "$SUBSCRIPTION" | md5sum | awk '{print $1}')"
  if curl -L --max-time 60 -o "$CACHE_FILE" "$SUBSCRIPTION"; then
    echo "✅ Downloaded subscription $SUBSCRIPTION"
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

for SUBSCRIPTION in "${BASE64_URLS[@]}"; do
  CACHE_FILE="$CACHE_DIR/$(echo "$SUBSCRIPTION" | md5sum | awk '{print $1}')"
  if curl -L --max-time 60 -o "$CACHE_FILE" "$SUBSCRIPTION"; then
    echo "✅ Downloaded subscription $SUBSCRIPTION"
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

rm -rf /tmp/test* /tmp/sing-box*
