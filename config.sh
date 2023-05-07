# Common config
. common/scripts/config.sh
# Local config
disk_label='gpt'
disk_split='100M'
pacstrap_from_repo_pkgs+=(
  'linux-firmware: optional firmware for some devices'
)
name_distro+='-OrangePi5'
release_note_packages+=(
  'linux-aarch64-orangepi5:[my AUR][AUR linux-aarch64-orangepi5]'
  'yay:[AUR][AUR yay]'
)