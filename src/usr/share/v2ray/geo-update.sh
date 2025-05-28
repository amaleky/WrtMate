#!/bin/sh

curl -L -o /tmp/geoip.dat https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/geoip.dat && mv /tmp/geoip.dat /usr/share/v2ray/geoip.dat
curl -L -o /tmp/geosite.dat https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/geosite.dat && mv /tmp/geosite.dat /usr/share/v2ray/geosite.dat
curl -L -o /tmp/security-ip.dat https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/security-ip.dat && mv /tmp/security-ip.dat /usr/share/v2ray/security-ip.dat
curl -L -o /tmp/geoip-services.dat https://cdn.jsdelivr.net/gh/chocolate4u/Iran-v2ray-rules@release/geoip-services.dat && mv /tmp/geoip-services.dat /usr/share/v2ray/geoip-services.dat
