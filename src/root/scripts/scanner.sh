#!/bin/bash

CONFIGS="/root/ghost/configs.conf"
PREV_COUNT=$(wc -l < "$CONFIGS")
CACHE_DIR="/root/.cache/subscriptions"
CONFIGS_LIMIT=40

mkdir -p "$CACHE_DIR"

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
  "https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/vmess.txt"
  "https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/vless.txt"
  "https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/shadowsocks.txt"
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
  "https://vpn.fail/free-proxy/v2ray"
)

BASE64_URLS=(
  "https://raw.githubusercontent.com/mahsanet/MahsaFreeConfig/main/mci/sub_1.txt"
  "https://raw.githubusercontent.com/mahsanet/MahsaFreeConfig/main/mtn/sub_1.txt"
  "https://raw.githubusercontent.com/mahsanet/MahsaFreeConfig/main/segment/test_sub.txt"
  "https://raw.githubusercontent.com/Joker-funland/V2ray-configs/main/config.txt"
  "https://raw.githubusercontent.com/AzadNetCH/Clash/main/AzadNet.txt"
  "https://raw.githubusercontent.com/DaBao-Lee/V2RayN-NodeShare/main/base64"
  "https://raw.githubusercontent.com/ripaojiedian/freenode/main/sub"
)

cd "/tmp" || true
echo "ℹ️ $PREV_COUNT Previous Configs Found"

if curl -s -L -I --max-time 1 --socks5-hostname "127.0.0.1:9801" -o "/dev/null" "https://raw.githubusercontent.com/amaleky/WrtMate/main/install.sh"; then
  PROXY_OPTION="--socks5-hostname 127.0.0.1:9801"
fi

if ! ping -c 1 -W 2 "217.218.155.155" > /dev/null 2>&1; then
  echo "ERROR: Connectivity test failed."
  exit 0
fi

process_config() {
  local CONFIG="$1"
  local SOCKS_PORT=9898
  local TEMP_CONFIG="/tmp/test.config.conf"
  local PARSED_CONFIG="/tmp/test.parsed.json"
  local JSON_CONFIG="/tmp/test.xray.json"

  if [ "$(wc -l < "$CONFIGS")" -ge $CONFIGS_LIMIT ]; then
    echo "🎉 $(wc -l < "$CONFIGS") Configs Found (previous: $PREV_COUNT)"
    exit 0
  fi

  if [[ -z "$CONFIG" ]] || [[ "$CONFIG" == \#* ]]; then
    return
  fi

  echo "$CONFIG" >"$TEMP_CONFIG"

  if grep -qxF "$CONFIG" "$CONFIGS" || /usr/bin/hiddify-cli parse "$TEMP_CONFIG" -o "$PARSED_CONFIG" 2>&1 | grep -qiE "error|fatal"; then
    return
  fi

  jq --argjson port "$SOCKS_PORT" '. + {
    "inbounds": [
      {
        "type": "mixed",
        "tag": "mixed-in",
        "listen": "127.0.0.1",
        "listen_port": $port
      }
    ]
  }' "$PARSED_CONFIG" >"$JSON_CONFIG"

  if [[ ! -f "/tmp/sing-box-$SOCKS_PORT" ]]; then
    ln -s "/usr/bin/sing-box" "/tmp/sing-box-$SOCKS_PORT"
  fi

  /tmp/sing-box-$SOCKS_PORT run -c "$JSON_CONFIG" 2>&1 | while read -r LINE; do
    if echo "$LINE" | grep -q "sing-box started"; then
      if [ "$(curl -s -L -I --max-time 1 --socks5-hostname "127.0.0.1:$SOCKS_PORT" -o "/dev/null" -w "%{http_code}" "https://developer.android.com/")" -eq 200 ]; then
        echo "✅ Successfully ($(wc -l < "$CONFIGS")) ${CONFIG}"
        echo "$CONFIG" >> "$CONFIGS"
      fi
      kill -9 $(pgrep -f "/tmp/sing-box-$SOCKS_PORT run -c .*")
      wait
      rm -rf "$TEMP_CONFIG" "$PARSED_CONFIG" "$JSON_CONFIG" "/tmp/sing-box-$SOCKS_PORT"
    fi
  done
}

BACKUP="$(cat "$CONFIGS")"
echo -n >"$CONFIGS"

echo "⏳ Testing $CONFIGS"
while IFS= read -r CONFIG; do
  process_config "$CONFIG"
done <<< "$BACKUP"

for SUBSCRIPTION in "${CONFIG_URLS[@]}"; do
  CACHE_FILE="$CACHE_DIR/$(echo "$SUBSCRIPTION" | md5sum | awk '{print $1}')"
  if curl -L $PROXY_OPTION --max-time 60 -o "$CACHE_FILE" "$SUBSCRIPTION"; then
    echo "✅ Downloaded subscription $SUBSCRIPTION"
  elif [ -f "$CACHE_FILE" ]; then
    echo "⚠️ Using cashed $SUBSCRIPTION"
  else
    echo "❌ Failed to download $SUBSCRIPTION"
    continue
  fi
  if [ "$(wc -l < "$CONFIGS")" -lt $CONFIGS_LIMIT ]; then
    while IFS= read -r CONFIG; do
      process_config "$CONFIG"
    done < "$CACHE_FILE"
  fi
done

for SUBSCRIPTION in "${BASE64_URLS[@]}"; do
  CACHE_FILE="$CACHE_DIR/$(echo "$SUBSCRIPTION" | md5sum | awk '{print $1}')"
  if curl -L $PROXY_OPTION --max-time 60 -o "$CACHE_FILE" "$SUBSCRIPTION"; then
    echo "✅ Downloaded subscription $SUBSCRIPTION"
  elif [ -f "$CACHE_FILE" ]; then
    echo "⚠️ Using cashed $SUBSCRIPTION"
  else
    echo "❌ Failed to download $SUBSCRIPTION"
    continue
  fi
  if [ "$(wc -l < "$CONFIGS")" -lt $CONFIGS_LIMIT ]; then
    base64 --decode "$CACHE_FILE" 2>/dev/null | while IFS= read -r CONFIG; do
      process_config "$CONFIG"
    done
  fi
done

rm -rf /tmp/test* /tmp/sing-box*
