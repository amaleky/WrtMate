#!/bin/sh

TEST_URL="http://gstatic.com/generate_204"
TEST_PING="217.218.155.155"

if ! /etc/init.d/hiddify-cli enabled || ! ping -c 1 -W 2 "$TEST_PING" > /dev/null 2>&1 || [ "$(uci get passwall2.@global[0].enabled 2>/dev/null)" != "1" ]; then
  exit 0
fi

if /etc/init.d/hiddify-cli enabled; then
  if ! curl --max-time 10 --retry 2 --socks5 127.0.0.1:12334 --silent --output "/dev/null" "$TEST_URL"; then
    echo "ERROR: Hiddify proxy connectivity test failed. Restarting hiddify-cli service..."
    /etc/init.d/hiddify-cli restart
  else
    echo "Hiddify proxy connectivity test passed"
  fi
else
  echo "INFO: Hiddify proxy is not running"
fi

if /etc/init.d/ghost enabled; then
  if ! curl --max-time 10 --retry 2 --socks5 127.0.0.1:22334 --silent --output "/dev/null" "$TEST_URL"; then
    echo "ERROR: Ghost proxy connectivity test failed. Restarting ghost service..."
    /etc/init.d/scanner start
    /etc/init.d/ghost restart
  else
    echo "Ghost proxy connectivity test passed"
  fi
else
  echo "INFO: Ghost proxy is not running"
fi

if /etc/init.d/warp-plus enabled; then
  if ! curl --max-time 10 --retry 2 --socks5 127.0.0.1:8086 --silent --output "/dev/null" "$TEST_URL"; then
    echo "ERROR: WARP proxy connectivity test failed. Clearing cache and restarting warp-plus service..."
    rm -rfv /.cache/warp-plus/
    /etc/init.d/warp-plus restart
  else
    echo "WARP proxy connectivity test passed"
  fi
else
  echo "INFO: WARP proxy is not running"
fi

if /etc/init.d/ssh-proxy enabled; then
  if ! curl --max-time 10 --retry 2 --socks5 127.0.0.1:1080 --silent --output "/dev/null" "$TEST_URL"; then
    echo "ERROR: SSH proxy connectivity test failed. Restarting ssh-proxy service..."
    rm -fv /root/.ssh/known_hosts
    /etc/init.d/ssh-proxy restart
  else
    echo "SSH proxy connectivity test passed"
  fi
else
  echo "INFO: SSH proxy is not running"
fi

if /etc/init.d/serverless enabled; then
  if ! curl --max-time 10 --retry 2 --socks5 127.0.0.1:10808 --silent --output "/dev/null" "$TEST_URL"; then
    echo "ERROR: ServerLess connectivity test failed. Restarting serverless service..."
    /etc/init.d/serverless restart
  else
    echo "ServerLess connectivity test passed"
  fi
else
  echo "INFO: ServerLess is not running"
fi
