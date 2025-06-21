#!/bin/sh

TEST_URL="http://www.gstatic.com/generate_204"

if ! curl --silent --max-time 10 --output "/dev/null" "$TEST_URL"; then
  echo "ERROR: Connectivity test failed. Skipping all proxy checks."
  exit 0
fi

if echo | nc 127.0.0.1 12334 > /dev/null 2>&1; then
  if ! curl --socks5 127.0.0.1:12334 --silent --max-time 10 --output "/dev/null" "$TEST_URL"; then
    echo "ERROR: Hiddify proxy connectivity test failed. Restarting hiddify-cli service..."
    /etc/init.d/hiddify-cli restart
  else
    echo "Hiddify proxy connectivity test passed"
  fi
else
  echo "INFO: Hiddify proxy is not running on port 12334"
fi

if echo | nc 127.0.0.1 8086 > /dev/null 2>&1; then
  if ! curl --socks5 127.0.0.1:8086 --silent --max-time 10 --output "/dev/null" "$TEST_URL"; then
    echo "ERROR: WARP proxy connectivity test failed. Clearing cache and restarting warp-plus service..."
    rm -rfv /.cache/warp-plus/
    /etc/init.d/warp-plus restart
  else
    echo "WARP proxy connectivity test passed"
  fi
else
  echo "INFO: WARP proxy is not running on port 8086"
fi

if echo | nc 127.0.0.1 1080 > /dev/null 2>&1; then
  if ! curl --socks5 127.0.0.1:1080 --silent --max-time 10 --output "/dev/null" "$TEST_URL"; then
    echo "ERROR: SSH proxy connectivity test failed. Restarting ssh-proxy service..."
    rm -fv /root/.ssh/known_hosts
    /etc/init.d/ssh-proxy restart
  else
    echo "SSH proxy connectivity test passed"
  fi
else
  echo "INFO: SSH proxy is not running on port 1080"
fi
