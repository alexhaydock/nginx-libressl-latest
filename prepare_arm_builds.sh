#!/bin/sh

# Since the Pi / ARM builds of this container do not require any
# special action, just copy the regular Dockerfile and change the
# FROM field to the correct version of Alpine.

cp -fv ./Dockerfile ./Dockerfile.arm32v6
cp -fv ./Dockerfile ./Dockerfile.arm64v8

sed -i 's,alpine:3.8,arm32v6/alpine:3.8,g' Dockerfile.arm32v6
sed -i 's,alpine:3.8,arm64v8/alpine:3.8,g' Dockerfile.arm64v8
