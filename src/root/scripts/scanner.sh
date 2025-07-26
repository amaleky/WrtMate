#!/bin/bash

TEST_URL="http://www.youtube.com/generate_204"
SUBSCRIPTION="/root/ghost/subscription.conf"
CONFIGS="/root/ghost/configs.conf"
MAX_PARALLEL=10
JOBS=0

CONFIG_URLS=(
  "https://raw.githubusercontent.com/roosterkid/openproxylist/main/V2RAY_RAW.txt"
  "https://raw.githubusercontent.com/MatinGhanbari/v2ray-CONFIGs/main/subscriptions/v2ray/all_sub.txt"
  "https://raw.githubusercontent.com/hamed1124/PORT-based-v2ray-CONFIGs/main/All-Configs.txt"
  "https://raw.githubusercontent.com/barry-far/V2ray-Config/main/All_Configs_Sub.txt"
  "https://raw.githubusercontent.com/Epodonios/v2ray-CONFIGs/main/All_Configs_Sub.txt"
  "https://raw.githubusercontent.com/SoliSpirit/v2ray-configs/main/all_configs.txt"
)

if [ -f "$SUBSCRIPTION" ] && [ "$(wc -l <"$SUBSCRIPTION")" -ge 1 ]; then
  echo "ℹ️ $(wc -l <"$SUBSCRIPTION") Config Loaded (cache)"
else
  for CONFIG_URL in "${CONFIG_URLS[@]}"; do
    echo "🔄 Downloading: $CONFIG_URL"
    if curl --max-time 10 --retry 2 --socks5 127.0.0.1:12334 --silent --output "/dev/null" "$TEST_URL"; then
      PROXY_OPTION="--socks5 127.0.0.1:12334"
    elif curl --max-time 10 --retry 2 --socks5 127.0.0.1:22334 --silent --output "/dev/null" "$TEST_URL"; then
      PROXY_OPTION="--socks5 127.0.0.1:22334"
    elif curl --max-time 10 --retry 2 --socks5 127.0.0.1:8086 --silent --output "/dev/null" "$TEST_URL"; then
      PROXY_OPTION="--socks5 127.0.0.1:8086"
    elif curl --max-time 10 --retry 2 --socks5 127.0.0.1:1080 --silent --output "/dev/null" "$TEST_URL"; then
      PROXY_OPTION="--socks5 127.0.0.1:1080"
    else
      PROXY_OPTION=""
    fi

    if curl -f --max-time 60 --retry 2 $PROXY_OPTION "$CONFIG_URL" >>"$SUBSCRIPTION"; then
      echo "✅ Subscription Saved: $CONFIG_URL"
    else
      echo "❌ Failed to fetch: $CONFIG_URL"
    fi
  done
  echo "ℹ️ $(wc -l <"$SUBSCRIPTION") Config Loaded"
fi

test_config() {
  local CONFIG="$1"
  local ID="$BASHPID"
  local DIRECTORY="/tmp/$ID"

  mkdir -p "$DIRECTORY"
  cd "$DIRECTORY" || true

  ln -s "/usr/bin/hiddify-cli" "$DIRECTORY/tester"

  $DIRECTORY/tester instance --config "$CONFIG" 2>&1 | while read -r LINE; do
    if echo "$LINE" | grep -q "Instance is running on port"; then
      if curl -s --max-time 1 --retry 1 --proxy "socks://$(echo "$LINE" | sed -n 's/.*socks5:\/\/\([^"]*\).*/\1/p')" "$TEST_URL"; then
        echo "✅ Successfully ($(wc -l < "$CONFIGS")) ${CONFIG}"
        grep -qxF "$CONFIG" "$CONFIGS" || echo "$CONFIG" >> "$CONFIGS"
      else
        ESCAPED=$(printf '%s\n' "$CONFIG" | sed 's/[]\/$*.^[]/\\&/g')
        sed -i "/^$ESCAPED$/d" "$CONFIGS"
      fi
      rm -rf $DIRECTORY
      kill -9 "$(pgrep -f "$DIRECTORY/tester instance --config .*")"
    fi
  done
}

PREV_COUNT=$(wc -l < "$CONFIGS")

cat "$CONFIGS" "$SUBSCRIPTION" | while IFS= read -r CONFIG; do
  FOUND_COUNT=$(wc -l < "$CONFIGS")

  if [ "$FOUND_COUNT" -gt 20 ]; then
    echo "🎉 $FOUND_COUNT Configs Found (previous: $PREV_COUNT)"
    exit 0
  fi

  while [ "$(pgrep -f "/tmp/.*/tester instance --config .*" | wc -l)" -ge 10 ]; do
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

pgrep -f "/tmp/.*/tester instance --config .*" | xargs kill
