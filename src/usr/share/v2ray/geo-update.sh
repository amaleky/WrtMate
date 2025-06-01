#!/bin/sh

if [ ! -d "/usr/share/v2ray" ]; then mkdir -p "/usr/share/v2ray"; fi

# ip
curl -L -o /tmp/geoip-lite.dat https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/geoip-lite.dat && mv /tmp/geoip-lite.dat /usr/share/v2ray/geoip.dat

# domain
curl -L -o /tmp/geosite-lite.dat https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/geosite-lite.dat && mv /tmp/geosite-lite.dat /usr/share/v2ray/geosite.dat
