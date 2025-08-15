#!/bin/sh

CONFIGS="/root/balancer/configs.conf"
PARSED_CONFIG="/tmp/balancer-parsed.json"
OUTPUT_CONFIG="/tmp/balancer-configs.json"
SOCKS_PORT=22335

kill -9 "$(pgrep -f "/usr/bin/sing-box run -c $OUTPUT_CONFIG")"

/usr/bin/hiddify-cli parse "$CONFIGS" -o "$PARSED_CONFIG" > /dev/null 2>&1 && jq --argjson port "$SOCKS_PORT" '{
  "log": {
    "level": "warning"
  },
  "inbounds": [
    {
      "type": "mixed",
      "tag": "mixed-in",
      "listen": "0.0.0.0",
      "listen_port": $port
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
      },
      {
        "tag": "direct",
        "type": "direct"
      }
    ] + .outbounds
  ),
  "route": {
    "auto_detect_interface": true,
    "final": "Select"
  },
  "dns": {
    "servers": [
      {
        "address": "tcp://1.1.1.1",
        "address_resolver": "dns-local",
        "strategy": "prefer_ipv4",
        "tag": "dns-remote",
        "detour": "Select"
      },
      {
        "address": "8.8.8.8",
        "detour": "direct",
        "tag": "dns-local"
      }
    ],
    "rules": [
      {
        "domain": ( [ .outbounds[].server ] | unique ),
        "server": "dns-local"
      },
      {
        "outbound": "direct",
        "server": "dns-local"
      }
    ],
    "final": "dns-local",
    "reverse_mapping": true,
    "strategy": "prefer_ipv4",
    "independent_cache": true
  }
}' "$PARSED_CONFIG" >"$OUTPUT_CONFIG" && /usr/bin/sing-box run -c "$OUTPUT_CONFIG"
