#!/bin/sh

SUBSCRIPTION_URL=""
CONFIGS="/root/balancer/subscription.json"
TEMP_FILE="/tmp/balancer-tmp.json"
SUBSCRIPTION="/tmp/balancer-subscription.json"

kill -9 $(pgrep -f "/usr/bin/sing-box run -c $SUBSCRIPTION")

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
        "outbounds": (["Auto"] + [.outbounds[] | select(.type | IN("selector","urltest","direct") | not) | .tag]),
        "default": "Auto"
      },
      {
        "type": "urltest",
        "tag": "Auto",
        "outbounds": [.outbounds[] | select(.type | IN("selector","urltest","direct") | not) | .tag],
        "url": "https://1.1.1.1/cdn-cgi/trace/",
        "interval": "1m",
        "tolerance": 50,
        "interrupt_exist_connections": false
      }
    ] + [.outbounds[] | select(.tag | IN("Select","Auto") | not) | select(.type | IN("selector","urltest","direct") | not)]
  ),
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
    "default_domain_resolver": "remote",
    "final": "Select"
  }
}' "$CONFIGS" >"$SUBSCRIPTION" || exit 0

/usr/bin/sing-box run -c "$SUBSCRIPTION"
