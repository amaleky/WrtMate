#!/bin/bash
# USB configuration for OpenWRT

usb_wan_support() {
  ensure_packages "comgt-ncm kmod-usb-net-huawei-cdc-ncm usb-modeswitch kmod-usb-serial kmod-usb-serial-option kmod-usb-serial-wwan luci-proto-3g luci-proto-ncm luci-proto-qmi"
}

usb_storage_support() {
  ensure_packages "kmod-usb-storage kmod-usb-storage-uas usbutils block-mount e2fsprogs kmod-fs-ext4 libblkid kmod-fs-exfat exfat-fsck parted block-mount kmod-fs-ext4 e2fsprogs"
}

configure_samba() {
  ensure_packages "luci-app-samba4"
  uci add samba4 sambashare
  uci set samba4.@sambashare[-1].name='Share'
  uci set samba4.@sambashare[-1].path='/mnt/sda1'
  uci set samba4.@sambashare[-1].read_only='no'
  uci set samba4.@sambashare[-1].guest_ok='yes'
  uci set samba4.@sambashare[-1].create_mask='0666'
  uci set samba4.@sambashare[-1].dir_mask='0777'
  uci commit samba4
  /etc/init.d/samba4 restart
  chmod -R 777 /mnt/sda1
}

extend_storage() {
  # Create partition table and partition
  info "Creating partition table..."

  DISK="/dev/sda"
  parted -s ${DISK} -- mklabel gpt mkpart extroot 2048s -2048s || error "Failed to partition USB storage."
  DEVICE="${DISK}1"
  mkfs.ext4 -L extroot ${DEVICE} || error "Failed to format extroot."
  eval "$(block info ${DEVICE} | grep -o -e 'UUID="\S*"')"
  eval "$(block info | grep -o -e 'MOUNT="\S*/overlay"')"
  uci -q delete fstab.extroot
  uci set fstab.extroot="mount"
  uci set fstab.extroot.uuid="${UUID}"
  uci set fstab.extroot.target="${MOUNT}"
  uci commit fstab
  ORIG="$(block info | sed -n -e '/MOUNT="\S*\/overlay"/s/:\s.*$//p')"
  uci -q delete fstab.rwm
  uci set fstab.rwm="mount"
  uci set fstab.rwm.device="${ORIG}"
  uci set fstab.rwm.target="/rwm"
  uci commit fstab
  mount "${DEVICE}" /mnt || error "Failed to mount extroot."
  tar -C "${MOUNT}" -cvf - . | tar -C /mnt -xf - || error "Failed to copy overlay data."
}

main() {
  if confirm "Do you need USB-WAN support?"; then
    usb_wan_support
  else
    if confirm "Do you want to use USB as router storage?"; then
      usb_storage_support
      extend_storage
      reboot
    fi

    if confirm "Do you want to access USB data using SMB?"; then
      usb_storage_support
      configure_samba
      reboot
    fi
  fi
}

main "$@"
