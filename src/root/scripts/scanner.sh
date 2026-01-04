#!/bin/bash
# V2ray/Xray Subscription Scanner
#
# Usage:    wget -O "$HOME/scanner.sh" "https://raw.githubusercontent.com/amaleky/WrtMate/main/src/root/scripts/scanner.sh"; sudo bash "$HOME/scanner.sh"
#

[ -z "$HOME" ] || [ "$HOME" = "/" ] && HOME="/root"
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ This script must be run as root (use sudo)"
  exit
fi

if [[ ! -f "/usr/bin/hiddify-cli" ]]; then
  source <(wget -qO- "https://raw.githubusercontent.com/amaleky/WrtMate/main/scripts/packages/hiddify.sh")
fi
if [[ ! -f "/usr/bin/sing-box" ]]; then
  source <(wget -qO- "https://raw.githubusercontent.com/amaleky/WrtMate/main/scripts/packages/sing-box.sh")
fi

CONFIGS="$HOME/ghost/configs.conf"
TMP_CONFIGS="$HOME/ghost/configs.backup"
SCAN_HISTORY="/tmp/scanner.history"
CACHE_DIR="$HOME/.cache/subscriptions"
CONFIGS_LIMIT=40
PARALLEL_LIMIT=10

echo -n >"$SCAN_HISTORY"
mkdir -p "$CACHE_DIR" "$HOME/ghost"

CONFIG_URLS=(
  "https://raw.githubusercontent.com/sinavm/SVM/main/subscriptions/xray/normal/mix"
  "https://raw.githubusercontent.com/Rayan-Config/C-Sub/main/configs/proxy.txt"
  "https://raw.githubusercontent.com/4n0nymou3/multi-proxy-config-fetcher/main/configs/proxy_configs.txt"
  "https://raw.githubusercontent.com/Mahdi0024/ProxyCollector/master/sub/proxies.txt"
  "https://raw.githubusercontent.com/Arashtelr/lab/main/FreeVPN-by-ArashZidi"
  "https://raw.githubusercontent.com/ALIILAPRO/v2rayNG-Config/main/server.txt"
  "https://raw.githubusercontent.com/liketolivefree/kobabi/main/sub.txt"
  "https://raw.githubusercontent.com/hans-thomas/v2ray-subscription/master/servers.txt"
  "https://raw.githubusercontent.com/darkvpnapp/CloudflarePlus/main/proxy"
  "https://raw.githubusercontent.com/VPNforWindowsSub/configs/master/full.txt"
  "https://raw.githubusercontent.com/mohamadfg-dev/telegram-v2ray-configs-collector/main/category/vless.txt"
  "https://raw.githubusercontent.com/mohamadfg-dev/telegram-v2ray-configs-collector/main/category/ss.txt"
  "https://raw.githubusercontent.com/mohamadfg-dev/telegram-v2ray-configs-collector/main/category/wireguard.txt"
  "https://raw.githubusercontent.com/miladtahanian/V2RayCFGDumper/main/config.txt"
  "https://raw.githubusercontent.com/Stinsonysm/GO_V2rayCollector/main/mixed_iran.txt"
  "https://raw.githubusercontent.com/ShatakVPN/ConfigForge-V2Ray/main/configs/all.txt"
  "https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/shadowsocks.txt"
  "https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/trojan.txt"
  "https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/vless.txt"
  "https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/vmess.txt"
  "https://raw.githubusercontent.com/ermaozi/get_subscribe/main/subscribe/v2ray.txt"
  "https://raw.githubusercontent.com/Barabama/FreeNodes/main/nodes/yudou66.txt"
  "https://raw.githubusercontent.com/Barabama/FreeNodes/main/nodes/blues.txt"
  "https://raw.githubusercontent.com/Barabama/FreeNodes/main/nodes/clashmeta.txt"
  "https://raw.githubusercontent.com/Barabama/FreeNodes/main/nodes/ndnode.txt"
  "https://raw.githubusercontent.com/Barabama/FreeNodes/main/nodes/nodev2ray.txt"
  "https://raw.githubusercontent.com/Barabama/FreeNodes/main/nodes/nodefree.txt"
  "https://raw.githubusercontent.com/Barabama/FreeNodes/main/nodes/v2rayshare.txt"
  "https://raw.githubusercontent.com/Barabama/FreeNodes/main/nodes/wenode.txt"
  "https://raw.githubusercontent.com/Firmfox/Proxify/main/v2ray_configs/seperated_by_protocol/shadowsocks.txt"
  "https://raw.githubusercontent.com/Firmfox/Proxify/main/v2ray_configs/seperated_by_protocol/warp.txt"
  "https://raw.githubusercontent.com/Firmfox/Proxify/main/v2ray_configs/seperated_by_protocol/trojan.txt"
  "https://raw.githubusercontent.com/Firmfox/Proxify/main/v2ray_configs/seperated_by_protocol/vmess.txt"
  "https://raw.githubusercontent.com/Firmfox/Proxify/main/v2ray_configs/seperated_by_protocol/other.txt"
  "https://raw.githubusercontent.com/Firmfox/Proxify/main/v2ray_configs/seperated_by_protocol/vless.txt"
  "https://raw.githubusercontent.com/MatinGhanbari/v2ray-CONFIGs/main/subscriptions/v2ray/all_sub.txt"
  "https://raw.githubusercontent.com/coldwater-10/V2ray-Config-Lite/main/All_Configs_Sub.txt"
  "https://raw.githubusercontent.com/barry-far/V2ray-Config/main/All_Configs_Sub.txt"
  "https://raw.githubusercontent.com/SoliSpirit/v2ray-configs/main/all_configs.txt"
  "https://raw.githubusercontent.com/ebrasha/free-v2ray-public-list/main/all_extracted_configs.txt"
  "https://raw.githubusercontent.com/Kolandone/v2raycollector/main/config.txt"
  "https://raw.githubusercontent.com/Epodonios/v2ray-CONFIGs/main/All_Configs_Sub.txt"
  "https://raw.githubusercontent.com/liMilCo/v2r/main/all_configs.txt"
)

BASE64_URLS=(
  "https://raw.githubusercontent.com/mahdibland/V2RayAggregator/master/Eternity"
  "https://raw.githubusercontent.com/peasoft/NoMoreWalls/master/list.txt"
  "https://raw.githubusercontent.com/Surfboardv2ray/TGParse/main/splitted/mixed"
  "https://raw.githubusercontent.com/itsyebekhe/PSG/main/subscriptions/xray/base64/mix"
  "https://raw.githubusercontent.com/roosterkid/openproxylist/main/V2RAY_BASE64.txt"
  "https://raw.githubusercontent.com/mahsanet/MahsaFreeConfig/main/mci/sub_1.txt"
  "https://raw.githubusercontent.com/mahsanet/MahsaFreeConfig/main/mtn/sub_1.txt"
  "https://raw.githubusercontent.com/mahsanet/MahsaFreeConfig/main/segment/test_sub.txt"
  "https://raw.githubusercontent.com/R-the-coder/V2ray-configs/main/config.txt"
  "https://raw.githubusercontent.com/Joker-funland/V2ray-configs/main/config.txt"
  "https://raw.githubusercontent.com/AzadNetCH/Clash/main/AzadNet.txt"
  "https://raw.githubusercontent.com/DaBao-Lee/V2RayN-NodeShare/main/base64"
  "https://raw.githubusercontent.com/ripaojiedian/freenode/main/sub"
)

cd "/tmp" || true
echo "🔍 $(wc -l <"$CONFIGS") Previous Configs"

while ! ping -c 1 -W 2 "217.218.127.127" >/dev/null 2>&1; do
  echo "❌ Connectivity test failed."
  sleep 2
done

throttle() {
  if [ -f "/etc/openwrt_release" ]; then
    local CPU_USAGE MEM_AVAILABLE
    CPU_USAGE=$(
      top -b -n 1 | awk '
        $1=="PID" {in_table=1; next}
        in_table && $1 ~ /^[0-9]+$/ {sum += $7}
        END {printf "%d\n", int(sum+0.5)}
      '
    )
    MEM_AVAILABLE=$(free -m | awk '/^Mem:/ {print $7}')
    if [ "$CPU_USAGE" -gt 90 ] || [ "$MEM_AVAILABLE" -lt 100000 ]; then
      wait
    fi
  fi
  if [ "$(pgrep -f "/usr/bin/sing-box run -c *" | wc -l)" -ge "$PARALLEL_LIMIT" ]; then
    sleep 1
  fi
  if [ "$(wc -l <"$CONFIGS")" -ge "$CONFIGS_LIMIT" ]; then
    if [ -f "/etc/init.d/ghost" ]; then
      if ! test_socks_port "9802"; then
        /etc/init.d/ghost restart
      fi
    fi
    wait
    exit
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

test_socks_port() {
  local SOCKS_PORT=$1
  if [ "$(curl -s -L -I --max-time 3 --socks5-hostname "127.0.0.1:$SOCKS_PORT" -o "/dev/null" -w "%{http_code}" "https://telegram.org/")" -eq 200 ] && \
    [ "$(curl -s -L -I --max-time 3 --retry 2 --socks5-hostname "127.0.0.1:$SOCKS_PORT" -o "/dev/null" -w "%{http_code}" "https://www.oracle.com/")" -eq 200 ] && \
    [ "$(curl -s -L -I --max-time 3 --retry 2 --socks5-hostname "127.0.0.1:$SOCKS_PORT" -o "/dev/null" -w "%{http_code}" "https://aws.amazon.com/")" -eq 200 ] && \
    [ "$(curl -s -L -I --max-time 3 --retry 2 --socks5-hostname "127.0.0.1:$SOCKS_PORT" -o "/dev/null" -w "%{http_code}" "https://gemini.google.com/")" -eq 200 ]; then
    return 0
  else
    return 1
  fi
}

process_config() {
  local CONFIG SOCKS_PORT RAW_CONFIG PARSED_CONFIG FINAL_CONFIG
  CONFIG="$1"
  SOCKS_PORT="$(get_random_port)"
  RAW_CONFIG="/tmp/scanner.raw.${SOCKS_PORT}"
  PARSED_CONFIG="/tmp/scanner.parsed.${SOCKS_PORT}"
  FINAL_CONFIG="/tmp/scanner.final.${SOCKS_PORT}"

  if [[ -z $CONFIG ]] || [[ $CONFIG == \#* ]] || [ "$(wc -l <"$CONFIGS")" -ge "$CONFIGS_LIMIT" ]; then
    return
  fi

  echo "$CONFIG" >"$RAW_CONFIG"

  if grep -qxF "$CONFIG" "$CONFIGS" || /usr/bin/hiddify-cli parse "$RAW_CONFIG" -o "$PARSED_CONFIG" | grep -qiE "error|fatal"; then
    rm -rf "$RAW_CONFIG" "$PARSED_CONFIG"
    return
  fi

  TAG=$(jq -r '(.outbounds[0]? // empty) | "\(.type)-\(.server)-\(.server_port)"' "$PARSED_CONFIG")
  if grep -q "$TAG" "$SCAN_HISTORY"; then
    return
  fi
  echo "$TAG" >>"$SCAN_HISTORY"

  jq --argjson port "$SOCKS_PORT" '{
    "inbounds": [
      { "type": "mixed", "tag": "mixed-in", "listen": "127.0.0.1", "listen_port": $port }
    ],
    "outbounds": .outbounds
  }' "$PARSED_CONFIG" >"$FINAL_CONFIG"

  /usr/bin/sing-box run -c "$FINAL_CONFIG" 2>&1 | while read -r LINE; do
    if echo "$LINE" | grep -q "sing-box started"; then
      if test_socks_port "$SOCKS_PORT"; then
        echo "🚀 Found ($(wc -l <"$CONFIGS") / $(wc -l <"$SCAN_HISTORY"))"
        echo "$CONFIG" >>"$CONFIGS"
      fi
      kill -9 $(pgrep -f "/usr/bin/sing-box run -c $FINAL_CONFIG")
    fi
  done

  rm -rf "$RAW_CONFIG" "$PARSED_CONFIG" "$FINAL_CONFIG"
}

test_subscriptions_local() {
  cat "$CONFIGS" >>"$TMP_CONFIGS"
  echo -n >"$CONFIGS"
  echo "⏳ Testing $CONFIGS"
  while IFS= read -r CONFIG; do
    throttle
    process_config "$CONFIG" &
  done <"$TMP_CONFIGS"
  wait
  echo -n >"$TMP_CONFIGS"
}

test_subscriptions() {
  SUBSCRIPTION="$1"
  IS_BASE64="$2"
  CACHE_FILE="$CACHE_DIR/$(echo "$SUBSCRIPTION" | md5sum | awk '{print $1}')"
  echo "⏳ Testing $SUBSCRIPTION"
  if curl -L --max-time 60 -o "$CACHE_FILE" "$SUBSCRIPTION"; then
    echo "✅ Downloaded $SUBSCRIPTION"
  elif [ -f "$CACHE_FILE" ]; then
    echo "⚠️ Using cashed $SUBSCRIPTION"
  else
    echo "❌ Failed to download $SUBSCRIPTION"
    return
  fi
  if [ "$IS_BASE64" = "true" ]; then
    while IFS= read -r CONFIG; do
      throttle
      process_config "$CONFIG" &
    done < <(base64 --decode "$CACHE_FILE" 2>/dev/null)
  else
    while IFS= read -r CONFIG; do
      throttle
      process_config "$CONFIG" &
    done <"$CACHE_FILE"
  fi
}

main() {
  test_subscriptions_local
  for SUBSCRIPTION in "${CONFIG_URLS[@]}"; do
    test_subscriptions "$SUBSCRIPTION" "false"
  done
  for SUBSCRIPTION in "${BASE64_URLS[@]}"; do
    test_subscriptions "$SUBSCRIPTION" "true"
  done
}

main "$@"
