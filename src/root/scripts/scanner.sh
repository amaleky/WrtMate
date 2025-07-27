#!/bin/bash

TEST_URL="http://gstatic.com/generate_204"
TEST_PING="217.218.155.155"
SUBSCRIPTION="/tmp/ghost-subscription.conf"
CONFIGS="/root/ghost/configs.conf"
BACKUP="/tmp/ghost-backup.conf"
PREV_COUNT=$(wc -l < "$CONFIGS")
MAX_PARALLEL=5
JOBS=0

CONFIG_URLS=(
  "https://raw.githubusercontent.com/roosterkid/openproxylist/main/V2RAY_RAW.txt"
  "https://raw.githubusercontent.com/MatinGhanbari/v2ray-CONFIGs/main/subscriptions/v2ray/all_sub.txt"
  "https://raw.githubusercontent.com/hamed1124/PORT-based-v2ray-CONFIGs/main/All-Configs.txt"
  "https://raw.githubusercontent.com/barry-far/V2ray-Config/main/All_Configs_Sub.txt"
  "https://raw.githubusercontent.com/Epodonios/v2ray-CONFIGs/main/All_Configs_Sub.txt"
  "https://raw.githubusercontent.com/SoliSpirit/v2ray-configs/main/all_configs.txt"
)

cd "/tmp" || true

if curl --max-time 2 --retry 2 --socks5 127.0.0.1:12334 --silent --output "/dev/null" "$TEST_URL"; then
  PROXY_OPTION="--socks5 127.0.0.1:12334"
elif curl --max-time 2 --retry 2 --socks5 127.0.0.1:22334 --silent --output "/dev/null" "$TEST_URL"; then
  PROXY_OPTION="--socks5 127.0.0.1:22334"
elif curl --max-time 2 --retry 2 --socks5 127.0.0.1:8086 --silent --output "/dev/null" "$TEST_URL"; then
  PROXY_OPTION="--socks5 127.0.0.1:8086"
elif curl --max-time 2 --retry 2 --socks5 127.0.0.1:1080 --silent --output "/dev/null" "$TEST_URL"; then
  PROXY_OPTION="--socks5 127.0.0.1:1080"
else
  PROXY_OPTION=""
fi

if [ -f "$SUBSCRIPTION" ] && [ "$(wc -l <"$SUBSCRIPTION")" -ge 1 ]; then
  echo "ℹ️ $(wc -l <"$SUBSCRIPTION") Config Loaded (cache)"
else
  curl -f --max-time 60 --retry 2 $PROXY_OPTION "https://the3rf.com/api.php" | jq -r '.[]' >> "$SUBSCRIPTION"
  for CONFIG_URL in "${CONFIG_URLS[@]}"; do
    echo "🔄 Downloading: $CONFIG_URL"
    if curl -f --max-time 60 --retry 2 $PROXY_OPTION "$CONFIG_URL" >>"$SUBSCRIPTION"; then
      echo "✅ Subscription Saved: $CONFIG_URL"
    else
      echo "❌ Failed to fetch: $CONFIG_URL"
    fi
  done
  echo "ℹ️ $(wc -l <"$SUBSCRIPTION") Config Loaded"
fi

cat "$CONFIGS" >"$BACKUP"
echo "" >"$CONFIGS"

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

  if hiddify-cli parse "$TEMP_CONFIG" -o "$PARSED_CONFIG" 2>&1 | grep -qiE "error|fatal"; then
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
      if curl -s --max-time 1 --retry 1 --proxy "socks://127.0.0.1:$SOCKS_PORT" "$TEST_URL"; then
        echo "✅ Successfully ($(wc -l < "$CONFIGS")) ${CONFIG}"
        grep -qxF "$CONFIG" "$CONFIGS" || echo "$CONFIG" >> "$CONFIGS"
      else
        ESCAPED=$(printf '%s\n' "$CONFIG" | sed 's/[]\/$*.^[]/\\&/g')
        sed -i "/^$ESCAPED$/d" "$CONFIGS"
      fi
      rm -rf "/tmp/test.${SOCKS_PORT}.*"
      kill -9 "$(pgrep -f "/tmp/sing-box-$SOCKS_PORT run -c .*")"
      wait
    fi
  done
}

cat "$BACKUP" "$SUBSCRIPTION" | while IFS= read -r CONFIG; do
  if [ "$(wc -l < "$CONFIGS")" -ge 20 ]; then
    echo "🎉 $(wc -l < "$CONFIGS") Configs Found (previous: $PREV_COUNT)"
    exit 0
  fi

  while ! ping -c 1 -W 2 "$TEST_PING" > /dev/null 2>&1 || [ "$(pgrep -f "/tmp/sing-box-.* run -c .*" | wc -l)" -ge $MAX_PARALLEL ]; do
    sleep 1
  done

  while [[ $JOBS -ge $MAX_PARALLEL ]]; do
    wait -n
    ((JOBS--))
  done

  if [[ -z "$CONFIG" ]] || [[ "$CONFIG" == \#* ]]; then
    continue
  fi

  test_config "$CONFIG" &
  ((JOBS++))
done

wait
