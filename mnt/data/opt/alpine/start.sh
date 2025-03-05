#!/bin/sh

TARGET_ROOTFS=/data/local/alpine

if ! [ -e "$TARGET_ROOTFS/proc/cgroups" ]; then
	# kernel provides cgroups?
	if [ ! -e /proc/cgroups ]; then
		echo "/proc/cgroups not exists" >&2
		exit 1
	fi

	# if we don't even have the directory we need, something else must be wrong
	if [ ! -d /sys/fs/cgroup ]; then
		echo "/sys/fs/cgroup not exists" >&2
		exit 1
	fi

	mkdir -p "$TARGET_ROOTFS"
	mount --bind rootfs "$TARGET_ROOTFS"
	busybox mount --make-slave "$TARGET_ROOTFS"
	mkdir "$TARGET_ROOTFS/storage"
	mount --rbind /mnt "$TARGET_ROOTFS/mnt"
	busybox mount --make-rslave "$TARGET_ROOTFS/mnt"
	mount --rbind /storage "$TARGET_ROOTFS/storage"
	busybox mount --make-rslave "$TARGET_ROOTFS/storage"
	rm -rf "$TARGET_ROOTFS/sdcard"
	if [ -L /sdcard ]; then
		cp -a /sdcard "$TARGET_ROOTFS/"
	else
		mkdir "$TARGET_ROOTFS/sdcard"
		mount --rbind /sdcard "$TARGET_ROOTFS/sdcard"
		busybox mount --make-rslave "$TARGET_ROOTFS/sdcard"
	fi
	mount --bind /dev "$TARGET_ROOTFS/dev"
	busybox mount --make-slave "$TARGET_ROOTFS/dev"
	if mountpoint -q /dev/binderfs; then
		mount --bind /dev/binderfs "$TARGET_ROOTFS/dev/binderfs"
		busybox mount --make-slave "$TARGET_ROOTFS/dev/binderfs"
	fi
	mount -t tmpfs tmpfs "$TARGET_ROOTFS/tmp"
	mount -t sysfs sysfs "$TARGET_ROOTFS/sys"
#begin cgroupfs mounting
#cgroupfs v2
	# mount -t cgroup2 none "$TARGET_ROOTFS/sys/fs/cgroup"
#cgroupfs v1
	mount -t tmpfs -o size=4M,uid=0,gid=0,mode=0755 cgroup "$TARGET_ROOTFS/sys/fs/cgroup"
	for controller in $(awk '!/^#/ { if ($4 == 1) print $1 }' /proc/cgroups); do
		mkdir -p "$TARGET_ROOTFS/sys/fs/cgroup/$controller"
		if ! mountpoint -q "$TARGET_ROOTFS/sys/fs/cgroup/$controller" ; then
			if ! mount -n -t cgroup -o $controller cgroup "$TARGET_ROOTFS/sys/fs/cgroup/$controller" ; then
				rmdir "$TARGET_ROOTFS/sys/fs/cgroup/$controller" || true
			fi
		fi
	done

	# cpuset mount with noprefix will cause docker run fail
	[ -e "$TARGET_ROOTFS/sys/fs/cgroup/cpuset/cpuset.cpus" ] || {
		umount "$TARGET_ROOTFS/sys/fs/cgroup/cpuset" 2>/dev/null
		rmdir "$TARGET_ROOTFS/sys/fs/cgroup/cpuset" 2>/dev/null
	}
#end cgroupfs mounting

	mount -t proc proc "$TARGET_ROOTFS/proc"
fi

export TMPDIR=/tmp
export TMP=/tmp
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

/system/bin/chroot "$TARGET_ROOTFS" /bin/sh -i
