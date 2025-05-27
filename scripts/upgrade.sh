#!/bin/bash
# Upgrade function for WrtMate

upgrade() {
  . /etc/openwrt_release
  LATEST_VERSION=$(curl -s "https://downloads.openwrt.org/.versions.json" | jq -r ".stable_version") || error_exit "Failed to fetch latest OpenWrt version."
  if [[ "$LATEST_VERSION" != "$DISTRIB_RELEASE" ]]; then
    echo "Do You Want To Upgrade Firmware? (yes/no)"
    read -e -i "no" FIRMWARE_UPGRADE
    if [[ "$FIRMWARE_UPGRADE" == "yes" ]]; then
      DEVICE_ID=$(awk '{print tolower($0)}' /tmp/sysinfo/model | tr ' ' '_')
      FILE_NAME=$(curl -s "https://downloads.openwrt.org/releases/${LATEST_VERSION}/targets/${DISTRIB_TARGET}/profiles.json" | jq -r --arg id "$DEVICE_ID" '.profiles[$id].images | map(select(.type == "sysupgrade")) | sort_by((.name | contains("squashfs")) | not) | .[0].name') || error_exit "Failed to fetch device profile."
      DOWNLOAD_URL="https://downloads.openwrt.org/releases/${LATEST_VERSION}/targets/${DISTRIB_TARGET}/${FILE_NAME}"
      curl -L -o /tmp/firmware.bin "${DOWNLOAD_URL}" || error_exit "Failed to download firmware."
      sysupgrade -n -v /tmp/firmware.bin || error_exit "Failed to upgrade firmware."
    fi
  fi

  UPGRADABLE_PACKAGES=$(opkg list-upgradable | cut -f 1 -d ' ')
  if [ -n "$UPGRADABLE_PACKAGES" ]; then
    for PACKAGE in $UPGRADABLE_PACKAGES; do
      opkg upgrade "$PACKAGE" || error_exit "Failed to upgrade package $PACKAGE."
    done
  fi
}

upgrade
