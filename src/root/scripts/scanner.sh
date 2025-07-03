#!/bin/bash

OUTPUT_FILE="/root/hiddify/configs.conf"
TEMP_CONFIG="/tmp/test.conf"
PARSED_CONFIG="/tmp/parsed.json"
XRAY_CONFIG="/tmp/xray.json"
SOCKS_PORT=22334

ALL_CONFIGS=$(cat "$OUTPUT_FILE")

CONFIG_URLS=(
  "https://cdn.jsdelivr.net/gh/roosterkid/openproxylist@main/V2RAY_RAW.txt"
#  "https://raw.githubusercontent.com/SoliSpirit/v2ray-configs/refs/heads/main/all_configs.txt"
#  "https://cdn.jsdelivr.net/gh/barry-far/V2ray-Config@main/All_Configs_Sub.txt"
#  "https://cdn.jsdelivr.net/gh/Epodonios/v2ray-CONFIGs@main/All_Configs_Sub.txt"
#  "https://cdn.jsdelivr.net/gh/hamed1124/PORT-based-v2ray-CONFIGs@main/All-Configs.txt"
#  "https://cdn.jsdelivr.net/gh/MatinGhanbari/v2ray-CONFIGs@main/subscriptions/v2ray/all_sub.txt"
)

cd "/tmp" || {
  echo "❌ Failed to cd /tmp"
  exit 1
}

for CONFIG_URL in "${CONFIG_URLS[@]}"; do
  echo "🔄 Downloading: $CONFIG_URL"
  HASHED_FILE="/tmp/$(echo -n "$CONFIG_URL" | md5sum | cut -d ' ' -f1).conf"

  if [[ -f "$HASHED_FILE" ]]; then
    echo "⏩ Cached already: $HASHED_FILE"
  else
    if curl --max-time 60 "$CONFIG_URL" -o "$HASHED_FILE"; then
      echo "✅ Saved to cache: $HASHED_FILE"
    else
      echo "❌ Failed to fetch: $CONFIG_URL"
      rm -f "$HASHED_FILE"
      continue
    fi
  fi
  ALL_CONFIGS+=$'\n'"$(cat "$HASHED_FILE")"$'\n'
done

echo "" >"$OUTPUT_FILE"

while IFS= read -r CONFIG; do
  echo "🔄 Testing $CONFIG"
  echo "$CONFIG" >"$TEMP_CONFIG"
  rm -f $PARSED_CONFIG $XRAY_CONFIG

  if [[ -z "$CONFIG" ]]; then
    echo "❌ config is empty"
    continue
  fi

  if [[ "$CONFIG" == \#* ]]; then
    echo "❌ config is commented"
    continue
  fi

  if grep -qxF "$CONFIG" "$OUTPUT_FILE"; then
    echo "❌ config is duplicated in $OUTPUT_FILE"
    continue
  fi

  if hiddify-cli parse "$TEMP_CONFIG" -o "$PARSED_CONFIG" 2>&1 | grep -qiE "error|fatal"; then
    echo "❌ Failed to parse config"
    continue
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

  sing-box run -c "$XRAY_CONFIG" >/dev/null 2>&1 &
  PID=$!
  sleep 1

  if curl -s --max-time 1 --proxy "socks://127.0.0.1:$SOCKS_PORT" "https://www.google.com/generate_204"; then
    echo "✅ Successfully connected"
    echo "$CONFIG" >>"$OUTPUT_FILE"
  else
    echo "❌ Failed to connect"
  fi

  kill "$PID" >/dev/null 2>&1
  wait "$PID" 2>/dev/null
done <<<"$ALL_CONFIGS"
