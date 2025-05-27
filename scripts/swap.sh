#!/bin/bash
# ZRAM Swap configuration for WrtMate

swap() {
  opkg install zram-swap || error_exit "Failed to install zram-swap."
}

swap