#!/bin/sh

SUBSCRIPTION_PATH="/root/ghost/configs.conf"
FIRST_CONFIG="/tmp/ghost-first.conf"
CONFIGS="/tmp/ghost-parsed.json"
SUBSCRIPTION="/tmp/ghost-subscription.json"

kill -9 $(pgrep -f "/usr/bin/sing-box run -c $SUBSCRIPTION")

sed -n '1p' "$SUBSCRIPTION_PATH" > "$FIRST_CONFIG"

/usr/bin/hiddify-cli parse "$FIRST_CONFIG" -o "$CONFIGS" || exit 1

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
  "outbounds": .outbounds,
  "dns": {
    "servers": [
      {
        "tag": "remote",
        "type": "tls",
        "server": "208.67.222.2"
      }
    ],
    "strategy": "ipv4_only"
  },
  "route": {
    "rules": [
      {
        "action": "sniff"
      },
      {
        "protocol": "dns",
        "action": "hijack-dns"
      }
    ],
    "default_domain_resolver": "remote"
  }
}' "$CONFIGS" >"$SUBSCRIPTION" || exit 0

/usr/bin/sing-box run -c "$SUBSCRIPTION"
