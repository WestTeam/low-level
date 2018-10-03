#!/bin/bash

echo Welcome - Robot Image Generator V1.0

echo Make sure you run the script in the correct directory.
echo Default: PATH-TO-GITHUB/software/robot_filesystem/

echo "Press <Enter> to continue..."
read touche
case $touche in
*)  echo "Creating the empty image..."
    ;;
    esac

# create an empty image file of 3.8Go
image="robot.img"

dd if=/dev/zero of=$image bs=800M count=1 # about 3.8Go

# Use a loopback device for partition and data
ld=$(losetup --show -f $image)

echo Loopback device is: $ld
# Use fdisk to create partition tables

sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $ld
o # clear the in memory partition table
n # new partition
p # primary partition
3 # partition number 3
# default - start at beginning of disk
+1M # 1 MB uboot

n # new partition
p # primary partition
1 # partion number 1
# default, start immediately after preceding partition
+64M # 64 MB for dtb files and others stuff

n # new partition
p # primary partition
2 # partion number 1
# default, start immediately after preceding partition
# default, extend to the end

t # change partition
3 # partition 3
a2 # MBR

t # change partition
1 # partition 1
b # W95 FAT32

w # write the partition table
q # and we're done
EOF

partprobe $ld

# Create the filesystem
part1=$ld
part2=$ld
part3=$ld

part1+="p1"
part2+="p2"
part3+="p3"

mkfs -t vfat $part1
mkfs.ext4 $part2

# Burn u-boot in partition 3 at index 4
dd if=./u-boot/u-boot-spl.sfp of=$part3 bs=64k seek=0
dd if=./u-boot/u-boot.img of=$part3 bs=64k seek=4

# Create temp dir to cp device files to
mkdir tmp_mnt
mount $part1 ./tmp_mnt

cp boot/soc_system.dtb boot/soc_system.rbf boot/uEnv.txt boot/zImage tmp_mnt

# Sync, umount devices and ask to burn the image
sync
umount tmp_mnt
rm -rf tmp_mnt

# Create temp dir to cp rootfs files to
mkdir tmp_rootfs
mount $part2 ./tmp_rootfs

echo -n "Enter path to your root FS tarball and press [ENTER]?";
read rootfs_path;

#Untar the rootfs
tar xfz $rootfs_path -C ./tmp_rootfs

# Sync, umount devices and ask to burn the image
sync
umount tmp_rootfs
rm -rf tmp_rootfs

echo Successfully created robot.img file to burn on your SD card

while true; do
    read -p "Burn $image to a specific device?[Yn]" yn
    case $yn in
       [Yy]* ) echo -n "Enter path to your sd card and press [ENTER]?";
       read path;
       break;;
       [Nn]* ) exit;;
       * );;
    esac
done

# Last confirmation with warning
while true; do
    read -p "Device $path will be formatted. Do you want to continue?[Yn]" yn
    case $yn in
       [Yy]* ) break;;
       [Nn]* ) exit;;
       * );;
    esac
done

echo Burning image to: $path
dd if=$image | pv | dd of=$path bs=2048

exit 0
