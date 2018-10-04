low-level
====

This is the low level project. It includes all linux stuff to build the robot
image.

We use linux-socfpga and uboot-socfpga dependencies from Altera.

Setup the cross-compile toolchain:
====

We are currently using gcc-linaro-6.1.1-2016.08-x86_64_arm-linux-gnueabihf toolchain

tar -xvf gcc...

Build u-boot:
====

start embedded_command_shel.sh

export CROSS_COMPILE=...

make socfpga_cyclone5_config
make

On obtient notre petit uboot.img

Build linux kernel from source:
====

start embedded_command_shel.sh

export CROSS_COMPILE=...

make ARCH=arm socfpga_defconfig

make ARCH=arm menuconfig

on applique 2-3 options a la con:

Go into the “General Setup” menu. Uncheck “Automatically append version information to the version string”. This will prevent the kernel from adding extra “version” information to the kernel.

And, enter the “Enable the block layer” menu option and enable the “Support for large (2TB+) block devices and files” option. Although the chances of you actually having 2TB+ files on your filesystem are small, if you look at the help for this option (press “?”) you’ll notice that this option is required to be enabled if you’re using the EXT4 filesystem (which we are). If you forget to enable this option, the kernel will mount your filesystem in read-only mode and print out a helpful message reminding you to come back and enable this if you want full read/write support.

When you’re done looking at the available options, hit the right arrow key to select the “Save” option at the bottom of the window and press enter. When asked for a filename, leave it at the default (“.config”) and hit enter. Hit enter again, then exit the configuration tool.

OTG
CFG802xxx wireless extension
ext4
no version append

on save

make ARCH=arm

on obtient notre petit zImage des familles

Build linux driver:
====

On build ensuite les drivers qu'on veux en faisant gaffe au path du kernel
et de la chaine de cross compile gcc

on obtient les .ko qui vont bien et on les scp sur la target

Creating the image:
====

Une fois qu'on a tout, on fait notre petite carte sd:

on s'assure de rm toutes les partoch de la sd avant de commencer, de toute facon
on va tout bousiller apres avec le fdisk

sudo fdisk /dev/sdb
n p 3 default +1M
n p 1 default +64M
n p 2 default default
t 3 a2
t 1 b
w

mkfs -t vfat /dev/sdb1
mkfs.ext4 /dev/sdb2

dd if=./u-boot/u-boot-spl.sfp of=/dev/sdb3 bs=64k seek=0
dd if=./u-boot/u-boot.img of=/dev/sdb3 bs=64k seek=4

sudo mount /dev/sdb2 usb2
sudo tar -xvf rootfs.tgz -C usb2

sudo mount /dev/sdb1 usb1
sudp cp zImage dtb uEnv rbf > usb1

umount le tout
sync
done

Boot and configuration:
====

Ensuite sur la target (si on a tout bien fait):

on fait gaffe si on veux que wlan0 ne soit pas renomme:
ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules

On peux set une mac fix dans le uboot
setenv ethaddr MAC_ADDR
saveenv

on peut se creer un petit /etc/rc.local dans lequel on monte les drivers et on
conf le reseau

insmod *.ko

conf reseau
ifconfig wlan0 up
iwconfig wlan0 mode Managed
iwconfig wlan0 essid ESSID

Warnings:
====

Remarque:

Pour les 2 cpu on oublie pas la petite option dans le .dts:

enable-method = "altr,socfpga-smp";


le build peux foire si on est sur un system x64. bien penser a installer des
paquets du style

sudo apt-get install gcc-multilib


