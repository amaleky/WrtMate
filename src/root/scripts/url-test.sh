#!/bin/sh

TEST_URL="http://www.gstatic.com/generate_204"

if ! curl --socks5 127.0.0.1:8086 --silent --max-time 5 --output "/dev/null" "$TEST_URL"; then
  if /etc/init.d/warp-plus status | grep -q "running"; then
    /etc/init.d/warp-plus restart
  fi
fi

if ! curl --socks5 127.0.0.1:12334 --silent --max-time 5 --output "/dev/null" "$TEST_URL"; then
  if /etc/init.d/hiddify-cli status | grep -q "running"; then
    /etc/init.d/hiddify-cli restart
  fi
fi
