#!/bin/bash

GHOST_ERRORS=0
BALANCER_ERRORS=0

logread -f | while IFS= read -r LINE; do
  if echo "$LINE" | grep "run.sh\[$(pgrep -f '/usr/bin/sing-box run -c /root/ghost/configs.json')\]" | grep -q "ERROR"; then
    GHOST_ERRORS=$((GHOST_ERRORS + 1))
    echo "Error detected. Counter: $GHOST_ERRORS"
    if [ "$GHOST_ERRORS" -gt 10 ]; then
      echo "Restarting ghost due to excessive errors..."
      /etc/init.d/ghost restart
      GHOST_ERRORS=0
    fi
  fi
  if echo "$LINE" | grep "run.sh\[$(pgrep -f '/root/balancer/run.sh')\]" | grep -q "ERROR"; then
    BALANCER_ERRORS=$((BALANCER_ERRORS + 1))
    echo "Error detected. Counter: $BALANCER_ERRORS"
    if [ "$BALANCER_ERRORS" -gt 10 ]; then
      echo "Restarting balancer due to excessive errors..."
      /etc/init.d/balancer restart
      BALANCER_ERRORS=0
    fi
  fi
done
