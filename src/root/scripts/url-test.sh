#!/bin/sh

get_retry_count() {
  FILE="/tmp/$1.count"
  COUNT=$(cat "$FILE" 2>/dev/null || echo 0)
  echo "$COUNT"
}

set_retry_count() {
  FILE="/tmp/$1.count"
  COUNT=$(cat "$FILE" 2>/dev/null || echo 0)
  COUNT=$((COUNT + 1))
  echo "$COUNT" > "$FILE"
}

if ! ping -c 1 -W 2 "217.218.155.155" >/dev/null 2>&1; then
  echo "❌ Connectivity test failed."
  exit 0
fi

if [ "$(uci get passwall2.@global[0].enabled 2>/dev/null)" = "1" ]; then
  if ! top -bn1 | grep -v 'grep' | grep '/tmp/etc/passwall2/bin/' | grep 'default' | grep 'global' >/dev/null; then
    echo "❌ passwall2 is not running."
    /etc/init.d/passwall2 restart
  fi
fi

if [ "$(get_retry_count "balancer")" -le 5 ]; then
  if ! curl -s -L -I --max-time 2 --retry 2 --socks5-hostname "127.0.0.1:9801" -o "/dev/null" "http://www.gstatic.com/generate_204"; then
    echo "❌ balancer connectivity test failed"
    set_retry_count "balancer"
    /etc/init.d/balancer restart
  else
    echo "✅ balancer connectivity test passed"
  fi
else
  /etc/init.d/balancer stop
fi

if [ "$(get_retry_count "ghost")" -le 5 ]; then
  while [ "$(logread | grep "run.sh\[$(pgrep -f '/root/ghost/run.sh')\]" | grep -c "ERROR")" -gt 50 ] || \
    [ "$(curl -s -L -I --max-time 2 --retry 2 --socks5-hostname "127.0.0.1:9802" -o "/dev/null" -w "%{http_code}" "https://telegram.org/")" -ne 200 ] || \
    [ "$(curl -s -L -I --max-time 2 --retry 2 --socks5-hostname "127.0.0.1:9802" -o "/dev/null" -w "%{http_code}" "https://www.youtube.com/")" -ne 200 ] || \
    [ "$(curl -s -L -I --max-time 2 --retry 2 --socks5-hostname "127.0.0.1:9802" -o "/dev/null" -w "%{http_code}" "https://firebase.google.com/")" -ne 200 ] || \
    [ "$(curl -s -L -I --max-time 2 --retry 2 --socks5-hostname "127.0.0.1:9802" -o "/dev/null" -w "%{http_code}" "https://developer.android.com/")" -ne 200 ]; do
    echo "❌ ghost connectivity test failed"
    sed -i '1d' "/root/ghost/configs.conf"
    set_retry_count "ghost"
    /etc/init.d/ghost restart
    /etc/init.d/scanner start
    sleep 5
  done
  echo "✅ ghost connectivity test passed"
else
  /etc/init.d/ghost stop
fi

if [ "$(get_retry_count "warp-plus")" -le 5 ]; then
  if ! curl -s -L -I --max-time 2 --retry 2 --socks5-hostname "127.0.0.1:9803" -o "/dev/null" "http://www.gstatic.com/generate_204"; then
    echo "❌ warp-plus connectivity test failed"
    rm -rfv /.cache/warp-plus/
    set_retry_count "warp-plus"
    /etc/init.d/warp-plus restart
  else
    echo "✅ warp-plus connectivity test passed"
  fi
else
  /etc/init.d/warp-plus stop
fi

if [ "$(get_retry_count "psiphon")" -le 5 ]; then
  if ! curl -s -L -I --max-time 2 --retry 2 --socks5-hostname "127.0.0.1:9804" -o "/dev/null" "http://www.gstatic.com/generate_204"; then
    echo "❌ psiphon connectivity test failed"
    set_retry_count "psiphon"
    /etc/init.d/psiphon restart
  else
    echo "✅ psiphon connectivity test passed"
  fi
else
  /etc/init.d/psiphon stop
fi

if [ "$(get_retry_count "tor")" -le 5 ]; then
  if ! curl -s -L -I --max-time 2 --retry 2 --socks5-hostname "127.0.0.1:9805" -o "/dev/null" "http://www.gstatic.com/generate_204"; then
    echo "❌ tor connectivity test failed"
    set_retry_count "tor"
    /etc/init.d/tor restart
  else
    echo "✅ tor connectivity test passed"
  fi
else
  /etc/init.d/tor stop
fi

if [ "$(get_retry_count "ssh-proxy")" -le 5 ]; then
  if ! curl -s -L -I --max-time 2 --retry 2 --socks5-hostname "127.0.0.1:9806" -o "/dev/null" "http://www.gstatic.com/generate_204"; then
    echo "❌ ssh-proxy connectivity test failed"
    rm -fv /root/.ssh/known_hosts
    set_retry_count "ssh-proxy"
    /etc/init.d/ssh-proxy restart
  else
    echo "✅ ssh-proxy connectivity test passed"
  fi
else
  /etc/init.d/ssh-proxy stop
fi

if [ "$(get_retry_count "serverless")" -le 5 ]; then
  if ! curl -s -L -I --max-time 2 --retry 2 --socks5-hostname "127.0.0.1:9807" -o "/dev/null" "http://www.gstatic.com/generate_204"; then
    echo "❌ serverless connectivity test failed"
    set_retry_count "serverless"
    /etc/init.d/serverless restart
  else
    echo "✅ serverless connectivity test passed"
  fi
else
  /etc/init.d/serverless stop
fi
