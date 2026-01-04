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

CONFIGS="$HOME/ghost/configs.json"
CACHE_DIR="$HOME/.cache/subscriptions"
TEST_HISTORY="/tmp/scanner.tags"
CONFIGS_LIMIT=200
PARALLEL_LIMIT=10

echo -n >"$TEST_HISTORY"
mkdir -p "$CACHE_DIR" "$HOME/ghost"
pkill -9 -f "/usr/bin/sing-box run -c /tmp/scanner.json" 2>/dev/null || true

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

normalize_tag() {
  "$@" | jq -c '
    def mkTag:
      [ (.type? // empty),
        (.server? // empty),
        (.server_port? // empty | tostring)
      ]
      | map(select(length > 0))
      | join("_");
    .tag = mkTag
  '
}

test_socks_port() {
  local OUTBOUND_JSON
  local SOCKS_PORT=$1
  local OUTBOUND_TAG=$2
  local PARSED_CONFIG=$3
  OUTBOUND_JSON="$(normalize_tag jq -c --arg tag "$OUTBOUND_TAG" '.outbounds[] | select(.tag == $tag)' "$PARSED_CONFIG")"
  NEW_TAG="$(jq -r '.tag' <<<"$OUTBOUND_JSON")"
  if grep -q "$NEW_TAG" "$TEST_HISTORY"; then
    return 0
  fi
  echo "$NEW_TAG" >> "$TEST_HISTORY"
  if [ "$(curl -sLI --max-time 3 --socks5-hostname "127.0.0.1:$SOCKS_PORT" -o "/dev/null" -w "%{http_code}" "https://telegram.org/")" -eq 200 ] && \
    [ "$(curl -sLI --max-time 3 --retry 2 --socks5-hostname "127.0.0.1:$SOCKS_PORT" -o "/dev/null" -w "%{http_code}" "https://www.oracle.com/")" -eq 200 ] && \
    [ "$(curl -sLI --max-time 3 --retry 2 --socks5-hostname "127.0.0.1:$SOCKS_PORT" -o "/dev/null" -w "%{http_code}" "https://aws.amazon.com/")" -eq 200 ] && \
    [ "$(curl -sLI --max-time 3 --retry 2 --socks5-hostname "127.0.0.1:$SOCKS_PORT" -o "/dev/null" -w "%{http_code}" "https://gemini.google.com/")" -eq 200 ] && \
    [ "$(curl -sLI --max-time 3 --retry 2 --socks5-hostname "127.0.0.1:$SOCKS_PORT" -o "/dev/null" -w "%{http_code}" "https://cloud.nx.app/favicon.ico")" -eq 200 ]; then
    echo "$OUTBOUND_JSON" >> "$CONFIGS"
    echo "✅ Found ($(wc -l <"$CONFIGS")/$(wc -l <"$TEST_HISTORY")): $NEW_TAG"
  fi
}

collect_clean_configs() {
  local FILE TEMP PARSED_CONFIG
  FILE=$1
  PARSED_CONFIG="/tmp/scanner.json"
  TEMP=$(mktemp)

  echo "$(/usr/bin/hiddify-cli parse "$FILE" -o "$PARSED_CONFIG")" >/dev/null

  jq '.outbounds = [.outbounds[] | select(.type != "xray")] |
  .inbounds = [.outbounds | to_entries | .[] | {
    type: "socks",
    tag: .value.tag,
    listen: "127.0.0.1",
    listen_port: (20800 + .key)
  }]' "$PARSED_CONFIG" > "$TEMP"

  mv "$TEMP" "$PARSED_CONFIG"

  /usr/bin/sing-box run -c "$PARSED_CONFIG" 2>&1 | while read -r LINE; do
    if echo "$LINE" | grep -q "sing-box started"; then
      echo "🚀 Testing $FILE"
      PIDS=()
      while IFS= read -r LINE; do
        OUTBOUND_TAG=$(echo "$LINE" | jq -r '.tag')
        SOCKS_PORT=$(echo "$LINE" | jq -r '.listen_port')
        if [ "$(pgrep -f "curl -sLI --max-time 3 *" | wc -l)" -ge "$PARALLEL_LIMIT" ]; then
          sleep 1
        fi
        test_socks_port "$SOCKS_PORT" "$OUTBOUND_TAG" "$PARSED_CONFIG" &
        if [ "$(wc -l <"$CONFIGS")" -ge "$CONFIGS_LIMIT" ]; then
          break
        fi
        PIDS+=($!)
      done < <(cat "$PARSED_CONFIG" | jq -c '.inbounds[]')
      for PID in "${PIDS[@]}"; do
        wait "$PID"
      done
      pkill -9 -f "/usr/bin/sing-box run -c $PARSED_CONFIG"
    fi
  done

  if [ "$(wc -l <"$CONFIGS")" -ge "$CONFIGS_LIMIT" ]; then
    exit
  fi
}

test_remote_configs() {
  local SUBSCRIPTION CACHE_FILE
  SUBSCRIPTION="$1"
  CACHE_FILE="$CACHE_DIR/$(echo "$SUBSCRIPTION" | md5sum | awk '{print $1}')"
  if curl -L --max-time 60 -o "$CACHE_FILE" "$SUBSCRIPTION"; then
    echo "✅ Downloaded $SUBSCRIPTION"
  elif [ -f "$CACHE_FILE" ]; then
    echo "⚠️ Using cashed $SUBSCRIPTION"
  else
    echo "❌ Failed to download $SUBSCRIPTION"
    return
  fi
  collect_clean_configs "$CACHE_FILE"
}

test_local_configs() {
  cp "$CONFIGS" "$CONFIGS.backup"
  echo -n >"$CONFIGS"
  if [ "$(wc -l <"$CONFIGS.backup")" -gt "0" ]; then
    collect_clean_configs "$CONFIGS.backup"
  fi
}

main() {
  test_local_configs
  for SUBSCRIPTION in "${CONFIG_URLS[@]}"; do
    test_remote_configs "$SUBSCRIPTION"
  done
  for SUBSCRIPTION in "${BASE64_URLS[@]}"; do
    test_remote_configs "$SUBSCRIPTION"
  done
}

main "$@"
