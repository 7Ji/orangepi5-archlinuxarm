#!/bin/bash -e

# Common config
. common/scripts/config.sh
# Local config
disk_label='gpt'
pacstrap_from_repo_pkgs+=(
  'linux-firmware: optional firmware for some devices'
)
name_distro+='-OrangePi5'
release_note_packages+=(
  'linux-aarch64-orangepi5:[my AUR][AUR linux-aarch64-orangepi5]'
  'yay:[AUR][AUR yay]'
)
# Common functions
. common/functions/build.sh
# Overload common functions
prepare_blob() { :; }
populate_blob() {
  populate_boot
}
remove_non_fallback() {
  echo " => Removing non-fallback initramfs..."
  sudo rm -f ${dir_boot}/initramfs-linux-aarch64-orangepi5.img
  echo " => Removed non-fallback initramfs"
}
# Local functions
populate_boot() {
  echo " => Populating boot partition..."
  echo "  -> Writing booting configuration..."
  local kernel='linux-aarch64-orangepi5'
  local temp_extlinux=$(mktemp)
  printf \
    "LABEL\t%s\nLINUX\t/%s\nINITRD\t/%s\nFDT\t/%s\nAPPEND\t%s\n"\
        'Arch Linux for OrangePi 5'\
        "vmlinuz-${kernel}"\
        "initramfs-${kernel}-fallback.img"\
        "dtbs/${kernel}/rockchip/rk3588s-orangepi-5.dtb"\
        "root=UUID=${uuid_root} rw" > "${temp_extlinux}"
  sudo mkdir -p "${dir_boot}/extlinux"
  sudo cp "${temp_extlinux}" "${dir_boot}/extlinux/extlinux.conf"
  rm -f "${temp_extlinux}"
  echo " => Populated boot partition"
}
# Actual build
build