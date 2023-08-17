# ArchLinux ARM for Orange Pi 5 / 5B / 5 plus

## Installation
Download a release from the [releases page](https://github.com/7Ji/orangepi5-archlinuxarm/releases) or [Actions](https://github.com/7Ji/orangepi5-archlinuxarm/actions). There're several different types of release to choose from:
 - `ArchLinuxARM-aarch64-OrangePi5-*.img.xz`
   - a compressed disk image which you could just decompress and write to disk
     - `xz -cdk < ArchLinuxARM-aarch64-OrangePi5-*.img.xz > /dev/theTargetDisk`
   - partition layout and filesystems are pre-determined and you can't easily change (remember to enlarge the root partition)
   - booting configuration already set and ready to go, just plug in the card and it will boot right into the system
   - **Rockchip bootloader not included to save space**, it is expected to be installed by yourself on SPI flash beforehand with the tools provided in either OrangePi's Debian/Ubuntu or official Armbian
 - `ArchLinuxARM-aarch64-OrangePi5-*-root.tar.xz`
   - a compressed rootfs archive of stuffs in the above image which you should extract to a partitioned disk
     - `bsdtar -C /mnt/yourMountPoint --acls --xattrs -xvpJf ArchLinuxARM-aarch64-OrangePi5-*-root.tar.xz`
   - partition layout non-exist, you should partition the card (**must be GPT**) and format the partitions in whatever way you like it
   - `/etc/fstab` and `/boot/extlinux/extlinux.conf` should be updated to reflect the actual disk layout
   - **Rockchip bootloader not included to save space**, it is expected to be installed by yourself on SPI flash beforehand with the tools provided in either OrangePi's Debian/Ubuntu or official Armbian
 - `ArchLinuxARM-aarch64-OrangePi5-*-pkgs.tar.xz`
   - a compressed archive of AUR packages installed into the above image
   - useful if you want to `pacstrap` an installation without the above image
   - useful if you want to update your installation without compiling the packages by yourself

## Configuration
### Bootup
The default bootup configuration uses `/extlinux/extlinux.conf` and set `rk3588s-orangepi-5.dtb` as the DTB. **If you flash the `*.img` directly and you're using opi5, then you do not need to change anything**. However for any other combination (opi5 + *.tar, op5b + any, opi5plus + any), you need to adapt the bootup configuration:
 - If you deploy the `*.tar` archive into a single root partition, where `/extlinux/extlinux.conf` supposed in a seperate `/boot` mount point is now stored as `/boot/extlinux/extlinux.conf` under mount point `/`, you need to edit the paths of kernel, initramfs and dtb in `extlinux.conf` to prefix them with `/boot` to reflect their new paths
 - If you're using orange pi 5 b/plus, you need to edit the `FDT=` line to change the DTB name to match your device.
 - If you deploy the `*.tar` archive, and you've formatted the partitions by yourself, then the `root=UUID=xxxx` partition identifier will need to be updated to point to your actual root partition, `/etc/fstab` will also need to be updated
 - If you deploy the `*.tar` archive into a **non-default** `Btrfs` subvolume as your rootfs, you need to add at least argument `rootflags=subvol=[subvolume]` to the `APPEND` line in `/boot/extlinux/extlinux.conf`, and update your `/` mountpoint specification in `/etc/fstab` with mounting option `subvol=[subvolume]` (`genfstab` should help you do the latter one). The variable `[subvolume]` should **be same in both files** and reflect the actual subvolume you're using.

### Users
 - `root`'s default password is `alarm_please_change_me`, remember to change it upon first successful login  
 - A user `alarm` is created with its group set to `wheel`, able to use `sudo` with password, which is set to `alarm_please_change_me`, remember to change it upon first successful login
### Timezone
The timezone is set to `Asia/Shanghai` by default. Use the following command to change that:
```
ln -sf /usr/share/zoneinfo/[Area/City] /etc/localtime
```
### Locale
The following locales are enabled by default:
```
en_GB.UTF-8
en_US.UTF-8
zh_CN.UTF-8
```
and `en_GB.UTF-8` is set as the default locale

Edit `/etc/locale.gen` and run `locale-gen` if you want to use other locales, and edit `/etc/locale.conf` to set the new default locale.
### Time sync
The NTP is turned off by default. Use the following command to enable NTP if you want to keep the clock in sync:
```
timedatectl set-ntp true
```
### Pacman mirror
The mirror is set to tuna's mirror in China by default, edit it if you don't like it or it's slow in your country:
```
vi /etc/pacman.d/mirrorlist
```
Remember to run a full system update upon first boot:
```
yay
```

**Note: some packages including the kernel package `linux-aarch64-orangepi5` are installed as local packages, as they are not available from the official repos, this means if you want to upgrade them, you'll have to do it one of the following ways:**
 1. Use AUR helpers like `yay`, they will build and install the packages for you. **You will have to spend a lot of time on building if your device or distcc network is not powerful enough.**
    - For reference, on an actively cooled opi5 at stock frequency with 8G RAM, with a Samsung 960 EVO NVMe SSD as the build drive,  the average build time for the `linux-aarch64-oragepi5-5.10.110-4` alone is about 45 minutes.
 2. Download the build artifacts of the newest github action CI, unzip it and you'll get `*-pkgs.tar.xz`, you can extract all pre-built packages in the image, then use `pacman -U` to install them as local packages. **You do not need to build the packages**
 3. Add [my repo](https://github.com/7Ji/archrepo) as an additional pacman repo, read instructions on that repo on how to add it. You can then use `pacman -Syu` to update these packages. **You do not need to build the packages**

### Hostname
The hostname is set to `alarm` by default, if you want to change that, edit `/etc/hostname`

### Network
`systemd-networkd.service` and `systemd-resolved.service` are enabled by default, and will do DHCP on interface `eth*` and `en*` to get IP, gateway and DNS. Check your router to get IP if you're doing a headless installation.

Edit `/etc/systemd/network/20-wired.network` to like the following if you want a static IP instead:
```
[Match]
Name=eth* en*

[Network]
Address=[Your static IP with mask, e.g. 192.168.123.234/24]
Gateway=[Your gateway, e.g. 192.168.123.1]
DNS=[Your DNS, e.g. 192.168.123.1, or 8.8.8.8]
```
### SSH
`sshd.service` is enabled by default, and is set to accept root login. Edit `/etc/ssh/sshd_config` to turn off root login if you find that dangerous. Change the following line:
```
PermitRootLogin yes
```
To
```
PermitRootLogin no
```
Or (if commented, the default value `prohibit-password` is used)
```
#PermitRootLogin yes
```

### GPU / 3D Acceleration
The released images and rootfs/pkg archives in this repo are bare-minimum CLI images without any desktop environment.

You can follow https://wiki.archlinux.org/title/Desktop_environment to install a desktop environment you like, ignoring any part related to GPU drivers. After installtion you should end up with `mesa` as your OpenGL library providing software-based `llvmpipe` rendering pipeline, which can be checked by running `glxinfo` in your DE.

Assuming you've installed a DE and made sure you can enter the software-rendered desktop envinroment (so we can guarantee the only part that's not working is the OpenGL library), you can do the following steps to enable GPU accelration:

  1. Add my repo following the instructions: https://github.com/7Ji/archrepo
  2. Install panfork mesa:
     ```
     sudo pacman -Syu mesa-panfork-git
     ```
  3. Download the firmware for GPU
     ```
     wget https://github.com/JeffyCN/mirrors/raw/libmali/firmware/g610/mali_csffw.bin -O /tmp/mali_csffw.bin
     sudo cp /tmp/mali_csffw.bin /usr/lib/firmware/
     ```

A reboot is neccessary if you've started any GPU work (e.g. entering your DE) during this boot.

### Hardware-based video encoding/decoding

A rockchip mpp (multi-media processing platform) enabled ffmpeg pacakge is also available from my repo that can do hardware based video encoding/decoding:

1. Add my repo following the instructions: https://github.com/7Ji/archrepo
2. Install ffmpeg-mpp:
   ```
   sudo pacman -Syu ffmpeg-mpp
   ```

## Build
The project needs to be built in a native ArchLinux ARM environment, which could be obtained through the image here or pacstrapping with the help of kernel packages here on Orange Pi 5 itself.

Due to some quirks in the kernel source and mismatching in ArchLinux ARM's native gcc and ArchLinux's distccd-alarm-armv8 package from AUR recommended by ArchLinux ARM, some flags will be carried wrongly to the x86_64 hosted aarch64 distcc server during the kernel compilation. You must build this project (or at least the kernel package) **with distcc disabled**

### Getting the source
The source could be got with a simple command like the following:
```
git clone --recursive https://github.com/7Ji/orangepi5-archlinuxarm.git
```
The flag `--recursive` is neccessary to also pull the common build scripts and AUR pacakges
### Updating the source
For future builds, the source should be updated to make sure it is not outdated. When pulling the changes you will also need to update the submodules:
```
git pull
git submodule init # If you see a new AUR package added, this is a must
git submodule update
```
### Environment variable
Some environment variable could be set to determine the build script's behaviour:
 - `compressor`
   - A combination of compressor executable and argument
     - `xz -9ev` is the default, for maximum compression with xz
     - `gzip -1` is faster
     - you can freely decide the combination
   - If set to `no`, the release won't be compressed, so you can split the build work to aarch64 and compression work to a powerful x86_64 machine, for example.
### Actual build
Use the following command **inside this folder** to build:
```
./build.sh
```
Or if you want to run it with the shell claimed instead (not recommended):
```
bash -e build.sh
```
The `-e` flag is mandatory! It will let the script bail out as song as any error encountered

## Source
The script is mostly based on [the alarm builder common](https://github.com/7Ji/alarm-builder-common) project

The packges installed in the image are mostly from ArchLinux ARM's official repo

Addtional AUR packages installed:
 - linux-aarch64-orangepi5 is from [my AUR](https://aur.archlinux.org/packages/linux-aarch64-orangepi5)
 - yay is from [AUR](https://aur.archlinux.org/packages/yay)

## License
The builder project is licensed under GPLv3, whereas the image provided follows the same license as ArchLinux ARM itself.
