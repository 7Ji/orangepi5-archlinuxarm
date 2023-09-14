# Common config
. common/scripts/config.sh
# Local config
name_distro+='-OrangePi5'
disk_label='gpt'
disk_split='100M'
enable_systemd_units+=(
  'usb2host.service'
)
release_note_packages+=(
  'linux-aarch64-orangepi5:[my AUR][AUR linux-aarch64-orangepi5]'
  'linux-firmware-orangepi:[my AUR][AUR linux-firmware-orangepi]'
  'usb2host:[my AUR][AUR usb2host]'
  'yay:[AUR][AUR yay]'
)