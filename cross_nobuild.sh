#!/bin/bash -e
# Experimental new cross-building script, to replace cross.sh
# Instead of calling build.sh in a QEMU AArch64 ALARM environment, this does everything purely on host
# The expected running environment is Ubuntu 22.04, i.e. the main distro used in Github Actions
# If you're running ALARM, then you should look at build.sh
# If you're running Arch, then you should expect breakage due to Ubuntu FHS being expected


# Mainly for pacman-static
repo_url_archlinuxcn_x86_64=https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/x86_64
# For base system packages
repo_url_alarm_aarch64=http://mirror.archlinuxarm.org/aarch64/'$repo'
# For kernels and other stuffs
repo_url_7Ji_aarch64=https://github.com/7Ji/archrepo/releases/download/aarch64

if [[ "${use_local_mirror}" ]]; then
    repo_url_archlinuxcn_x86_64=http://repo.lan:9129/repo/archlinuxcn_x86_64/x86_64
    repo_url_alarm_aarch64=http://repo.lan:9129/repo/archlinuxarm/aarch64/'$repo'
    repo_url_7Ji_aarch64=http://repo.lan/github-mirror/aarch64
fi

# Everything will be done in a subfolder
mkdir -p cross_nobuild/{bin,cache,img,rkloader}
pushd cross_nobuild

# Get rkloaders
dl() { # 1: url 2: output
    if [[ "$2" ]]; then
        curl -qgb "" -fL --retry 3 --retry-delay 3 -o "$2" "$1"
    else
        curl -qgb "" -fL --retry 3 --retry-delay 3 "$1"
    fi
}
if [[ "${freeze_rkloaders}" ]]; then
    rkloaders=()
    for i in rkloader/*; do
        rkloaders+=("${i##*/}")
    done
else
    rkloader_parent=https://github.com/7Ji/orangepi5-rkloader/releases/download/nightly
    rkloaders=($(dl "${rkloader_parent}"/list))
    for rkloader in "${rkloaders[@]}"; do
        if [[ ! -f rkloader/"${rkloader}" ]]; then
            dl "${rkloader_parent}/${rkloader}" rkloader/"${rkloader}".temp
            mv rkloader/"${rkloader}"{.temp,}
        fi
    done
fi

# Deploy pacman-static
dl "${repo_url_archlinuxcn_x86_64}/archlinuxcn.db" cache/archlinuxcn.db
desc=$(tar -xOf cache/archlinuxcn.db --wildcards 'pacman-static-*/desc')
ver=$(sed -n '/%VERSION%/{n;p;}' <<< "${desc}")
if [[ ! -f bin/pacman-$ver ]]; then
    rm bin/pacman-* || true
    pkg=$(sed -n '/%FILENAME%/{n;p;}' <<< "${desc}")
    dl "${repo_url_archlinuxcn_x86_64}/${pkg}" cache/"${pkg}"
    tar -xOf cache/"${pkg}" usr/bin/pacman-static > bin/pacman-"${ver}".temp
    mv bin/pacman-"${ver}"{.temp,}
fi
chmod +x bin/pacman-"${ver}"
ln -sf pacman-"${ver}" bin/pacman
alias pacman=bin/pacman

# Create temporary pacman config
pacman_mirrors="
[core]
Server = ${repo_url_alarm_aarch64}
[extra]
Server = ${repo_url_alarm_aarch64}
[alarm]
Server = ${repo_url_alarm_aarch64}
[aur]
Server = ${repo_url_alarm_aarch64}"

cat > cache/pacman-loose.conf << _EOF_
[options]
Architecture = aarch64
SigLevel = Optional TrustAll${pacman_mirrors}
_EOF_

cat > cache/pacman-strict.conf << _EOF_
[options]
Architecture = aarch64
SigLevel = DatabaseOptional${pacman_mirrors}
[7Ji]
Server = ${repo_url_7Ji_aarch64}
_EOF_

# Basic image layout
rm -f img/base.img
truncate -s 2G img/base.img
sfdisk img/base.img << _EOF_
label: gpt
start=8192, size=204800, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
start=212992, size=3979264, type=B921B045-1DF0-41C3-AF44-4C6F280D3FAE
_EOF_

# Partition
lodev=$(sudo losetup --find --partscan --show img/base.img)
uuid_root=$(uuidgen)
uuid_boot_mkfs=$(uuidgen)
uuid_boot_mkfs=${uuid_boot_mkfs::8}
uuid_boot_mkfs=${uuid_boot_mkfs^^}
uuid_boot_specifier="${uuid_boot_mkfs::4}-${uuid_boot_mkfs:4}"
sudo mkfs.vfat -n 'ALARMBOOT' -F 32 -i "${uuid_boot_mkfs}" "${lodev}"p1
sudo mkfs.ext4 -L 'ALARMROOT' -m 0 -U "${uuid_root}" "${lodev}"p2

# Mount
root=$(mktemp -d)
sudo mount -o noatime "${lodev}"p2 "${root}"
sudo mkdir -p "${root}"/{boot,dev/{pts,shm},etc/pacman.d,proc,run,sys,tmp,var/{cache/pacman/pkg,lib/pacman,log}}
sudo mount -o noatime "${lodev}"p2 "${root}"/boot
sudo mount proc "${root}"/proc -t proc -o nosuid,noexec,nodev
sudo mount sys "${root}"/sys -t sysfs -o nosuid,noexec,nodev,ro
sudo mount udev "${root}"/dev -t devtmpfs -o mode=0755,nosuid
sudo mount devpts "${root}"/dev/pts -t devpts -o mode=0620,gid=5,nosuid,noexec
sudo mount shm "${root}"/dev/shm -t tmpfs -o mode=1777,nosuid,nodev
sudo mount run "${root}"/run -t tmpfs -o nosuid,nodev,mode=0755
sudo mount tmp "${root}"/tmp -t tmpfs -o mode=1777,strictatime,nodev,nosuid

# Base system
sudo bin/pacman -Sy --config cache/pacman-loose.conf --root "${root}" --noconfirm base
# Temporary network
sudo mount --bind /etc/resolv.conf "${root}"/etc/resolv.conf
# Keyring
run_in_chroot() {
   sudo chroot "${root}" "$@" 
}
run_in_chroot pacman-key --init
run_in_chroot pacman-key --populate
run_in_chroot pacman-key --recv-keys BA27F219383BB875
run_in_chroot pacman-key --lsign BA27F219383BB875

# Non-base packages
kernel='linux-aarch64-orangepi5'
sudo bin/pacman -Sy --config cache/pacman-strict.conf --root "${root}" --noconfirm \
    vim nano sudo openssh \
    7Ji/"${kernel}"{,-headers} \
    linux-firmware-orangepi \
    usb2host

# /etc/fstab
printf '# root partition with ext4 on SDcard / USB drive\nUUID=%s\t/\text4\trw,noatime,data=writeback\t0 1\n# boot partition with vfat on SDcard / USB drive\nUUID=%s\t/boot\tvfat\trw,noatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro\t0 2\n' \
    "${uuid_root}" "${uuid_boot_specifier}" | sudo tee -a "${root}"/etc/fstab

# Time
sudo ln -sf "/usr/share/zoneinfo/UTC" "${root}"/etc/localtime
run_in_chroot timedatectl set-ntp true

# Locale
sudo sed -i 's/^#\(en_US.UTF-8  \)$/\1/g' "${root}"/etc/locale.gen
sudo tee "${root}"/etc/locale.conf <<< LANG=en_US.UTF-8
run_in_chroot locale-gen

# Network
sudo tee "${root}"/etc/hostname <<< alarm
printf '127.0.0.1\tlocalhost\n::1\t\tlocalhost\n' | sudo tee -a "${root}"/etc/hosts
printf '[Match]\nName=eth* en*\n\n[Network]\nDHCP=yes\nDNSSEC=no\n' | 
    sudo tee "${root}"/etc/systemd/network/20-wired.network

# Units
run_in_chroot systemctl enable systemd-{network,resolve}d usb2host sshd

# Users
useradd -g wheel -m alarm
run_in_chroot /bin/sh -c 'printf "%s\n" alarm_please_change_me alarm_please_change_me | passwd alarm'
sudoers="${root}"/etc/sudoers
sudo chmod o+w "${sudoers}"
sudo sed -i 's|^# %wheel ALL=(ALL:ALL) ALL$|%wheel ALL=(ALL:ALL) ALL|g' "${sudoers}"
sudo chmod o-w "${sudoers}"

# QoL: vim link
sudo ln -sf 'vim' "${root}"/usr/bin/vi

# Actual resolv
sudo umount "${root}"/etc/resolv.conf
sudo ln -sf /run/systemd/resolve/resolv.conf "${root}"/etc/resolv.conf

# Extlinux
sudo mkdir "${root}"/boot/extlinux
printf \
    "LABEL\t%s\nLINUX\t/%s\nINITRD\t/%s\nFDT\t/%s\nAPPEND\t%s\n"\
    'Arch Linux for OrangePi 5'\
    "vmlinuz-${kernel}"\
    "initramfs-${kernel}-fallback.img"\
    "dtbs/${kernel}/rockchip/rk3588s-orangepi-5.dtb"\
    "root=UUID=${uuid_root} rw" | 
    sudo tee "${root}"/boot/extlinux/extlinux.conf

# Clean up
sudo rm -rf "${root}"/var/cache/pacman/pkg/*
sudo umount -R "${root}"
sudo losetup --detach "${lodev}"
popd