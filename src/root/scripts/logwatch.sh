#!/bin/bash

GHOST_ERRORS=0

logread -f | while IFS= read -r LINE; do
  if echo "$LINE" | grep "sing-box\[$(pgrep -f '/usr/bin/sing-box run -c /root/ghost/configs.json')\]" | grep -q "ERROR"; then
    GHOST_ERRORS=$((GHOST_ERRORS + 1))
    echo "Error detected (ghost). Counter: $GHOST_ERRORS"
    if [ "$GHOST_ERRORS" -gt 10 ]; then
      echo "Restarting ghost due to excessive errors..."
      /etc/init.d/ghost restart
      GHOST_ERRORS=0
    fi
  fi
done
