#!/bin/sh

CONFIGS="/root/balancer/configs.conf"
OUTPUT_CONFIG="/tmp/balancer-configs.json"
PARSED_CONFIG="/tmp/balancer-parsed.json"
SOCKS_PORT=22335

kill -9 "$(pgrep -f "/usr/bin/sing-box run -c $OUTPUT_CONFIG")"

/usr/bin/hiddify-cli parse "$CONFIGS" -o "$PARSED_CONFIG" > /dev/null 2>&1 && jq --argjson port "$SOCKS_PORT" --arg url "https://1.1.1.1/cdn-cgi/trace/" '{
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
        "type": "urltest",
        "tag": "Auto",
        "outbounds": [.outbounds[] | select(.type != "urltest") | .tag],
        "url": $url,
        "interval": "5m",
        "tolerance": 100
      }
    ] + .outbounds
  )
}' "$PARSED_CONFIG" > "$OUTPUT_CONFIG" && /usr/bin/sing-box run -c "$OUTPUT_CONFIG"
