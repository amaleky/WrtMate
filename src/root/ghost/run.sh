#!/bin/sh

CONFIGS="/root/ghost/configs.conf"
OUTPUT_CONFIG="/tmp/ghost-configs.json"
PARSED_CONFIG="/tmp/ghost-parsed.json"
SOCKS_PORT=22334

kill -9 "$(pgrep -f "/usr/bin/sing-box run -c $OUTPUT_CONFIG")"

/usr/bin/hiddify-cli parse "$CONFIGS" -o "$PARSED_CONFIG" > /dev/null 2>&1 && jq --argjson port "$SOCKS_PORT" '. + {
  "log": {
    "level": "warning"
  },
  "inbounds": [
    {
      "type": "socks",
      "tag": "socks-inbound",
      "listen": "127.0.0.1",
      "listen_port": $port
    }
  ]
}' "$PARSED_CONFIG" >"$OUTPUT_CONFIG" && /usr/bin/sing-box run -c "$OUTPUT_CONFIG"
