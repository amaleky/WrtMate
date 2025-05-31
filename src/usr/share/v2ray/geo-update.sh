#!/bin/sh

# ip
curl -L -o /tmp/geoip.dat https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/geoip-lite.dat && mv /tmp/geoip-lite.dat /usr/share/v2ray/geoip.dat
curl -L -o /tmp/security-ip.dat https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/security-ip.dat && mv /tmp/security-ip.dat /usr/share/v2ray/security-ip.dat

# domain
curl -L -o /tmp/geosite.dat https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/geosite-lite.dat && mv /tmp/geosite-lite.dat /usr/share/v2ray/geosite.dat
curl -L -o /tmp/security.dat https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/security.dat && mv /tmp/security.dat /usr/share/v2ray/security.dat
