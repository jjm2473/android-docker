#!/bin/sh
if ! [ -f /data/local/alpine/sys/fs/cgroup/cgroup.controllers ]; then
	mkdir -p /data/local/alpine
	mount --bind rootfs /data/local/alpine
	mount --rbind /mnt /data/local/alpine/mnt
	mount --bind /dev /data/local/alpine/dev
	mount -t tmpfs tmpfs /data/local/alpine/tmp
	mount -t proc proc /data/local/alpine/proc
	mount -t sysfs sysfs /data/local/alpine/sys
	mount -t cgroup2 none /data/local/alpine/sys/fs/cgroup
fi

export TMPDIR=/tmp
export TMP=/tmp
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
/system/bin/chroot /data/local/alpine /bin/sh -i
