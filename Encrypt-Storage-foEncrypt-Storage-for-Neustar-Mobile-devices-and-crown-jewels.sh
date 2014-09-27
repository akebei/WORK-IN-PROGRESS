#/bin/bash -vvvvv
#######################################################################################################################
# Title: Encrypt New storage for Neustar Crown-Jewels and grant access to group NeustarDirectors exclusively. Encrypt
#        Storage for mobile devices such as Rhel-based OS laptops
#
# Author: Athanasius C. Kebei
#
# References:
# https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/5/html/Installation_Guide/Disk_Encr#yption_Gui#de.html
# https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/pdf/Storage_Administration_Guide/Red_Hat_Ent#erprise_Linux-6-Storage_Administration_Guide-en-US.pdf
#
# Encrypt-Script-proper.sh
#######################################################################################################################
cryptsetup luksFormat /dev/vda1
YES
!C0ntr01
!C0ntr01
crypsetup luksOpen /dev/vda1 verysafename #op
!C0ntr01
pvcreate /dev/mapper/verysafe
vgcreate vgverysafe /dev/mapper/verysafe
lvcreate -n lvverysafe vgverysafe -l +300G
mkfs.ext4 /dev/vgverysafe/lvverysafe
blkid /dev/mapper/verysafe  
mkdir /test
echo -e 'UUID=GJJKku-idhhe--iwS3-oU4K-avEa-GkSa-Y2Hjc1 /test  ext4 defaults  0 0' >> /etc/fstab
mount /dev/vgverysafe/lvverysafe /test
chgrp NeustarDirectors /dev/vgverysafe/lvverysafe
setfacl -m d:g:NeustarDirectors:rwx /dev/vgverysafe/lvverysafe
chmod 2070 /dev/vgverysafe/lvverysafe
cd /test
touch crownjewels.txt
cryptsetup luksClose /dev/vgverysafe/lvverysafe


#########################################################################################################################
# Detail setup of Encrypted partition file system 
#########################################################################################################################
# 1. Create new partition manually first. Only encrypt disk with no data on it!!!!
#fdisk -cu /dev/vda
# new: n
# primary: p
# 1-4: 1
# Enter to use first default sector
# Enter to use all remain sectors or +size in K,M,G: +300G
# print: p
# type (82=swap,83=linux,8e=lvm): t
# 8e
# write: w
# reboot, or partprobe -v

# 2. Encrypt new partition and set a decryption password
cryptsetup luksFormat /dev/vda1
# WARNING!
#This will overwrite data on /dev/vda1 irrevocably.
#Are you sure? (Type uppercase YES): 
YES
#Enter passphrase:
afunde21
#Verify passhrase:
afunde21

# 3. To open/unlock  encrypted volume:
crypsetup luksopen /dev/vda1 verysafename  # OR crypsetup luksopen /dev/vda1 name
Enter passphrase for /dev/sdf1:
# This unlocks /dev/sdf1 as /dev/mapper/verysafe or /dev/mapper/name after you enter the correct password

# 4. Create physical volume
pvcreate /dev/mapper/verysafe
# Physical volume "/dev/mapper/verysafe" successfully created

#5. Create volume group 
 vgcreate vgverysafe /dev/mapper/verysafe
# Volume group "vgverysafe" successfully created
 
# 6. create logical volume
lvcreate -n lvverysafe vgverysafe -l +300G
#Logical volume "lvverysafe" created

# 7. Extend lv
lvextend /dev/mapper/vgverysafe/lvverysafe /dev/mapper/verysafe

#. 8. create file system
mkfs.ext4 /dev/vgverysafe/lvverysafe

mkfs -t ext4 /dev/mapper/verysafe   # Or mkfs.ext4 /dev/mapper/verysafe  
mkfs -t ext4 /dev/vgname/lvname  # or mkfs.ext4 /dev/vgname/lvname

# 9. Determine UUID of files ystem
blkid /dev/mapper/verysafe    
# /dev/vda1: UUID="GJJKku-idhhe--iwS3-oU4K-avEa-GkSa-Y2Hjc1" TYPE="LVM2_member"
blkid /dev/vgverysafe/lvverysafe
#/dev/vgverysafe/lvverysafe: UUID="c5021b6c-62a9-4725-8267-34ed42a63f5e" TYPE="ext4" 


#10. Create mountpoint to mount partition and mount the new filesystem
mkdir /test
echo -e 'UUID=GJJKku-idhhe--iwS3-oU4K-avEa-GkSa-Y2Hjc1 /test  ext4 defaults  0 0' >> /etc/fstab
mount /test

# Mount the filesystem
mount /dev/vgverysafe/lvverysafe /test

# When finished working on the filesystem unmount /dev/mapper/name and run cryptsetup luksClose
# to lock the encrypted volume
umount /dev/vgverysafe/lvverysafe
umount /dev/mapper/verysafe   # umount /dev/mapper/name
umount /dev/mapper/verysafe or umount /dev/mapper/name

cryptsetup luksClose verysafe
cryptsetup luksClose /dev/vgverysafe/lvverysafe
