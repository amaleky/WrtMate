#!/bin/bash
# Smart Queue Management (SQM) configuration for WrtMate

sqm() {
  opkg install luci-app-sqm || error_exit "Failed to install SQM."
}

sqm