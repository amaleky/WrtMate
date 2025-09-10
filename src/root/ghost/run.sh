#!/bin/sh

INPUT_CONFIGS="/root/ghost/configs.conf"
PARSED_CONFIG="/tmp/ghost-parsed.json"
OUTPUT_CONFIG="/tmp/ghost-final.json"

kill -9 "$(pgrep -f "/usr/bin/sing-box run -c $OUTPUT_CONFIG")"

/usr/bin/hiddify-cli parse "$INPUT_CONFIGS" -o "$PARSED_CONFIG" > /dev/null 2>&1 || exit 1

jq '{
  "log": {
    "level": "warning"
  },
  "inbounds": [
    {
      "type": "mixed",
      "tag": "mixed-in",
      "listen": "0.0.0.0",
      "listen_port": 9802
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
