#!/bin/sh

if [ ! -d "/usr/share/v2ray" ]; then mkdir -p "/usr/share/v2ray"; fi
if [ ! -d "/usr/share/singbox" ]; then mkdir -p "/usr/share/singbox"; fi

# ip
curl -L -o /usr/share/v2ray/geoip.dat "https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/geoip.dat"
curl -L -o /usr/share/singbox/geoip.db "https://cdn.jsdelivr.net/gh/chocolate4u/Iran-sing-box-rules@release/geoip.db"

# domain
curl -L -o /usr/share/v2ray/geosite.dat "https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/geosite.dat"
curl -L -o /usr/share/singbox/geosite.db "https://cdn.jsdelivr.net/gh/chocolate4u/Iran-sing-box-rules@release/geosite.db"
