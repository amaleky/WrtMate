#!/bin/sh

get_retry_count() {
  FILE="/tmp/$1.count"
  cat "$FILE" 2>/dev/null || echo 0
}

set_retry_count() {
  FILE="/tmp/$1.count"
  echo "$(($(get_retry_count "$1") + 1))" >"$FILE"
}

test_connection() {
  if ! ping -c 1 -W 2 "217.218.127.127" >/dev/null 2>&1; then
    echo "❌ Connectivity test failed."
    exit 0
  fi
}

test_passwall() {
  if [ "$(uci get passwall2.@global[0].enabled 2>/dev/null)" = "1" ]; then
    if ! top -bn1 | grep -v 'grep' | grep '/tmp/etc/passwall2/bin/' | grep 'default' | grep 'global' >/dev/null; then
      echo "❌ passwall2 is not running."
      /etc/init.d/passwall2 restart
    fi
  fi
}

test_service() {
  SERVICE="$1"
  PORT="$2"
  AUTO_STOP="$3"
  if [ "$(get_retry_count "$SERVICE")" -le 5 ] || [ "$(uci get passwall2.Splitter.default_node)" = "$SERVICE" ] || [ "$(uci get passwall2.Splitter.Proxy)" = "$SERVICE" ]; then
    if ! curl -s -L -I --max-time 2 --retry 2 --socks5-hostname "127.0.0.1:$PORT" -o "/dev/null" "https://1.1.1.1/cdn-cgi/trace/"; then
      echo "❌ $SERVICE connectivity test failed"
      case "$SERVICE" in
        ghost) /etc/init.d/scanner start ;;
        warp-plus) rm -rfv /.cache/warp-plus/ ;;
        ssh-proxy) rm -fv /root/.ssh/known_hosts ;;
      esac
      if [ "$SERVICE" != "ghost" ]; then
        set_retry_count "$SERVICE"
      fi
      /etc/init.d/"$SERVICE" restart
    else
      echo "✅ $SERVICE connectivity test passed"
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
  test_connection
  test_passwall
  test_service "balancer" 9801 "true"
  test_service "ghost" 9802 "false"
  test_service "warp-plus" 9803 "true"
  test_service "psiphon" 9804 "true"
  test_service "tor" 9805 "true"
  test_service "ssh-proxy" 9806 "true"
  test_service "serverless" 9807 "true"
}

main "$@"
