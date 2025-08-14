#!/bin/bash

WARP_XRAY_CONF="/root/xray/warp.json"
WARP_RESULT="/tmp/result.csv"

rm -f "$WARP_RESULT" "/.cache/warp-plus/"

if grep -q "PUBLIC_KEY_HERE" "$WARP_XRAY_CONF" || grep -q "PRIVATE_KEY_HERE" "$WARP_XRAY_CONF"; then
  KEYPAIR=$(/usr/bin/sing-box generate wg-keypair)
  PRIVATE_KEY=$(echo "$KEYPAIR" | grep 'PrivateKey:' | awk '{print $2}')
  PUBLIC_KEY=$(echo "$KEYPAIR" | grep 'PublicKey:' | awk '{print $2}')
  if grep -q "PUBLIC_KEY_HERE" "$WARP_XRAY_CONF"; then
    sed -i "s/PUBLIC_KEY_HERE/$PUBLIC_KEY/g" "$WARP_XRAY_CONF"
  fi
  if grep -q "PRIVATE_KEY_HERE" "$WARP_XRAY_CONF"; then
    sed -i "s/PRIVATE_KEY_HERE/$PRIVATE_KEY/g" "$WARP_XRAY_CONF"
  fi
fi

while true; do
  if [ -f "$WARP_RESULT" ] && [ "$(sed -n '2p' "$WARP_RESULT")" != "" ]; then
    ENDPOINT=$(sed -n '2p' "$WARP_RESULT" | cut -d',' -f1)
    sed -i "s|^ENDPOINT_PARAMS=.*|ENDPOINT_PARAMS=\"-e ${ENDPOINT}\"|" "/etc/init.d/warp-plus"
    sed -i "s|^ENDPOINT_PARAMS=.*|ENDPOINT_PARAMS=\"-e ${ENDPOINT}\"|" "/etc/init.d/psiphon"
    sed -i -E "s/(\"endpoint\"\s*:\s*\")[^\"]*(\")/\1$ENDPOINT\2/" "$WARP_XRAY_CONF"
    jq --arg ep "$ENDPOINT" '(.outbounds[] | select(.protocol=="wireguard") | .settings.peers[] | .endpoint) = $ep' "$WARP_XRAY_CONF" > "$WARP_XRAY_CONF.tmp" && mv "$WARP_XRAY_CONF.tmp" "$WARP_XRAY_CONF"
    break
  else
    cd "/tmp" || exit 1
    yes 1 | bash <(curl -fsSL "https://raw.githubusercontent.com/bia-pain-bache/BPB-Warp-Scanner/main/install.sh")
  fi
done
