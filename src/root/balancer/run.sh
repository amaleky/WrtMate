#!/bin/sh

INPUT_CONFIGS=""
PARSED_CONFIG="/tmp/balancer-parsed.json"
OUTPUT_CONFIG="/tmp/balancer-final.json"

kill -9 "$(pgrep -f "/usr/bin/sing-box run -c $OUTPUT_CONFIG")"

curl -L -o "$PARSED_CONFIG" "$INPUT_CONFIGS"

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
