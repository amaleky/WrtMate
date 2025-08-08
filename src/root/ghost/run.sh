#!/bin/sh

SOURCE_CONFIGS="/root/ghost/configs.conf"
INPUT_CONFIGS="/tmp/ghost-input.conf"
OUTPUT_CONFIG="/tmp/ghost-configs.json"
PARSED_CONFIG="/tmp/ghost-parsed.json"
SOCKS_PORT=22334

kill -9 "$(pgrep -f "/usr/bin/sing-box run -c $OUTPUT_CONFIG")"

sed -n '1p' "$SOURCE_CONFIGS" > "$INPUT_CONFIGS"

/usr/bin/hiddify-cli parse "$INPUT_CONFIGS" -o "$PARSED_CONFIG" > /dev/null 2>&1 && jq --argjson port "$SOCKS_PORT" '. + {
  "log": {
    "level": "warning"
  },
  "dns": {
    "servers": [
      {
        "address": "tcp://1.1.1.1",
        "address_resolver": "dns-local",
        "strategy": "prefer_ipv4",
        "tag": "dns-remote",
        "detour": (.outbounds[0].tag)
      },
      {
        "address": "local",
        "detour": "direct",
        "tag": "dns-local"
      }
    ],
    "rules": [
      {
        "domain": ( [ .outbounds[].server ] | unique ),
        "server": "dns-local"
      }
    ],
    "final": "dns-remote",
    "strategy": "prefer_ipv4",
    "disable_cache": false,
    "disable_expire": false
  },
  "inbounds": [
    {
      "type": "socks",
      "tag": "socks-inbound",
      "listen": "127.0.0.1",
      "listen_port": $port
    }
  ],
  "outbounds": (
    .outbounds + [
      {
        "tag": "direct",
        "type": "direct"
      }
    ]
  )
}' "$PARSED_CONFIG" >"$OUTPUT_CONFIG" && /usr/bin/sing-box run -c "$OUTPUT_CONFIG"
