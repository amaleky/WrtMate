#!/bin/sh

SUBSCRIPTION_URL=""
RAW_CONFIG="/root/balancer/subscription.json"
TEMP_CONFIG="/tmp/balancer.tmp"
FINAL_CONFIG="/tmp/balancer.final"

kill -9 $(pgrep -f "/usr/bin/sing-box run -c $FINAL_CONFIG")

if curl -L -o "$TEMP_CONFIG" "$SUBSCRIPTION_URL"; then
  mv "$TEMP_CONFIG" "$RAW_CONFIG"
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
        "type": "urltest",
        "tag": "Auto",
        "outbounds": [.outbounds[] | select(.type | IN("selector","urltest","direct") | not) | .tag],
        "url": "https://1.1.1.1/cdn-cgi/trace/",
        "interval": "10m",
        "tolerance": 50,
        "interrupt_exist_connections": false
      }
    ] + [.outbounds[] | select(.type | IN("selector","urltest","direct") | not)]
  ),
  "dns": {
    "servers": [
      { "tag": "remote", "type": "tls", "server": "1.1.1.1" }
    ],
    "strategy": "ipv4_only"
  },
  "route": {
    "rules": [
      { "action": "sniff" },
      { "protocol": "dns", "action": "hijack-dns" }
    ],
    "default_domain_resolver": "remote",
    "final": "Auto"
  }
}' "$RAW_CONFIG" >"$FINAL_CONFIG" || exit 0

/usr/bin/sing-box run -c "$FINAL_CONFIG"
