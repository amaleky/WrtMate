#!/bin/sh

CONFIGS="/root/hiddify/configs.conf"
OUTPUT_CONFIG="/tmp/hiddify-configs.json"
PARSED_CONFIG="/tmp/hiddify-parsed.json"
TEST_URL="http://gstatic.com/generate_204"
SOCKS_PORT=12334

/usr/bin/hiddify-cli parse "$CONFIGS" -o "$PARSED_CONFIG" > /dev/null 2>&1

jq --argjson port "$SOCKS_PORT" --arg url "$TEST_URL" '{
  log: {
    level: "error"
  },
  inbounds: [
    {
      type: "socks",
      tag: "socks-inbound",
      listen: "127.0.0.1",
      listen_port: $port
    }
  ],
  outbounds: (
    [
      {
        type: "urltest",
        tag: "Auto",
        outbounds: [.outbounds[] | select(.type != "urltest") | .tag],
        url: $url,
        interval: "5m"
      }
    ] + (.outbounds | map(select(.type != "urltest")))
  )
}' "$PARSED_CONFIG" > "$OUTPUT_CONFIG"

kill -9 "$(pgrep -f "/usr/bin/sing-box run -c $OUTPUT_CONFIG")"

/usr/bin/sing-box run -c "$OUTPUT_CONFIG"
