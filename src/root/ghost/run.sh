#!/bin/sh

SUBSCRIPTION_PATH="/root/ghost/configs.conf"
CONFIGS="/tmp/ghost-parsed.json"
SUBSCRIPTION="/tmp/ghost-subscription.json"

kill -9 "$(pgrep -f "/usr/bin/sing-box run -c $SUBSCRIPTION")"

/usr/bin/hiddify-cli parse "$SUBSCRIPTION_PATH" -o "$CONFIGS" || exit 1

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
    "final": "Select"
  }
}' "$CONFIGS" >"$SUBSCRIPTION" || exit 0

/usr/bin/sing-box run -c "$SUBSCRIPTION"
