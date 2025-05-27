#!/bin/bash
# USB Storage configuration for WrtMate

usbstorage() {
  # Install required packages
  opkg install kmod-usb-storage kmod-usb-storage-uas usbutils block-mount e2fsprogs kmod-fs-ext4 libblkid kmod-fs-exfat exfat-fsck || error_exit "Failed to install USB-Storage packages."

  # Format USB storage
  mkfs.ext4 /dev/sda1 || error_exit "Failed to format USB storage."
  block detect | uci import fstab || error_exit "Failed to detect block devices."
  uci set fstab.@mount[-1].enabled='1'
  uci set fstab.@global[0].check_fs='1'
  uci commit fstab
  /etc/init.d/fstab boot || error_exit "Failed to boot fstab."

  # Configure SMB if requested
  echo "Do You Want To Access USB Data Using SMB? (yes/no)"
  read -e -i "yes" SMB_CONFIG
  if [[ "$SMB_CONFIG" != "no" ]]; then
    opkg install luci-app-samba4 || error_exit "Failed to install Samba4."
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
  fi

  # Configure USB as router storage if requested
  echo "Do You Want To Use USB as Router Storage? (yes/no)"
  read -e -i "no" EXTEND_STORAGE
  if [[ "$EXTEND_STORAGE" == "yes" ]]; then
    opkg install block-mount kmod-fs-ext4 e2fsprogs parted || error_exit "Failed to install storage extension packages."
    parted -s /dev/sda -- mklabel gpt mkpart extroot 2048s -2048s || error_exit "Failed to partition USB storage."

    # Configure extroot
    DEVICE="$(block info | sed -n -e '/MOUNT="\S*\/overlay"/s/:\s.*$//p')"
    uci -q delete fstab.rwm
    uci set fstab.rwm="mount"
    uci set fstab.rwm.device="${DEVICE}"
    uci set fstab.rwm.target="/rwm"
    uci commit fstab

    # Format and configure extroot partition
    DEVICE="/dev/sda1"
    mkfs.ext4 -L extroot ${DEVICE} || error_exit "Failed to format extroot."
    eval $(block info ${DEVICE} | grep -o -e 'UUID="\S*"')
    eval $(block info | grep -o -e 'MOUNT="\S*/overlay"')
    uci -q delete fstab.extroot
    uci set fstab.extroot="mount"
    uci set fstab.extroot.uuid="${UUID}"
    uci set fstab.extroot.target="${MOUNT}"
    uci commit fstab

    # Copy overlay data
    mount ${DEVICE} /mnt || error_exit "Failed to mount extroot."
    tar -C ${MOUNT} -cvf - . | tar -C /mnt -xf - || error_exit "Failed to copy overlay data."
  fi

  # Reboot to apply changes
  reboot
}

usbstorage