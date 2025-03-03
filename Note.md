## 踩坑记录

### 将分区1的typecode改成0700，使安卓自动挂载
```
sgdisk --typecode 0:0700 /dev/block/nvme0n1
```

### chroot 启动 dockerd 情况下，docker pull hello-world 失败
错误信息：
```
> docker pull hello-world
Using default tag: latest
latest: Pulling from library/hello-world
c9c5fd25a1bd: Extracting  3.156kB/3.156kB
failed to register layer: remount /, flags: 0x84000: invalid argument
```

strace跟踪错误位置:
```
[pid  2489] mount("", "/", 0x400098d52c, MS_REC|MS_SLAVE, NULL <unfinished ...>
[pid  2458] <... nanosleep resumed>NULL) = 0
[pid  2489] <... mount resumed>)        = -1 EINVAL (Invalid argument)
```

chroot前先执行`mount --bind rootfs rootfs`重新挂载rootfs，或者挂载到其他路径。


### chroot 启动 dockerd 情况下，docker run hello-world 失败
```
docker: Error response from daemon: failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: error jailing process inside rootfs: pivot_root .: invalid argument: unknown.
```

dockerd 加上环境变量 DOCKER_RAMDISK=true：
```
DOCKER_RAMDISK=true dockerd --config-file=/mnt/data/opt/dockerd/daemon.json
```


### cgroupfs v2 警告问题
如果使用cgroupfs v2，也就是`mount -t cgroup2 none /data/local/alpine/sys/fs/cgroup`，dockerd 会显示缺少部分 controllers。

```
> ./check-config.sh
info: reading kernel config from /proc/config.gz ...

Generally Necessary:
- cgroup hierarchy: cgroupv2
  Controllers:
  - cpu: missing
  - cpuset: missing
  - io: missing
  - memory: missing
  - pids: available
- CONFIG_NAMESPACES: enabled
- CONFIG_NET_NS: enabled
- CONFIG_PID_NS: enabled
- CONFIG_IPC_NS: enabled
- CONFIG_UTS_NS: enabled
- CONFIG_CGROUPS: enabled
- CONFIG_CGROUP_CPUACCT: enabled
- CONFIG_CGROUP_DEVICE: enabled
- CONFIG_CGROUP_FREEZER: enabled
- CONFIG_CGROUP_SCHED: enabled
- CONFIG_CPUSETS: enabled
- CONFIG_MEMCG: enabled
- CONFIG_KEYS: enabled
- CONFIG_VETH: enabled
- CONFIG_BRIDGE: enabled
- CONFIG_BRIDGE_NETFILTER: enabled
- CONFIG_IP_NF_FILTER: enabled
- CONFIG_IP_NF_MANGLE: enabled
- CONFIG_IP_NF_TARGET_MASQUERADE: enabled
- CONFIG_NETFILTER_XT_MATCH_ADDRTYPE: enabled
- CONFIG_NETFILTER_XT_MATCH_CONNTRACK: enabled
- CONFIG_NETFILTER_XT_MATCH_IPVS: enabled
- CONFIG_NETFILTER_XT_MARK: enabled
- CONFIG_IP_NF_NAT: enabled
- CONFIG_NF_NAT: enabled
- CONFIG_POSIX_MQUEUE: enabled
- CONFIG_CGROUP_BPF: enabled

Optional Features:
- CONFIG_USER_NS: enabled
- CONFIG_SECCOMP: enabled
- CONFIG_SECCOMP_FILTER: enabled
- CONFIG_CGROUP_PIDS: enabled
- CONFIG_MEMCG_SWAP: missing
    (cgroup swap accounting is currently enabled)
- CONFIG_BLK_CGROUP: enabled
- CONFIG_BLK_DEV_THROTTLING: enabled
- CONFIG_CGROUP_PERF: enabled
- CONFIG_CGROUP_HUGETLB: enabled
- CONFIG_NET_CLS_CGROUP: enabled
- CONFIG_CGROUP_NET_PRIO: enabled
- CONFIG_CFS_BANDWIDTH: enabled
- CONFIG_FAIR_GROUP_SCHED: enabled
- CONFIG_IP_NF_TARGET_REDIRECT: enabled
- CONFIG_IP_VS: enabled
- CONFIG_IP_VS_NFCT: enabled
- CONFIG_IP_VS_PROTO_TCP: enabled
- CONFIG_IP_VS_PROTO_UDP: enabled
- CONFIG_IP_VS_RR: enabled
- CONFIG_SECURITY_SELINUX: enabled
- CONFIG_SECURITY_APPARMOR: enabled
- CONFIG_EXT4_FS: enabled
- CONFIG_EXT4_FS_POSIX_ACL: enabled
- CONFIG_EXT4_FS_SECURITY: enabled
- Network Drivers:
  - "overlay":
    - CONFIG_VXLAN: enabled
    - CONFIG_BRIDGE_VLAN_FILTERING: enabled
      Optional (for encrypted networks):
      - CONFIG_CRYPTO: enabled
      - CONFIG_CRYPTO_AEAD: enabled
      - CONFIG_CRYPTO_GCM: enabled
      - CONFIG_CRYPTO_SEQIV: enabled
      - CONFIG_CRYPTO_GHASH: enabled
      - CONFIG_XFRM: enabled
      - CONFIG_XFRM_USER: enabled
      - CONFIG_XFRM_ALGO: enabled
      - CONFIG_INET_ESP: enabled
      - CONFIG_NETFILTER_XT_MATCH_BPF: enabled
  - "ipvlan":
    - CONFIG_IPVLAN: enabled
  - "macvlan":
    - CONFIG_MACVLAN: enabled
    - CONFIG_DUMMY: enabled
  - "ftp,tftp client in container":
    - CONFIG_NF_NAT_FTP: enabled
    - CONFIG_NF_CONNTRACK_FTP: enabled
    - CONFIG_NF_NAT_TFTP: enabled
    - CONFIG_NF_CONNTRACK_TFTP: enabled
- Storage Drivers:
  - "btrfs":
    - CONFIG_BTRFS_FS: enabled
    - CONFIG_BTRFS_FS_POSIX_ACL: enabled
  - "overlay":
    - CONFIG_OVERLAY_FS: enabled
  - "zfs":
    - /dev/zfs: missing
    - zfs command: missing
    - zpool command: missing

Limits:
- /proc/sys/kernel/keys/root_maxkeys: 1000000

```

cgroup.controllers 中确实只有这些：
```
> cat /sys/fs/cgroup/cgroup.controllers 
hugetlb pids
```

原因是 Android 自己已经挂载了cgroupfs v1：
```
> mount | grep cgroup
none on /dev/blkio type cgroup (rw,nosuid,nodev,noexec,relatime,blkio)
none on /sys/fs/cgroup type cgroup2 (rw,nosuid,nodev,noexec,relatime,memory_recursiveprot)
none on /dev/cpuctl type cgroup (rw,nosuid,nodev,noexec,relatime,cpu)
none on /dev/cpuset type cgroup (rw,nosuid,nodev,noexec,relatime,cpuset,noprefix,release_agent=/sbin/cpuset_release_agent)
none on /dev/memcg type cgroup (rw,nosuid,nodev,noexec,relatime,memory)
```
v1 中已经挂载的 controllers，在 v2 中就不可用([来源](https://man7.org/linux/man-pages/man7/cgroups.7.html#CGROUPS_VERSION_2))
> it is not possible to mount the same controller simultaneously under both the v1 and the v2 hierarchies.


### cgroupfs v1 cpuset.cpus 错误

切换到 cgroupfs v1 以后，出现如下错误：
```
# docker run --rm hello-world
docker: Error response from daemon: failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: unable to apply cgroup configuration: openat2 /sys/fs/cgroup/cpuset/docker/cpuset.cpus: no such file or directory: unknown.
```

这是因为 Android 已经挂载了 cpuset ，并且使用了 noprefix 标志，导致了 `/sys/fs/cgroup/cpuset/docker/cpuset.cpus` 不存在，而是存在 `/sys/fs/cgroup/cpuset/docker/cpus`。

dockerd（runc）目前好像还不能使用 noprefix 的 cpuset，临时方案可以 `umount /sys/fs/cgroup/cpuset` 禁用此功能。

更好的方案是：修改内核，让 cpuset 以 noprefix 挂载时，依然提供 `cpuset.cpus`，使其软链接到 `cpus`，或者反过来。

```patch
diff --git a/kernel/cgroup/cgroup.c b/kernel/cgroup/cgroup.c
index 684c16849..e45ce45cf 100644
--- a/kernel/cgroup/cgroup.c
+++ b/kernel/cgroup/cgroup.c
@@ -3949,6 +3949,12 @@ static int cgroup_add_file(struct cgroup_subsys_state *css, struct cgroup *cgrp,
 		spin_unlock_irq(&cgroup_file_kn_lock);
 	}
 
+	if (cft->ss && !(cft->flags & CFTYPE_NO_PREFIX) &&
+	    (cgrp->root->flags & CGRP_ROOT_NOPREFIX)) {
+		snprintf(name, CGROUP_FILE_NAME_MAX, "cpuset.%s", cft->name);
+		kernfs_create_link(cgrp->kn, name, kn);
+	}
+
 	return 0;
 }
 
```

