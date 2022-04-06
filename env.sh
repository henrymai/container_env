#!/bin/bash

# Example usage
# IMAGE=pytorch_environment:latest ./env.sh bash

: "${IMAGE:?Need to set image}"

PWD=`pwd`

# Mount this empty directory to mask over the host .local so that the container doesn't pick up
# the host's python libs
mkdir -p $HOME/empty_local

podman run --rm -ti \
  --net=host \
  -u `id -u`:`id -g` \
  --group-add `id -G | sed 's/ / --group-add /g'` \
  -v /etc/passwd:/etc/passwd:ro \
  -v /etc/group:/etc/group:ro \
  -v /dev/shm:/dev/shm \
  -v /run/shm:/run/shm \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -e DISPLAY=$DISPLAY \
  -v $HOME:$HOME \
  -v $HOME/empty_local:$HOME/.local \
  $IMAGE \
  bash -c "cd $PWD; $*"
