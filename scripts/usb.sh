#!/bin/bash
# USB configuration for OpenWRT

usb_wan_support() {
  opkg install comgt-ncm kmod-usb-net-huawei-cdc-ncm usb-modeswitch kmod-usb-serial kmod-usb-serial-option kmod-usb-serial-wwan comgt-ncm luci-proto-3g luci-proto-ncm luci-proto-qmi kmod-usb-net-huawei-cdc-ncm usb-modeswitch || error "Failed to install USB-WAN packages."
}

usb_storage_support() {
  opkg install kmod-usb-storage kmod-usb-storage-uas usbutils block-mount e2fsprogs kmod-fs-ext4 libblkid kmod-fs-exfat exfat-fsck || error "Failed to install USB-Storage packages."
}

configure_samba() {
  opkg install luci-app-samba4 || error "Failed to install Samba4."
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
  mkfs.ext4 /dev/sda1 || error "Failed to format USB storage."
  block detect | uci import fstab || error "Failed to detect block devices."
  uci set fstab.@mount[-1].enabled='1'
  uci set fstab.@global[0].check_fs='1'
  uci commit fstab
  /etc/init.d/fstab boot || error "Failed to boot fstab."
  opkg install block-mount kmod-fs-ext4 e2fsprogs parted || error "Failed to install storage extension packages."
  parted -s /dev/sda -- mklabel gpt mkpart extroot 2048s -2048s || error "Failed to partition USB storage."
  DEVICE="$(block info | sed -n -e '/MOUNT="\S*\/overlay"/s/:\s.*$//p')"
  uci -q delete fstab.rwm
  uci set fstab.rwm="mount"
  uci set fstab.rwm.device="${DEVICE}"
  uci set fstab.rwm.target="/rwm"
  uci commit fstab
  DEVICE="/dev/sda1"
  mkfs.ext4 -L extroot ${DEVICE} || error "Failed to format extroot."
  eval $(block info ${DEVICE} | grep -o -e 'UUID="\S*"')
  eval $(block info | grep -o -e 'MOUNT="\S*/overlay"')
  uci -q delete fstab.extroot
  uci set fstab.extroot="mount"
  uci set fstab.extroot.uuid="${UUID}"
  uci set fstab.extroot.target="${MOUNT}"
  uci commit fstab
  mount ${DEVICE} /mnt || error "Failed to mount extroot."
  tar -C ${MOUNT} -cvf - . | tar -C /mnt -xf - || error "Failed to copy overlay data."
}

usb() {
  echo "Do You Needs USB-WAN Support? (y/n)"
  read -r -e -i "n" INSTALL_WAN
  if [[ "$INSTALL_WAN" =~ ^[Yy] ]]; then
    usb_wan_support
  else
    echo "Do You Want To Use USB as Router Storage? (y/n)"
    read -r -e -i "n" EXTEND_STORAGE
    if [[ "$EXTEND_STORAGE" =~ ^[Yy] ]]; then
      usb_storage_support
      extend_storage
      reboot
    fi

    echo "Do You Want To Access USB Data Using SMB? (y/n)"
    read -r -e -i "n" SMB_CONFIG
    if [[ "$SMB_CONFIG" =~ ^[Yy] ]]; then
      usb_storage_support
      configure_samba
      reboot
    fi
  fi
}

usb
