#!/bin/sh

SUBSCRIPTION_URL=""
CONFIGS="/root/balancer/subscription.json"
TEMP_FILE="/tmp/balancer-tmp.json"
SUBSCRIPTION="/tmp/balancer-subscription.json"

kill -9 "$(pgrep -f "/usr/bin/sing-box run -c $SUBSCRIPTION")"

if curl -L -o "$TEMP_FILE" "$SUBSCRIPTION_URL"; then
  mv "$TEMP_FILE" "$CONFIGS"
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
}' "$CONFIGS" >"$SUBSCRIPTION" || exit 0

/usr/bin/sing-box run -c "$SUBSCRIPTION"
