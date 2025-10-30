# android-docker
Docker run in rooted Android

# 先决条件
1. Root Android 设备
2. 在 Android 设备执行这个脚本 https://github.com/moby/moby/blob/master/contrib/check-config.sh，确保“Generally Necessary”基本满足，“cgroup Controllers”可以不满足v2，因为我们用cgroup v1。
3. 挂载个 ext4 分区，或其他 Linux 友好的文件系统 （Android 自带的 /data 可能不行）

# 部署
1. 修改 `data/local/docker/docker.env` 中的 DOCKER_DATA_ROOT 变量，指向 ext4 分区的一个文件夹（通常是`/mnt/media_rw/`开头的）
1. 电脑连接好 Android 设备（已 ROOT）
2. 电脑上执行`cd data/local/docker && ./deploy.sh`，这会将文件 push 到 Android 设备

# 启动 dockerd 服务
1. 电脑连接好 Android 设备（已 ROOT）
2. 电脑上执行`adb root; adb shell`打开 shell
3. 在 shell 中执行 `/data/local/docker/start.sh`，成功的话，程序不会结束，不要关闭这个shell。

# 运行容器
1. dockerd 服务运行的情况下，电脑上执行`adb shell`打开另一个 shell
2. shell 中执行 `/data/local/docker/docker.sh run --rm hello-world`
（`/data/local/docker/docker.sh`是docker命令的封装，可以执行任何 docker 命令）

# 问题解决
* 启动 dockerd 服务或者运行容器如果失败了，可以检查下我的[踩坑笔记](Note.md)，或许能找到解决方案
