#!/bin/sh

TEST_URL="http://www.gstatic.com/generate_204"

if ! curl --socks5 127.0.0.1:8086 --silent --output "/dev/null" "$TEST_URL"; then
  /etc/init.d/warp-plus restart
fi

if ! curl --socks5 127.0.0.1:8087 --silent --output "/dev/null" "$TEST_URL"; then
  /etc/init.d/warp-psiphon restart
fi

if ! curl --socks5 127.0.0.1:12334 --silent --output "/dev/null" "$TEST_URL"; then
  /etc/init.d/hiddify-cli restart
fi
