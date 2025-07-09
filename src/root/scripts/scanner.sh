#!/bin/bash

TEST_URL="https://www.gstatic.com/generate_204"
TEST_INDEX="/root/hiddify/test.index"
SUBSCRIPTION="/root/hiddify/subscription.conf"
HIDDIFY_BACKUP="/tmp/configs.backup"
HIDDIFY_CONFIGS="/root/hiddify/configs.conf"
BASE_SOCKS_PORT=1400
PORT_COUNTER=$BASE_SOCKS_PORT
CURRENT_INDEX=0
START_INDEX=0
MAX_JOBS=10

CONFIG_URLS=(
  "https://cdn.jsdelivr.net/gh/roosterkid/openproxylist@main/V2RAY_RAW.txt"
  "https://cdn.jsdelivr.net/gh/MatinGhanbari/v2ray-CONFIGs@main/subscriptions/v2ray/all_sub.txt"
  "https://cdn.jsdelivr.net/gh/hamed1124/PORT-based-v2ray-CONFIGs@main/All-Configs.txt"
  "https://cdn.jsdelivr.net/gh/barry-far/V2ray-Config@main/All_Configs_Sub.txt"
  "https://cdn.jsdelivr.net/gh/Epodonios/v2ray-CONFIGs@main/All_Configs_Sub.txt"
  "https://raw.githubusercontent.com/SoliSpirit/v2ray-configs/refs/heads/main/all_configs.txt"
)

cd "/tmp" || {
  echo "❌ Failed to cd /tmp"
  exit 1
}

sort "$HIDDIFY_CONFIGS" | uniq | grep -v '^$' >"$HIDDIFY_BACKUP"
echo "" >"$HIDDIFY_CONFIGS"

if [ -f "$SUBSCRIPTION" ] && [ "$(wc -l <"$SUBSCRIPTION")" -ge 1 ]; then
  if [[ -f "$TEST_INDEX" ]]; then
    START_INDEX=$(<"$TEST_INDEX")
  fi
else
  for CONFIG_URL in "${CONFIG_URLS[@]}"; do
    echo "🔄 Downloading: $CONFIG_URL"
    if curl -f --max-time 60 --retry 2 "$CONFIG_URL" >>"$SUBSCRIPTION"; then
      echo "✅ Subscription Saved: $CONFIG_URL"
    else
      echo "❌ Failed to fetch: $CONFIG_URL"
    fi
  done
fi

echo "ℹ️ $(wc -l <"$SUBSCRIPTION") Config Loaded, $(wc -l <"$HIDDIFY_BACKUP") Config Found, Starting from $START_INDEX"

test_config() {
  local CONFIG="$1"
  local SOCKS_PORT="$2"
  TEMP_CONFIG="/tmp/config.${SOCKS_PORT}.conf"
  PARSED_CONFIG="/tmp/parsed.${SOCKS_PORT}.json"
  XRAY_CONFIG="/tmp/xray.${SOCKS_PORT}.json"

  echo "$CONFIG" >"$TEMP_CONFIG"

  if [[ -z "$CONFIG" ]] || [[ "$CONFIG" == \#* ]]; then
    echo "⚠️ Skipping empty or commented config"
    return
  fi

  if hiddify-cli parse "$TEMP_CONFIG" -o "$PARSED_CONFIG" 2>&1 | grep -qiE "error|fatal"; then
    echo "🚫 Failed to parse config ${CONFIG}"
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
  }' "$PARSED_CONFIG" >"$XRAY_CONFIG"

  if [ ! -e "/tmp/sing-box-test-${SOCKS_PORT}" ]; then
    ln -s "/usr/bin/sing-box" "/tmp/sing-box-test-${SOCKS_PORT}"
  fi

  /tmp/sing-box-test-${SOCKS_PORT} run -c "$XRAY_CONFIG" 2>&1 | while read -r line; do
    if echo "$line" | grep -q "sing-box started"; then
      if curl -s --max-time 1 --retry 1 --proxy "socks://127.0.0.1:$SOCKS_PORT" "$TEST_URL"; then
        echo "✅ Successfully connected ${CONFIG}"
        echo "$CONFIG" >>"$HIDDIFY_CONFIGS"
        killall "sing-box-test-${SOCKS_PORT}"
        wait
      else
        echo "❌ Failed to connect ${CONFIG}"
        killall "sing-box-test-${SOCKS_PORT}"
        wait
      fi
    fi
  done
}

while IFS= read -r CONFIG; do
  test_config "$CONFIG" "$PORT_COUNTER"
  ((PORT_COUNTER++))
done <"$HIDDIFY_BACKUP"

while IFS= read -r CONFIG; do
  ((CURRENT_INDEX++))
  if ((START_INDEX >= CURRENT_INDEX)); then
    continue
  fi
  while (($(jobs -r | wc -l) >= MAX_JOBS)); do
    echo "$CURRENT_INDEX" >"$TEST_INDEX"
    sleep 1
  done
  test_config "$CONFIG" "$PORT_COUNTER" &
  ((PORT_COUNTER++))
  if ((PORT_COUNTER >= BASE_SOCKS_PORT + 20)); then
    PORT_COUNTER=$BASE_SOCKS_PORT
  fi
done <"$SUBSCRIPTION"

wait
echo "🎉 $(wc -l <"$SUBSCRIPTION") Config Tested, $(wc -l <"$HIDDIFY_CONFIGS") Config Found"
rm -rfv $TEST_INDEX $SUBSCRIPTION $HIDDIFY_BACKUP /tmp/config.*.conf /tmp/parsed.*.json /tmp/xray.*.json
