#!/bin/bash
# IRQ Balance configuration for WrtMate

irq() {
  opkg install luci-app-irqbalance || error_exit "Failed to install IRQ balance."
  uci set irqbalance.irqbalance.enabled='1'
  uci commit irqbalance
  /etc/init.d/irqbalance enable
  /etc/init.d/irqbalance restart
}

irq