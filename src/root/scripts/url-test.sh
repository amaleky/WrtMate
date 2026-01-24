#!/bin/sh

get_retry_count() {
  FILE="/tmp/$1.count"
  cat "$FILE" 2>/dev/null || echo 0
}

set_retry_count() {
  FILE="/tmp/$1.count"
  echo "$(($(get_retry_count "$1") + 1))" >"$FILE"
}

test_socks_port() {
  SOCKS_PORT=$1
  URL=$2
  if curl -s -L -I --max-time 2 --retry 2 --socks5-hostname "127.0.0.1:$SOCKS_PORT" -o "/dev/null" "$URL"; then
    return 0
  else
    return 1
  fi
}

test_serverless() {
  if test_socks_port "10808" "https://www.google.com"; then
    echo "✅ serverless connectivity test passed"
  else
    SERVERLESS_CONFIG="/root/xray/serverless.json"
    SERVERLESS_SUBSCRIPTION="/root/xray/subscription.json"
    FOUND_WORKING=0
    i=$(($(jq '. | length' "$SERVERLESS_SUBSCRIPTION") - 1))
    while [ "$i" -ge 0 ]; do
      jq ".[$i]" "$SERVERLESS_SUBSCRIPTION" > "$SERVERLESS_CONFIG"
      echo "Testing serverless [$(jq -r '.remarks' "$SERVERLESS_CONFIG")]"
      /etc/init.d/serverless restart
      sleep 5
      if test_socks_port "10808" "https://www.google.com"; then
        echo "✅ serverless connectivity test passed"
        FOUND_WORKING=1
        break
      fi
      i=$((i - 1))
    done
    if [ "$FOUND_WORKING" -eq 0 ]; then
      echo "❌ serverless connectivity test failed"
      /etc/init.d/serverless stop
    fi
  fi
}

test_service() {
  SERVICE="$1"
  NODE="$2"
  PORT="$3"
  AUTO_STOP="$4"
  if [ "$(get_retry_count "$SERVICE")" -le 5 ] || [ "$(uci get passwall2.Splitter.default_node)" = "$NODE" ] || [ "$(uci get passwall2.Auto.node)" = "$NODE" ]; then
    if ! test_socks_port "$PORT" "https://1.1.1.1/cdn-cgi/trace/"; then
      echo "❌ $NODE connectivity test failed"
      case "$SERVICE" in
        warp-plus) rm -rfv /.cache/vwarp/ ;;
        ssh-proxy) rm -fv /root/.ssh/known_hosts ;;
      esac
      if [ "$SERVICE" != "scanner" ]; then
        set_retry_count "$SERVICE"
      fi
      /etc/init.d/"$SERVICE" restart
    else
      echo "✅ $NODE connectivity test passed"
    fi
  else
    if [ "$AUTO_STOP" != "false" ]; then
      if /etc/init.d/"$SERVICE" running; then
        /etc/init.d/"$SERVICE" stop
      fi
    fi
  fi
}

main() {
  test_service "scanner" "Scanner" 9802 "false"
  test_service "warp-plus" "WarpPlus" 9803 "true"
  test_service "psiphon" "Psiphon" 9804 "true"
  test_service "tor" "Tor" 9805 "true"
  test_service "ssh-proxy" "SshProxy" 9806 "true"
  test_service "lantern" "Lantern" 9807 "true"
  test_serverless
}

main "$@"
