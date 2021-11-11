#!/bin/bash
FW_REPO="https://raw.githubusercontent.com/Hexxeh/rpi-firmware/"
KERNEL_REPO="https://github.com/raspberrypi/linux/"

ACTIVE_KERNEL=`uname -r`
MODULE_DIR="/lib/modules/$ACTIVE_KERNEL"

modinfo generic_raw_uart &> /dev/null && RC=$? || RC=$?
if [ $RC -eq 0 ]; then
  exit
fi

if [ -e $MODULE_DIR/build ]; then
  exit
fi

set -e

if [ -f /boot/.firmware_revision ]; then
  FW_HASH=`cat /boot/.firmware_revision`
  KERNEL_GIT_HASH=`wget -O - -q $FW_REPO$FW_HASH/git_hash`
  KERNEL_GIT_VERSION=`wget -O - -q $FW_REPO$FW_HASH/uname_string7 | cut -d' ' -f3`

  if [ "$KERNEL_GIT_VERSION" != "$ACTIVE_KERNEL" ]; then
    echo "/boot/.firmware_revision does not match active kernel version."
    exit 1
  fi

  echo "Downloading kernel sources from GIT"
  wget -O $MODULE_DIR/linux.tar.gz -q $KERNEL_REPO/archive/$KERNEL_GIT_HASH.tar.gz

  echo "Unpacking kernel sources"
  cd $MODULE_DIR
  tar -xzf $MODULE_DIR/linux.tar.gz
  rm $MODULE_DIR/linux.tar.gz
  mv $MODULE_DIR/linux-$KERNEL_GIT_HASH $MODULE_DIR/source
  ln -sf $MODULE_DIR/source $MODULE_DIR/build

  echo "Configuring kernel sources"
  cd $MODULE_DIR/source
  KERNEL=kernel7
  modprobe configs &> /dev/null
  zcat /proc/config.gz > $MODULE_DIR/source/.config
  make modules_prepare
else
  echo "Could not determine kernel source."
  exit 1
fi

