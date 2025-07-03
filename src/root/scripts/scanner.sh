#!/bin/bash

TEST_URL="https://www.gstatic.com/generate_204"
OUTPUT_FILE="/root/hiddify/configs.conf"
HASH_DIR="/root/hiddify/ignored"
BASE_SOCKS_PORT=1400
ALL_CONFIGS=$(cat "$OUTPUT_FILE")
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

if [[ ! -d "$HASH_DIR" ]]; then
  mkdir -p "$HASH_DIR"
fi

for CONFIG_URL in "${CONFIG_URLS[@]}"; do
  echo "🔄 Downloading: $CONFIG_URL"
  HASHED_FILE="/tmp/$(echo -n "$CONFIG_URL" | md5sum | cut -d ' ' -f1).conf"
  if [[ -f "$HASHED_FILE" ]]; then
    echo "⏩ Cached already: $HASHED_FILE"
  else
    if curl --max-time 60 --retry 2 "$CONFIG_URL" -o "$HASHED_FILE"; then
      echo "✅ Saved to cache: $HASHED_FILE"
    else
      echo "❌ Failed to fetch: $CONFIG_URL"
      rm -f "$HASHED_FILE"
      continue
    fi
  fi
  ALL_CONFIGS+=$'\n'"$(cat "$HASHED_FILE")"$'\n'
  echo "" >"$OUTPUT_FILE"
done

test_config() {
  local CONFIG="$1"
  local SHORT_CONFIG="${CONFIG:0:50}..."
  local SOCKS_PORT="$2"
  TEMP_CONFIG="/tmp/config.${SOCKS_PORT}.conf"
  PARSED_CONFIG="/tmp/parsed.${SOCKS_PORT}.json"
  XRAY_CONFIG="/tmp/xray.${SOCKS_PORT}.json"

  HASH_FILE="$HASH_DIR/$(echo -n "$CONFIG" | sha256sum | cut -d ' ' -f1)"

  if [[ -f "$HASH_FILE" ]]; then
    # echo "⚡️ Config Already tested ${SHORT_CONFIG}"
    return
  fi

  echo "$CONFIG" >"$TEMP_CONFIG"

  if grep -qxF "$CONFIG" "$OUTPUT_FILE"; then
    echo "⚠️ Config is duplicated in $OUTPUT_FILE"
    return
  fi

  if [[ -z "$CONFIG" ]] || [[ "$CONFIG" == \#* ]]; then
    # echo "⚠️ Skipping empty or commented config"
    return
  fi

  if hiddify-cli parse "$TEMP_CONFIG" -o "$PARSED_CONFIG" 2>&1 | grep -qiE "error|fatal"; then
    # echo "🚫 Failed to parse config ${SHORT_CONFIG}"
    touch "$HASH_FILE"
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
        echo "✅ Successfully connected ${SHORT_CONFIG}"
        flock "$OUTPUT_FILE" -c "echo '$CONFIG' >> '$OUTPUT_FILE'"
        killall "sing-box-test-${SOCKS_PORT}"
        wait
      else
        # echo "❌ Failed to connect ${SHORT_CONFIG}"
        touch "$HASH_FILE"
        killall "sing-box-test-${SOCKS_PORT}"
        wait
      fi
    fi
  done
}

PORT_COUNTER=$BASE_SOCKS_PORT

while IFS= read -r CONFIG; do
  while (($(jobs -r | wc -l) >= MAX_JOBS)); do
    sleep 1
  done
  test_config "$CONFIG" "$PORT_COUNTER" &
  ((PORT_COUNTER++))
  if ((PORT_COUNTER >= BASE_SOCKS_PORT + 20)); then
    PORT_COUNTER=$BASE_SOCKS_PORT
  fi
done <<<"$ALL_CONFIGS"

wait
echo "🎉 All tests completed."
