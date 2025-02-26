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
