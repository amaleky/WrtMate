#!/bin/sh

if ! ping -c 1 -W 2 "217.218.155.155" > /dev/null 2>&1; then
  echo "ERROR: Connectivity test failed."
  exit 0
fi

if ! top -bn1 | grep -v 'grep' | grep '/tmp/etc/passwall2/bin/' | grep 'default' | grep 'global' > /dev/null; then
  echo "ERROR: Passwall is not running."
  /etc/init.d/passwall2 restart
fi

if /etc/init.d/ghost enabled; then
  if [ "$(logread | grep "run.sh\[$(pgrep -f '/root/ghost/run.sh')\]" | grep -c "ERROR")" -gt 50 ] || \
      [ "$(curl -s -L -I --max-time 1 --retry 1 --socks5-hostname "127.0.0.1:22334" -o "/dev/null" -w "%{http_code}" "https://1.1.1.1/cdn-cgi/trace/")" -ne 200 ]; then
    echo "ERROR: Ghost proxy connectivity test failed. Restarting ghost service..."
    sed -i '1d' "/root/ghost/configs.conf"
    /etc/init.d/ghost restart
    /etc/init.d/scanner start
  else
    echo "Ghost proxy connectivity test passed"
  fi
else
  echo "INFO: Ghost proxy is not running"
fi

if /etc/init.d/warp-plus enabled; then
  if ! curl -s -L -I --max-time 1 --retry 1 --socks5-hostname "127.0.0.1:8086" -o "/dev/null" "https://1.1.1.1/cdn-cgi/trace/"; then
    echo "ERROR: WARP proxy connectivity test failed. Clearing cache and restarting warp-plus service..."
    rm -rfv /.cache/warp-plus/
    /etc/init.d/warp-plus restart
  else
    echo "WARP Plus proxy connectivity test passed"
  fi
else
  echo "INFO: WARP Plus proxy is not running"
fi

if /etc/init.d/psiphon enabled; then
  if [ "$(curl -s -L -I --max-time 1 --retry 1 --socks5-hostname "127.0.0.1:8087" -o "/dev/null" -w "%{http_code}" "https://1.1.1.1/cdn-cgi/trace/")" -ne 200 ]; then
    echo "ERROR: WARP proxy connectivity test failed. Clearing cache and restarting psiphon service..."
    /etc/init.d/psiphon restart
  else
    echo "Psiphon proxy connectivity test passed"
  fi
else
  echo "INFO: Psiphon proxy is not running"
fi

if /etc/init.d/ssh-proxy enabled; then
  if ! curl -s -L -I --max-time 1 --retry 1 --socks5-hostname "127.0.0.1:1080" -o "/dev/null" "https://1.1.1.1/cdn-cgi/trace/"; then
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
  if ! curl -s -L -I --max-time 1 --retry 1 --socks5-hostname "127.0.0.1:10808" -o "/dev/null" "https://1.1.1.1/cdn-cgi/trace/"; then
    echo "ERROR: ServerLess connectivity test failed. Restarting serverless service..."
    /etc/init.d/serverless restart
  else
    echo "ServerLess connectivity test passed"
  fi
else
  echo "INFO: ServerLess is not running"
fi

if /etc/init.d/balancer enabled; then
  if ! curl -s -L -I --max-time 1 --retry 1 --socks5-hostname "127.0.0.1:22335" -o "/dev/null" "https://1.1.1.1/cdn-cgi/trace/"; then
    echo "ERROR: Balancer connectivity test failed. Restarting balancer service..."
    /etc/init.d/balancer restart
  else
    echo "Balancer connectivity test passed"
  fi
else
  echo "INFO: Balancer is not running"
fi
