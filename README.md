# Prebuilt ArchLinux ARM images for Orange Pi 5 / 5B / 5 plus

**This project is neither affiliated with ArchLinuxARM, ArchLinux nor OrangePi, it's my personal project and I purchased all the needed hardware by myself.**

## Installation
Download a type of release from the [nightly release page](https://github.com/7Ji/orangepi5-archlinuxarm/releases/tag/nightly), there're multiple types of releases to choose from
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
   - Can boot directly into the system if using opi5plus. 

### Optional: Rkloader (Rockchip Bootloader)
In the above releases, if you choose to use `-root.tar` or `-base.img` then there would be no rkloader included. You're free to allocate the bootloader drive, the boot drive, and the root drive. _E.g., a common choice would be SPI flash as bootloader driver, and your main NVMe/eMMC as boot+root so 0 byte would be wasted on bootloader_

Download rkloaders from my another project [orangepi5-rkloader](https://github.com/7Ji/orangepi5-rkloader) and follow the installation guide there.

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


## Manual installation using pacstrap
It is also possible to just `pacstrap` another installation from ground up like how you would do it on x86_64 ArchLinux following the [ArchLinux installation guide](https://wiki.archlinux.org/title/Installation_guide), using these images as your archiso-like installation media. Note the following differences:
- You must deploy rkloader to either SPI Flash, eMMC or SD
  - It needs to be one that is different from your current boot medium as the current one would later be removed.
  - Imagine this as your PC BIOS, the board won't boot without it.
- The partition label can only be GPT
  - The u-boot inside the rkloader does not recognize MBR, it is hardcoded by Rockchip to do so to be compatible with their rkloader offset.
- The boot partition needs to be marked as EFI system partition in the GPT, if it's not the first partition.
  - The u-boot picks GPT/MBR ESP -> MBR Boot -> first partition, as the partition to look for boot configuration.
- It's not recommended to use fs or fs features added after 5.10.110.
- It's recommendded to only create two partitions, one with FAT32 mounted at `/boot`, and another with your perferred root fs mounted at `/`
  - Alternatively, the u-boot supports to read from an `ext4` partition, so you can just have one big root partition. 
- Use `linux-aarch64-rockchip-rk3588-bsp5.10-orangepi` instead of `linux` as your kernel, `linux` is mainline kernel from ALARM official repo and won't work.
- Use `linux-firmware-orangepi-git` instead of `linux-firmware` as your firmware, this contains essential wireless firmware for 5b. For 5+ or 5, `linux-firmware` also work, but takes more space
- The boot configuration is `(/boot/)extlinux/extlinux.conf` inside the boot partition, and it uses a similar format to [syslinux format documented on ArchWiki](https://wiki.archlinux.org/title/Syslinux#Configuration).
  - `LINUX` is the path of kernel relative to the filesystem root, e.g. 
    ```
    LINUX  /vmlinuz-linux-aarch64-rockchip-rk3588-bsp5.10-orangepi
    ```
  - `INITRD` for initramfs, similarly, e.g. 
    ```
    INITRD  /initramfs-linux-aarch64-rockchip-rk3588-bsp5.10-orangepi.img
    ```
  - `FDT` for Flattened Device Tree, or Device Tree Blob, similary, e.g. 
    ```
    FDT  /dtbs/linux-aarch64-rockchip-rk3588-bsp5.10-orangepi/rockchip/rk3588-orangepi-5-plus.dtb
    ```
  - `FDTOVERLAYS` is for a list for FDT/DTB overlays, only needed when you need the overlays, e.g.
    ```
    FDTOVERLAYS  /dtbs/linux-aarch64-rockchip-rk3588-bsp5.10-orangepi/rockchip/overlay/rk3588-hdmirx.dtbo /dtbs/linux-aarch64-rockchip-rk3588-bsp5.10-orangepi/rockchip/overlay/rk3588-disable-led.dtbo
    ```
  - `APPEND` is for kernel command line, e.g. 
    ```
    APPEND  root=/dev/disk/by-path/platform-fe2e0000.mmc-part2 rootflags=subvol=@root rw console=ttyFIQ00,1500000 console=tty1
    ```  
- Add [my repo](https://github.com/7Ji/archrepo) to the target installation if you want to upgrade later using only `pamcan -Syu`

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

### Kernel selection
The images pack two different kernel packages, [linux-aarch64-rockchip-rk3588-bsp5.10-orangepi](https://github.com/7Ji-PKGBUILDs/linux-aarch64-rockchip-rk3588-bsp5.10-orangepi), which tracks the revision orangepi uses internal in their [build system](https://github.com/orangepi-xunlong/orangepi-build/tree/next/external/config/boards), and [linux-aarch64-rockchip-rk3588-bsp5.10-orangepi-git](https://github.com/7Ji-PKGBUILDs/linux-aarch64-rockchip-rk3588-bsp5.10-orangepi-git), which tracks directly their kernel tree.

All my kernel pacakges available under my repo do not conflict with each other, including these two.

As of this writting, the non-git version is at `5.10.110-6`, and the -git version is at `5.10.160.r48.eb1c681e5.ced0156-1`. The default boot target is the non-git version, but I highly recommend to migrate to the -git version.

The booting configration `/boot/extlinux/extlinux.conf` should look like this in a new installation:
```
DEFAULT linux-aarch64-rockchip-rk3588-bsp5.10-orangepi
LABEL   linux-aarch64-rockchip-rk3588-bsp5.10-orangepi
        LINUX   /vmlinuz-linux-aarch64-rockchip-rk3588-bsp5.10-orangepi
        INITRD  /initramfs-linux-aarch64-rockchip-rk3588-bsp5.10-orangepi-fallback.img
        FDT     /dtbs/linux-aarch64-rockchip-rk3588-bsp5.10-orangepi/rockchip/rk3588s-orangepi-5.dtb
        FDTOVERLAYS     /dtbs/linux-aarch64-rockchip-rk3588-bsp5.10-orangepi/rockchip/overlay/rk3588-ssd-sata0.dtbo
        APPEND  root=UUID=61c8756a-f424-4f05-99e9-0318ad48afa8 rw
LABEL   linux-aarch64-rockchip-rk3588-bsp5.10-orangepi-git
        LINUX   /vmlinuz-linux-aarch64-rockchip-rk3588-bsp5.10-orangepi-git
        INITRD  /initramfs-linux-aarch64-rockchip-rk3588-bsp5.10-orangepi-git-fallback.img
        FDT     /dtbs/linux-aarch64-rockchip-rk3588-bsp5.10-orangepi-git/rockchip/rk3588s-orangepi-5.dtb
        FDTOVERLAYS     /dtbs/linux-aarch64-rockchip-rk3588-bsp5.10-orangepi-git/rockchip/overlay/rk3588-ssd-sata0.dtbo
        APPEND  root=UUID=61c8756a-f424-4f05-99e9-0318ad48afa8 rw
```
To switch the version, simple modify the `DEFAULT` line and point it to a different `LABEL`.

If you want to be able to change the booting target interactively during the boot process, you can add a line like `TIMEOUT 30` after the `DEFAULT` line, which means to wait for 3 seconds to let you make the choice. Personally I feel this a waste of time because I use them as headless servers.

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
