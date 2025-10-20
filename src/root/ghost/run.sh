#!/bin/sh

RAW_CONFIG="/root/ghost/configs.conf"
PARSED_CONFIG="/tmp/ghost.parsed"
FINAL_CONFIG="/tmp/ghost.final"

kill -9 $(pgrep -f "/usr/bin/sing-box run -c $FINAL_CONFIG")

/usr/bin/hiddify-cli parse "$RAW_CONFIG" -o "$PARSED_CONFIG" || exit 1

jq '{
  "log": {
    "level": "warning"
  },
  "inbounds": [
    { "type": "mixed", "tag": "mixed-in", "listen": "0.0.0.0", "listen_port": 9802 }
  ],
  "outbounds": (
    [
      {
        "type": "urltest",
        "tag": "Auto",
        "outbounds": [.outbounds[] | select(.type | IN("selector","urltest","direct") | not) | .tag],
        "url": "https://developer.android.com/favicon.ico",
        "interval": "10m",
        "tolerance": 50,
        "interrupt_exist_connections": false
      }
    ] + [.outbounds[] | select(.type | IN("selector","urltest","direct") | not)]
  ),
  "route": {
    "final": "Auto"
  }
}' "$PARSED_CONFIG" >"$FINAL_CONFIG" || exit 0

/usr/bin/sing-box run -c "$FINAL_CONFIG"
