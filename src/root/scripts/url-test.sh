#!/bin/sh

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

if /etc/init.d/ghost enabled; then
  while [ "$(logread | grep "run.sh\[$(pgrep -f '/root/ghost/run.sh')\]" | grep -c "ERROR")" -gt 50 ] || \
    [ "$(curl -s -L -I --max-time 2 --retry 3 --socks5-hostname "127.0.0.1:9802" -o "/dev/null" -w "%{http_code}" "https://telegram.org/")" -ne 200 ] || \
    [ "$(curl -s -L -I --max-time 2 --retry 3 --socks5-hostname "127.0.0.1:9802" -o "/dev/null" -w "%{http_code}" "https://www.youtube.com/")" -ne 200 ] || \
    [ "$(curl -s -L -I --max-time 2 --retry 3 --socks5-hostname "127.0.0.1:9802" -o "/dev/null" -w "%{http_code}" "https://firebase.google.com/")" -ne 200 ] || \
    [ "$(curl -s -L -I --max-time 2 --retry 3 --socks5-hostname "127.0.0.1:9802" -o "/dev/null" -w "%{http_code}" "https://developer.android.com/")" -ne 200 ]; do
    echo "❌ ghost connectivity test failed"
    sed -i '1d' "/root/ghost/configs.conf"
    /etc/init.d/ghost restart
    /etc/init.d/scanner start
    sleep 5
  done
  echo "✅ ghost connectivity test passed"
else
  echo "⚠️ ghost is not running"
fi

if /etc/init.d/warp-plus enabled; then
  if ! curl -s -L -I --max-time 1 --socks5-hostname "127.0.0.1:9803" -o "/dev/null" "https://1.1.1.1/cdn-cgi/trace/"; then
    echo "❌ warp-plus connectivity test failed"
    rm -rfv /.cache/warp-plus/
    /etc/init.d/warp-plus restart
  else
    echo "✅ warp-plus connectivity test passed"
  fi
else
  echo "⚠️ warp-plus is not running"
fi

if /etc/init.d/psiphon enabled; then
  if ! curl -s -L -I --max-time 1 --socks5-hostname "127.0.0.1:9804" -o "/dev/null" "https://1.1.1.1/cdn-cgi/trace/"; then
    echo "❌ psiphon connectivity test failed"
    /etc/init.d/psiphon restart
  else
    echo "✅ psiphon connectivity test passed"
  fi
else
  echo "⚠️ psiphon is not running"
fi

if /etc/init.d/tor enabled; then
  if ! curl -s -L -I --max-time 1 --socks5-hostname "127.0.0.1:9805" -o "/dev/null" "https://1.1.1.1/cdn-cgi/trace/"; then
    echo "❌ tor connectivity test failed"
    /etc/init.d/tor restart
  else
    echo "✅ tor connectivity test passed"
  fi
else
  echo "⚠️ tor is not running"
fi

if /etc/init.d/ssh-proxy enabled; then
  if ! curl -s -L -I --max-time 1 --socks5-hostname "127.0.0.1:9806" -o "/dev/null" "https://1.1.1.1/cdn-cgi/trace/"; then
    echo "❌ ssh-proxy connectivity test failed"
    rm -fv /root/.ssh/known_hosts
    /etc/init.d/ssh-proxy restart
  else
    echo "✅ ssh-proxy connectivity test passed"
  fi
else
  echo "⚠️ ssh-proxy is not running"
fi

if /etc/init.d/serverless enabled; then
  if ! curl -s -L -I --max-time 1 --socks5-hostname "127.0.0.1:9807" -o "/dev/null" "https://1.1.1.1/cdn-cgi/trace/"; then
    echo "❌ serverless connectivity test failed"
    /etc/init.d/serverless restart
  else
    echo "✅ serverless connectivity test passed"
  fi
else
  echo "⚠️ serverless is not running"
fi

if /etc/init.d/balancer enabled; then
  if ! curl -s -L -I --max-time 1 --socks5-hostname "127.0.0.1:9801" -o "/dev/null" "https://1.1.1.1/cdn-cgi/trace/"; then
    echo "❌ balancer connectivity test failed"
    /etc/init.d/balancer restart
  else
    echo "✅ balancer connectivity test passed"
  fi
else
  echo "⚠️ balancer is not running"
fi
