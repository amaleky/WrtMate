#!/bin/sh

SOURCE_CONFIGS="/root/ghost/configs.conf"
INPUT_CONFIGS="/tmp/ghost-input.conf"
OUTPUT_CONFIG="/tmp/ghost-configs.json"
PARSED_CONFIG="/tmp/ghost-parsed.json"
SOCKS_PORT=22334

kill -9 "$(pgrep -f "/usr/bin/sing-box run -c $OUTPUT_CONFIG")"

sed -n '1p' "$SOURCE_CONFIGS" > "$INPUT_CONFIGS"

/usr/bin/hiddify-cli parse "$INPUT_CONFIGS" -o "$PARSED_CONFIG" > /dev/null 2>&1 && jq --argjson port "$SOCKS_PORT" '. + {
  "log": {
    "level": "warning"
  },
  "inbounds": [
    {
      "type": "mixed",
      "tag": "mixed-in",
      "listen": "0.0.0.0",
      "listen_port": $port
    }
  ]
}' "$PARSED_CONFIG" >"$OUTPUT_CONFIG" && /usr/bin/sing-box run -c "$OUTPUT_CONFIG"
