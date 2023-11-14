# Prebuilt ArchLinux ARM images for Orange Pi 5 / 5B / 5 plus

**This project is neither affiliated with ArchLinuxARM nor OrangePi, it's my personal project and I purchased all the needed hardware by myself.**

_This is the doc for the new images using purely Github Actions to deploy nightly, for the old doc for the old images, read [the old doc](README-old.md)_

## Installation
Download a type of release from the [nightly release page](https://github.com/7Ji/orangepi5-archlinuxarm/releases/tag/nightly), there're multiple types of releases to choose from:
 - `-root.tar`:
   - An archive of the complete rootfs which could be extracted to a partitioned disk, you can thus freely decide the partition layout
   - `/etc/fstab` and `/boot/extlinux/extlinux.conf` would need to be updated to point to your new, actual root partition 
   - Does not contain the rkloader
   - DTB set to opi5, change if needed
 - `-base.img`
   - An 2GiB image containing the content of the above image, and already partitioned with a 4MiB offset for rkloader, a 100MiB vfat boot partition and an ext4 root partition taking the remaining space
   - Does not contain the rkloader, but you can write yours to the first 4MiB and remember to re-create the lost partitions
   - DTB set to opi5, change if needed
 - `-5.img`
   - Same as `-base.img` but opi5's rkloader is written in the image
   - DTB set to opi5
   - Can boot directly into the system if using opi5
 - `-5_sata.img`
   - Same as `-base.img` but opi5's rkloader with m.2 remux to sata is written in the image
   - DTB set to opi5
   - DTBO for m.2 remux sata enabled
   - Can boot directly into the system if using opi5 with m.2 sata ssd.
 - `-5b.img`
   - Same as `-base.img` but opi5b's rkloader is written in the image
   - DTB set to opi5b
   - Can boot directly into the system if using opi5b. 
 - `-5_plus.img`
   - Same as `-base.img` but opi5plus' rkloader is written in the image
   - DTB set to opi5plus
   - Can boot directly into the system if using opi5b. 


### Optional: Rkloader (Rockchip Bootloader)
In the above releases, if you choose to use `-root.tar` or `-base.img` then there would be no rkloader included. You're free to allocate the bootloader drive, the boot drive, and the root drive. _E.g., a common choice would be SPI flash as bootloader driver, and your main NVMe/eMMC as boot+root so 0 byte would be wasted on bootloader_

The rkloader image is always 4MiB and should be stored at the beginning of SPI/SD/eMMC, and  it would therefore make the first 4MiB of your drive not usable for data storage.

As long as there's at least one device containing rkloader then your device should boot, no matter it's the SD card, the eMMC, or the SPI flash. And as all of the opi5 family came with an on-board 16MiB/128Mb SPI flash, I'd always recommend using that for rkloader, to save space on your main system drive.

You can download rkloaders for opi5 family from the [nightly release page](https://github.com/7Ji/orangepi5-rkloader/releases/tag/nightly) of my another project orangepi5-rklaoder, they're built and pushed everyday and always contain the latest BL31, DDR and u-boot.

#### Writing to SPI flash
Check the user manual of opi5/5b/5plus if you want to write under another Windows/Linux device.

On the device itself, do it like follows:
 1. Zero-out the SPI flash before writing to it:
    ```
    truncate -s 16M zero.img
    dd if=zero.img of=/dev/mtdblock0 bs=4K
    ```
 2. Write the rkloader image to it:
    ```
    dd if=rkloader.img of=/dev/mtdblock0 bs=4K
    ```
Note that:
 - Writting to SPI flash is very slow, ~60KiB/s, take patience
 - The erase block size of the on-board SPI flash is 4K, you can omit `bs=4K` arg but the default 512 block size would result in 8 writes to the same block for one 4K chunk of data, killing its lifespan very fast.

#### Writing to other block devices
It's always recomended to write the rkloader before you partition the drive, as they contain partition hints on unusable space:
```
# sfdisk -d rkloader-3588-orangepi-5-bl31-v1.38-ddr-v1.11-uboot-70b68713.img
label: gpt
label-id: A56EECCE-C819-4B6A-9C8A-3DD2DA5A5581
device: rkloader-3588-orangepi-5-bl31-v1.38-ddr-v1.11-uboot-70b68713.img
unit: sectors
first-lba: 34
last-lba: 8158
grain: 512
sector-size: 512

rkloader-3588-orangepi-5-bl31-v1.38-ddr-v1.11-uboot-70b68713.img1 : start=          64, size=         960, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, uuid=ED109328-4281-42F8-9F41-E229F38C4973, name="idbloader"
rkloader-3588-orangepi-5-bl31-v1.38-ddr-v1.11-uboot-70b68713.img2 : start=        1024, size=        6144, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, uuid=2162DE6C-AE90-4808-BC19-570D524FCB48, name="uboot"
```
As such, just write the image to your target image, then allocate your partitions with 4 MiB / 8192 sectors offset starting from partition 3, and you're safe from corrupting the rkloader.

Your result partition table would be like the following:
```
# sfdisk -d /dev/mmcblk1
label: gpt
label-id: BB3FDB43-B5B7-4246-A919-BE81F982EE19
device: /dev/mmcblk1
unit: sectors
first-lba: 34
last-lba: 488554462
sector-size: 512

/dev/mmcblk1p1 : start=          64, size=         960, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, uuid=2AFE2EC3-BF29-4066-8287-E99F2C85EE09, name="idbloader"
/dev/mmcblk1p2 : start=        1024, size=        6144, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, uuid=6256FD76-DA9F-4DDE-B499-374B29A6B65B, name="uboot"
/dev/mmcblk1p3 : start=        8192, size=      204800, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, uuid=1B233D55-9FFA-44B7-BBDF-0DDA8B9E7C51
/dev/mmcblk1p4 : start=      212992, size=   488339456, type=B921B045-1DF0-41C3-AF44-4C6F280D3FAE, uuid=3125F455-A424-44F0-ACD9-1843331FA001
```
Specially, mark your boot partition (in this case partition 3) as EFI system partition (`type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B`, in fdisk it's part type `1` when using `t` command), so the bootloader would know to find boot configs/kernel/initramfs from it. 

In your system, the partition would be mounted like this:
```
NAME         MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
mmcblk1      179:0    0   233G  0 disk 
├─mmcblk1p1  179:1    0   480K  0 part 
├─mmcblk1p2  179:2    0     3M  0 part 
├─mmcblk1p3  179:3    0   100M  0 part /boot
└─mmcblk1p4  179:4    0 232.9G  0 part /
```

#### Write to already partitioned drive
This is not recomended as the partition table inside the rkloader image would overwrite your existing part table. But you should still be able to work around it as long as your partitions start after the fist 4MiB:
 1. Dump your existing partitions with `sfdisk -d`:
    ```
    sfdisk -d /dev/mmcblk1 > old_parts.log
    ```
 2. Write the rkloader
    ```
    dd if=rkloader.img of=/dev/mmcblk1 bs=1M count=4
    ```
    _If `of` is a disk image, also add `conv=notrunc`_
 3. Get the current partitions
    ```
    sfdisk -d /dev/mmcblk1 > loader_parts.log
    ```
 4. Modify the current partitions, append your existing partitions in `old_parts.log` after first two parts in `loader_parts.log`, to get your new `new_parts.log`
 5. Apply the new partition table:
    ```
    sfdisk /dev/mmcblk1 < new_parts.log
    ```

## Optional: Boot Configuration
If you're not using the dedicated images, but using `-base.img` or `-root.tar`, then you need to adapt the bootup configurations. In other word, skip this part if you're using `-5/5_sata/5b/5_plus.img`.

The default bootup configuration inside these two releases uses `/extlinux/extlinux.conf` in part 1 and set `rk3588s-orangepi-5.dtb` as the DTB. **If you flash the `-base.img` directly and you're using opi5, then you do not need to change anything**. However for any other combination (opi5 + *.tar, op5b + any, opi5plus + any), you need to adapt the bootup configuration:
 - If you deploy the `*.tar` archive into a single root partition, where `/extlinux/extlinux.conf` supposed in a seperate `/boot` mount point is now stored as `/boot/extlinux/extlinux.conf` under mount point `/`, you need to edit the paths of kernel, initramfs and dtb in `extlinux.conf` to prefix them with `/boot` to reflect their new paths
 - If you're using orange pi 5 b/plus, you need to edit the `FDT=` line to change the DTB name to match your device.
 - If you deploy the `*.tar` archive, and you've formatted the partitions by yourself, then the `root=UUID=xxxx` partition identifier will need to be updated to point to your actual root partition, `/etc/fstab` will also need to be updated
 - If you deploy the `*.tar` archive into a **non-default** `Btrfs` subvolume as your rootfs, you need to add at least argument `rootflags=subvol=[subvolume]` to the `APPEND` line in `/boot/extlinux/extlinux.conf`, and update your `/` mountpoint specification in `/etc/fstab` with mounting option `subvol=[subvolume]` (`genfstab` should help you do the latter one). The variable `[subvolume]` should **be same in both files** and reflect the actual subvolume you're using.

## First boot

The images are all pre-configured to do DHCP on all LAN interfaces and run SSHD with default settings. The hostname is set to `alarm` and there's an existing `alarm` user in `wheel` (sudoer) group with password `alarm_please_change_me`. You can either login locally or through SSH.

## Base Configuration

### Users
A user `alarm` is created with its group set to `wheel`, able to use `sudo` with password, which is set to `alarm_please_change_me`, remember to change it upon first successful login

`root` does not have password and can't be logged in, you could set its password as user `alarm` with the following command:
```
sudo passwd root
```
### Timezone
The timezone is set to `UTC` by default. Use the following command to change that:
```
ln -sf /usr/share/zoneinfo/[Area/City] /etc/localtime
```
### Locale
The one locale enabled and set as default is `en_US.UTF-8`

Edit `/etc/locale.gen` and run `locale-gen` if you want to use other locales, and edit `/etc/locale.conf` to set the new default locale.
### Time sync
The NTP is turned on by default. You can sync the system clock to RTC with the following command
```
hwclock --systohc
```
Run the following command to check local time, universal time, RTC time, timezone, etc:
```
timedatectl
```
### Pacman mirror
The mirror is not modified and is using the official ALARM mirror. You can change that by modifying the mirrorlist and preappend other mirrors
```
vi /etc/pacman.d/mirrorlist
```

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

### WLAN
There's nothing pre-installed or pre-configured about the Wireless LAN, but the wireless drivers are built-in. To get WLAN working, you'll need to choose and install a wireless utility, following [the doc on arch wiki](https://wiki.archlinux.org/title/Network_configuration/Wireless), skipping the driver part. My recommendation would be [wpa_supplicant](https://wiki.archlinux.org/title/Wpa_supplicant) and the following part assumes you choose that.

Note that, the **network manager** and the **wireless utility** are two distinct parts, the latter is only responsible to assosiate your wireless card to the access point (OSI model layer 2), it doesn't even set your IP (OSI model layer 3).

The image already comes with `systemd-networkd` as the network manager. What it lacks is only a wireless utility to help you associate your wireless card with your access point.

#### With systemd-networkd
Assuming you've followed the `wpa_supplicant` doc on Wiki and already succeeded on connection to your AP at least once using `wpa_cli`, then enabling the `wpa_supplicant@[Interface Name].service` and adding another `systemd-networkd` network profile for your network interface would be enough.

#### Without systemd-networkd
If you feel the file-based configuration is too complicated for our `systemd-networkd` + `wpa_supplicant` combo, you can switch to another network manager providing both the network and wireless management, e.g. NetworkManager.

To do so, you need to disable `systemd-networkd` after the your new manager is installed:
```
systemctl disable --now systemd-{network,resolve}d.service
```
**Warning: after running the above command, your board would lose the network connection, so you better do have another network manager already installed and operate directly on the board**

As systemd-networkd is a part of the systemd package, provided by the base package group, you don't need to and can't uninstall it from your system. You can however delete all its config files, if you don't want to go back to it:
```
sudo rm -rf /etc/systemd/network
```

### SSH
`sshd.service` is enabled by default, you could turn that off:
```
systemctl disable sshd.service
```

## Advanced configuration

### Custom repo
By default, there's an additional [7Ji repo](https://github.com/7Ji/archrepo) added to pacman.conf, which is maintained by myself, serving my pre-built packages including kernel and Rockchip MPP related ones, if you don't want to use it, you can remove the repo by modifying `/etc/pacman.conf`:
```
vi /etc/pacman.conf
```
To delete the following part:
```
[7Ji]
Server = https://github.com/7Ji/archrepo/releases/download/$arch
```
And delete my signing key:
```
pacman-key --delete 8815547B7B80370675B3CD20BA27F219383BB875
```
As a alternative, the archlinuxcn repo also hosts pre-built kernels based on my packages, and [a list of all packages](https://github.com/7Ji/archrepo/blob/master/aarch64.yaml) on my repo is available so you can build them by yourself.

_Some of the arch-independent ones are available from AUR so you can use AUR helpers like `yay` to keep them up-to-date by building by yourself (arch-specific ones like kernels, drivers, MPP-related, etc were previous available on AUR but they're either removed or will be removed soon as AUR is purging non pure-x86_64-arch packages)._

The main benefit of the repo is that you can use simply `pacman -Syu` to keep the kernels up-to-date, and install some packages conveniently which are needed for the following steps.

### Desktop environment

The released images and rootfs/pkg archives in this repo are bare-minimum CLI images without any desktop environment.

You can follow https://wiki.archlinux.org/title/Desktop_environment to install a desktop environment you like, ignoring any part related to GPU drivers. After installtion you should end up with `mesa` as your OpenGL library providing software-based `llvmpipe` rendering pipeline, which can be checked by running `glxinfo` in your DE.

### GPU / 3D Acceleration

You can install panfork mesa and the firmware to enable GPU accelration:
```
sudo pacman -Syu mesa-panfork-git mali-valhall-g610-firmware
```

A reboot is neccessary if you've started any GPU work (e.g. entering your DE) during this boot.

#### Tuning

_Addtioanlly, you can set `PAN_MESA_DEBUG=gofaster` environment to let the driver push your GPU to its limit, but as it takes more power and generates more heat, it's only recommended that you set such environment for demanding applications, not globally, unless you have active cooling. For reference, with this env, Minecraft 1.16.5 vanilla on my active cooled OPi5 goes from ~10fps to ~35fps_

#### ARM proprietary blob GPU drivers

Alongside the mainline, open-source panfork MESA, another choice to utilize your GPU to do hardware-backed rendering is to use the closed-source proprietary blob drivers. These are also available from https://github.com/7Ji/archrepo :
```
sudo pacman -Syu libmali-valhall-g610-{dummy,gbm,wayland-gbm,x11-gbm,x11-wayland-gbm}
```

As these drivers do not provide `OpenGL` but only `OpenGLES`, no mainstream DE would work with them, so I didn't set them as global library. You would need to manually specify the driver you want to use when running some program that runs with `OpenGLES`:
```
LD_LIBRARY_PATH=/usr/lib/mali-valhall-g610/x11-gbm [program]
```
_(Multiple variants of the driver could co-exist, you can use the one that meets your current use case)_

For a more detailed list of which kind of blob drivers can be used in combination with `panfork` in X11 or Wayland, check upstream documentation: https://gitlab.com/panfork/mesa

#### OpenGL translation layer for OpenGLES blob GPU drivers
If you want to run OpenGL program with the blob GPU drivers, it won't work as the blob drivers only support OpenGLES, a subset of OpenGL that is mainly used on mobile platforms. You'll need a OpenGL translation layer, `gl4es`, which is also available from https://github.com/7Ji/archrepo :
```
sudo pacman -Syu gl4es-git
```

To run a program with the translation layer on top of the blob drivers:
```
LD_LIBRARY_PATH=/usr/lib/gl4es:/usr/lib/mali-valhall-g610/x11-gbm [program]
```

However, at least from my tests, the results could be even worse than panfork MESA with `gofaster` env, as the translation layer is pure software and is not very efficient.

#### Performance comparison
Here're a few performance comparisons for the drivers:
 - http://webglsamples.org/aquarium/aquarium.html , a WebGL demo, default setting
   - panfork mesa, stock, `chromium`, 35~40 fps
   - panfork mesa, gofaster, `PAN_MESA_DEBUG=gofaster chromium`, ~ 60fps (limtied by vsync)
   - blob, `LD_LIBRARY_PATH=/usr/lib/mali-valhall-g610/x11-gbm chromium --use-gl=egl`, 95~120 fps

 - Minecraft 1.16.5, vanilla, default setting:
   - panfork mesa, stock, ~10fps
   - panfork mesa, gofaster, ~35fps
   - blob, `LD_LIBRARY_PATH=/usr/lib/gl4es:/usr/lib/mali-valhall-g610/x11-gbm hmcl`, ~21fps

### Hardware-based video encoding/decoding

A rockchip mpp (multi-media processing platform) enabled ffmpeg pacakge is also available from https://github.com/7Ji/archrepo that can do hardware based video encoding/decoding, it could be used directly for transcoding, and should also effortlessly make any video players that depend on it do hardware encoding/decoding.
```
sudo pacman -Syu ffmpeg-mpp
```

Addtionally, install ffmpeg4.4-mpp, if you want to use `VLC` (basically the only video player that still uses `ffmpeg4.4` in Arch repo):
   ```
   sudo pacman -Syu ffmpeg4.4-mpp
   ```

### Hardware video decoding web browser

A rockchip mpp enabled Chromium package is also available from https://github.com/7Ji/archrepo, install it and you can do 8K H.264/HEVC/VP9/AV1 decoding on Youtube:
```
sudo pacman -Syu chromium-mpp
```

The package needs extra setup before running, which is documented [here](https://github.com/7Ji-PKGBUILDs/chromium-mpp)

_This Chromium package also supports running with blob drivers, same as how you would run offcial Chromium as docuemnted [above](#performance-comparison)_
