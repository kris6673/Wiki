# Resize disk in Ubuntu

## Table of Contents

- [Resize disk in Ubuntu](#resize-disk-in-ubuntu)
  - [Table of Contents](#table-of-contents)

Info found [here](https://packetpushers.net/ubuntu-extend-your-default-lvm-space/)

|Command|Used for|
|---|---|
|Lsblk |Giver overblik over disk størrelser|
|Df -h | Giver overblik over disk forbrug|
|cfdisk | Resize partitions|
|vgdisplay | Check Volume Group info|
|Lvdisplay | Check Logical Volume info|
|lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv | Extend Logical volume on VG to full partition/VG size |
|resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv | Resize the filesystem to new LV size. Find dev path with df -h |
