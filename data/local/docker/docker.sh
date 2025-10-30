#!/bin/sh

. /data/local/docker/docker.env

exec $DOCKER_ROOT/bin/docker "$@"
