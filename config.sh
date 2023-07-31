# Common config
. common/scripts/config.sh
# Local config
disk_label='gpt'
disk_split='100M'
name_distro+='-OrangePi5'
release_note_packages+=(
  'linux-aarch64-orangepi5:[my AUR][AUR linux-aarch64-orangepi5]'
  'linux-firmware-orangepi:[my AUR][AUR linux-firmware-orangepi]'
  'yay:[AUR][AUR yay]'
)