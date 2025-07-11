#!/bin/sh

NEEDS_UPDATE="false"
OUTPUT_DIR="/tmp/lib/adguardhome/data/filters"
TEMP_FILE=$(mktemp)

if [ ! -d "$OUTPUT_DIR" ]; then
  mkdir -p "$OUTPUT_DIR"
fi

yq eval '.filters[] | select(.enabled == true) | [.id, .url] | @tsv' /etc/adguardhome.yaml > "$TEMP_FILE"

while IFS='	' read -r ID URL; do
  OUTPUT_FILE="${OUTPUT_DIR}/${ID}.txt"

  if [ ! -f "$OUTPUT_FILE" ]; then
    if curl -L --max-time 600 --retry 2 --socks5 127.0.0.1:1070 --output "$OUTPUT_FILE" "$URL"; then
      NEEDS_UPDATE="true"
      echo "Downloaded filter $ID to $OUTPUT_FILE"
    else
      echo "Failed to download $ID: $URL"
    fi
  fi
done < "$TEMP_FILE"

rm -f "$TEMP_FILE"

if [ "$NEEDS_UPDATE" = "true" ]; then
  echo "Restart AdGuard service to apply changes"
  uci commit adguardhome
  /etc/init.d/adguardhome restart
fi
