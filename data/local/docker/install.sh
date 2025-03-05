#!/bin/sh

# wget https://download.docker.com/linux/static/stable/aarch64/docker-28.0.1.tgz
mkdir bin
tar -xzf docker-28.0.1.tgz --strip-components 1 -C bin

# wget https://dl-cdn.alpinelinux.org/alpine/v3.21/main/aarch64/ca-certificates-bundle-20241121-r1.apk
tar -xzf ca-certificates-bundle-20241121-r1.apk etc/ssl/certs/ca-certificates.crt
