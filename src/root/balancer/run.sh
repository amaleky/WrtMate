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
}' "$PARSED_CONFIG" >"$OUTPUT_CONFIG" || exit 0

/usr/bin/sing-box run -c "$OUTPUT_CONFIG"
