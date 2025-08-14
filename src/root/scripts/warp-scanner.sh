#!/bin/bash

FILE="/tmp/result.csv"

rm -f "$FILE" "/.cache/warp-plus/"

while true; do
  if [ -f "$FILE" ] && [ "$(sed -n '2p' "$FILE")" != "" ]; then
    ENDPOINT_PARAMS=$(sed -n '2p' "$FILE" | cut -d',' -f1)
    sed -i "s|^ENDPOINT_PARAMS=.*|ENDPOINT_PARAMS=\"-e ${ENDPOINT_PARAMS}\"|" "/etc/init.d/warp-plus"
    sed -i "s|^ENDPOINT_PARAMS=.*|ENDPOINT_PARAMS=\"-e ${ENDPOINT_PARAMS}\"|" "/etc/init.d/psiphon"
    break
  else
    cd "/tmp" || exit 1
    yes 1 | bash <(curl -fsSL "https://raw.githubusercontent.com/bia-pain-bache/BPB-Warp-Scanner/main/install.sh")
  fi
done
