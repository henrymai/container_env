#!/bin/bash

# Example usage
# IMAGE=pytorch_environment:latest ./env.sh bash

: "${IMAGE:?Need to set image}"

PWD=`pwd`

# Mount this empty directory to mask over the host .local so that the container doesn't pick up
# the host's python libs
mkdir -p $HOME/empty_local

# podman specific notes:
#
# Setting the environment variable `PODMAN_USERNS="keep-id"` will cause `podman run` to have this argument: `--userns=keep-id`
#
# `--userns=keep-id` is necessary for `podman` to act like the original user correctly.
#
# `--userns=keep-id` won't work with `docker` and isn't actually necessary for `docker`, the `PODMAN_USERNS` environment variable
#  will just be ignored by `docker`.
#
# `-v /dev/shm:/dev/shm` breaks for podman once `--userns=keep-id` is used.
#     I was originally mounting the /dev/shm inside mostly to have the same memory limit as the host, but
#     I can also just set the container /dev/shm to be unlimited instead as another solution.

export PODMAN_USERNS="keep-id"

podman run --rm -ti \
  --net=host \
  -u `id -u`:`id -g` \
  `id -G | sed 's/\s\?\([0-9]*\)/--group-add \1 /g'` \
  -v /etc/passwd:/etc/passwd:ro \
  -v /etc/group:/etc/group:ro \
  --shm-size=0 \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -e DISPLAY=$DISPLAY \
  -v $HOME:$HOME \
  -v $HOME/empty_local:$HOME/.local \
  $IMAGE \
  bash -c "cd $PWD; $*"
