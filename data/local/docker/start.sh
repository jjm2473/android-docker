#!/bin/sh

. /data/local/docker/docker.env

[ -d "$HOME" ] || mkdir "$HOME"
[ -d "$DOCKER_ROOT/var" ] || mkdir "$DOCKER_ROOT/var"

mountpoint -q "$DOCKER_ROOT/var" || mount -t tmpfs -o size=4M,uid=0,gid=0,mode=0755 tmpfs "$DOCKER_ROOT/var"

mkdir -p "$DOCKER_ROOT/var/run"

unshare -m "$DOCKER_ROOT/scripts/exec_dockerd.sh"
