#!/bin/sh

if ! ping -c 1 -W 2 "217.218.155.155" > /dev/null 2>&1; then
  echo "❌ Connectivity test failed."
  exit 0
fi

if ! top -bn1 | grep -v 'grep' | grep '/tmp/etc/passwall2/bin/' | grep 'default' | grep 'global' > /dev/null; then
  echo "❌ passwall2 is not running."
  /etc/init.d/passwall2 restart
fi

if /etc/init.d/warp-plus enabled; then
  if ! curl -s -L -I --max-time 1 --retry 3 --socks5-hostname "127.0.0.1:8086" -o "/dev/null" "https://1.1.1.1/cdn-cgi/trace/"; then
    echo "❌ warp-plus connectivity test failed"
    rm -rfv /.cache/warp-plus/
    /etc/init.d/warp-plus restart
  else
    echo "✅ warp-plus connectivity test passed"
    if /etc/init.d/psiphon enabled; then
      if ! curl -s -L -I --max-time 1 --retry 3 --socks5-hostname "127.0.0.1:8087" -o "/dev/null" "https://1.1.1.1/cdn-cgi/trace/"; then
        echo "❌ psiphon connectivity test failed"
        rm -rfv /.cache/warp-plus/
        /etc/init.d/psiphon restart
      else
        echo "✅ psiphon connectivity test passed"
      fi
    else
      echo "⚠️ psiphon is not running"
    fi
  fi
else
  echo "⚠️ warp-plus is not running"
fi

if /etc/init.d/ssh-proxy enabled; then
  if ! curl -s -L -I --max-time 1 --retry 3 --socks5-hostname "127.0.0.1:1080" -o "/dev/null" "https://1.1.1.1/cdn-cgi/trace/"; then
    echo "❌ ssh-proxy connectivity test failed"
    rm -fv /root/.ssh/known_hosts
    /etc/init.d/ssh-proxy restart
  else
    echo "✅ ssh-proxy connectivity test passed"
  fi
else
  echo "⚠️ ssh-proxy is not running"
fi
