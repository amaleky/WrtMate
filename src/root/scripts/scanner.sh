#!/bin/bash

TEST_SANCTION_URL="https://developer.android.com/"
TEST_PING="217.218.155.155"
CONFIGS="/root/ghost/configs.conf"
PREV_COUNT=$(wc -l < "$CONFIGS")
CONFIGS_LIMIT=40
MAX_PARALLEL=5

CONFIG_URLS=(
  "https://raw.githubusercontent.com/Arashtelr/lab/main/FreeVPN-by-ArashZidi"
  "https://raw.githubusercontent.com/ermaozi/get_subscribe/main/subscribe/v2ray.txt"
  "https://raw.githubusercontent.com/hans-thomas/v2ray-subscription/master/servers.txt"
  "https://raw.githubusercontent.com/ALIILAPRO/v2rayNG-Config/main/server.txt"
  "https://raw.githubusercontent.com/liketolivefree/kobabi/main/sub.txt"
  "https://raw.githubusercontent.com/miladtahanian/V2RayCFGDumper/main/config.txt"
  "https://raw.githubusercontent.com/Stinsonysm/GO_V2rayCollector/main/mixed_iran.txt"
  "https://raw.githubusercontent.com/roosterkid/openproxylist/main/V2RAY_RAW.txt"
  "https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/vmess.txt"
  "https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/vless.txt"
  "https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/shadowsocks.txt"
  "https://raw.githubusercontent.com/Rayan-Config/C-Sub/main/configs/proxy.txt"
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
)

BASE64_URLS=(
  "https://raw.githubusercontent.com/Joker-funland/V2ray-configs/main/config.txt"
  "https://raw.githubusercontent.com/AzadNetCH/Clash/main/AzadNet.txt"
  "https://raw.githubusercontent.com/DaBao-Lee/V2RayN-NodeShare/main/base64"
  "https://raw.githubusercontent.com/ripaojiedian/freenode/main/sub"
)

cd "/tmp" || true
echo "ℹ️ $PREV_COUNT Previous Configs Found"

while ! ping -c 1 -W 2 "$TEST_PING" > /dev/null 2>&1 || ! top -bn1 | grep -v 'grep' | grep '/tmp/etc/passwall2/bin/' | grep 'default' | grep 'global' > /dev/null; do
  sleep 1
done

if curl -I --max-time 3 --retry 1 --socks5 "127.0.0.1:22335" --silent --output "/dev/null" "$TEST_SANCTION_URL"; then
  PROXY_OPTION="--socks5 127.0.0.1:22335"
else
  PROXY_OPTION=""
fi

get_random_port() {
  for i in $(seq 1 100); do
    port=$(( (RANDOM % 16384) + 49152 ))
    nc -z 127.0.0.1 "$port" 2>/dev/null
    if [ $? -ne 0 ]; then
      echo "$port"
      return 0
    fi
  done
  echo "❌ Could not find free port after 100 tries" >&2
  return 1
}


test_config() {
  local CONFIG="$1"
  SOCKS_PORT=$(get_random_port)
  local TEMP_CONFIG="/tmp/test.${SOCKS_PORT}.config.conf"
  local PARSED_CONFIG="/tmp/test.${SOCKS_PORT}.parsed.json"
  local JSON_CONFIG="/tmp/test.${SOCKS_PORT}.xray.json"

  echo "$CONFIG" >"$TEMP_CONFIG"

  if grep -qxF "$CONFIG" "$CONFIGS" || hiddify-cli parse "$TEMP_CONFIG" -o "$PARSED_CONFIG" 2>&1 | grep -qiE "error|fatal"; then
    return
  fi

  jq --argjson port "$SOCKS_PORT" '. + {
    "inbounds": [
      {
        "type": "socks",
        "tag": "socks-inbound",
        "listen": "127.0.0.1",
        "listen_port": $port
      }
    ]
  }' "$PARSED_CONFIG" >"$JSON_CONFIG"

  if [[ ! -f "/tmp/sing-box-$SOCKS_PORT" ]]; then
    ln -s "/usr/bin/sing-box" "/tmp/sing-box-$SOCKS_PORT"
  fi

  /tmp/sing-box-$SOCKS_PORT run -c "$JSON_CONFIG" 2>&1 | while read -r line; do
    if echo "$line" | grep -q "sing-box started"; then
      if curl -I --max-time 3 --retry 1 --socks5 "127.0.0.1:$SOCKS_PORT" --silent --output "/dev/null" "$TEST_SANCTION_URL"; then
        echo "✅ Successfully ($(wc -l < "$CONFIGS")) ${CONFIG}"
        echo "$CONFIG" >> "$CONFIGS"
      fi
      kill -9 $(pgrep -f "/tmp/sing-box-$SOCKS_PORT run -c .*")
      wait
      rm -rf "$TEMP_CONFIG" "$PARSED_CONFIG" "$JSON_CONFIG" "/tmp/sing-box-$SOCKS_PORT"
    fi
  done
}

process_config() {
  local CONFIG="$1"

  if [ "$(wc -l < "$CONFIGS")" -ge $CONFIGS_LIMIT ]; then
    echo "🎉 $(wc -l < "$CONFIGS") Configs Found (previous: $PREV_COUNT)"
    exit 0
  fi

  while [ "$(pgrep -f "/tmp/sing-box-.* run -c .*" | wc -l)" -ge "$MAX_PARALLEL" ]; do
    sleep 1
  done

  if [[ -z "$CONFIG" ]] || [[ "$CONFIG" == \#* ]]; then
    return
  fi

  test_config "$CONFIG" &
}

BACKUP="$(cat "$CONFIGS")"
echo "" >"$CONFIGS"
echo "⏳ Testing $CONFIGS"
while IFS= read -r CONFIG; do
  process_config "$CONFIG"
done <<< "$BACKUP"

echo "⏳ Testing https://the3rf.com/api.php"
curl -f --max-time 60 --retry 2 $PROXY_OPTION "https://the3rf.com/api.php" | jq -r '.[]' | while IFS= read -r CONFIG; do
  process_config "$CONFIG"
done

for SUBSCRIPTION in "${CONFIG_URLS[@]}"; do
  echo "⏳ Testing $SUBSCRIPTION"
  curl -f --max-time 300 --retry 2 $PROXY_OPTION "$SUBSCRIPTION" | while IFS= read -r CONFIG; do
    process_config "$CONFIG"
  done
done

for SUBSCRIPTION in "${BASE64_URLS[@]}"; do
  echo "⏳ Testing $SUBSCRIPTION"
  curl -f --max-time 300 --retry 2 $PROXY_OPTION "$SUBSCRIPTION" | base64 --decode | while IFS= read -r CONFIG; do
    process_config "$CONFIG"
  done
done

rm -rf /tmp/test* /tmp/sing-box*
