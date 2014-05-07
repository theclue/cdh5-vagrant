#!/bin/bash
yum install -y parted

parted /dev/sdb mklabel msdos

parted /dev/sdb mkpart primary ext4 0% 100%
sleep 3

#-m swith tells mkfs to only reserve 1% of the blocks for the super block
mkfs.ext4 /dev/sdb1

e2label /dev/sdb1 "dfs"

######### mount sdb1 to /dfs ##############
mkdir /dfs
chmod 777 /dfs

mount /dev/sdb1 /dfs
chmod 777 /dfs

echo '/dev/sdb1 /dfs ext4 defaults 0 0' >> /etc/fstab