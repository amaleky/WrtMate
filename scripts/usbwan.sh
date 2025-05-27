#!/bin/bash
# USB WAN configuration for WrtMate

usbwan() {
  # Install required packages for USB WAN support
  opkg install comgt-ncm kmod-usb-net-huawei-cdc-ncm usb-modeswitch kmod-usb-serial kmod-usb-serial-option kmod-usb-serial-wwan comgt-ncm luci-proto-3g luci-proto-ncm luci-proto-qmi kmod-usb-net-huawei-cdc-ncm usb-modeswitch || error_exit "Failed to install USB-WAN packages."
}

usbwan