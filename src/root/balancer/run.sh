#!/bin/sh

INPUT_CONFIGS=""
PARSED_CONFIG="/root/balancer/subscription.json"
OUTPUT_CONFIG="/tmp/balancer-final.json"

kill -9 "$(pgrep -f "/usr/bin/sing-box run -c $OUTPUT_CONFIG")"

TEMP_FILE="$(mktemp)"
if curl -L -o "$TEMP_FILE" "$INPUT_CONFIGS"; then
  mv "$TEMP_FILE" "$PARSED_CONFIG"
fi

jq '{
  "log": {
    "level": "warning"
  },
  "inbounds": [
    {
      "type": "mixed",
      "tag": "mixed-in",
      "listen": "0.0.0.0",
      "listen_port": 9801
    }
  ],
  "outbounds": (
    [
      {
        "type": "selector",
        "tag": "Select",
        "outbounds": (["Auto"] + [.outbounds[] | select(.type != "selector") | .tag]),
        "default": "Auto"
      },
      {
        "type": "urltest",
        "tag": "Auto",
        "outbounds": [.outbounds[] | select(.type != "urltest") | .tag],
        "url": "https://1.1.1.1/cdn-cgi/trace/",
        "interval": "1m",
        "tolerance": 50,
        "interrupt_exist_connections": false
      }
    ] + .outbounds
  ),
  "route": {
    "auto_detect_interface": true,
    "final": "Select"
  }
}' "$PARSED_CONFIG" >"$OUTPUT_CONFIG" || exit 0

/usr/bin/sing-box run -c "$OUTPUT_CONFIG"
