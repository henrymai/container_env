#!/bin/bash

# Example usage
# IMAGE=pytorch_environment:latest ./env.sh bash

: "${IMAGE:?Need to set image}"

ABS_HOME=$(readlink -f $HOME)
PWD=`pwd`


# Use the image name as a prefix for any directories we want to offset and isolate from
# the host home directory convert :whatever to /whatever
PREFIX=`echo $IMAGE | sed 's#:#/#'`
# Mount these offset directory to mask over a variety of common package directories
# that reside on the host such as: .local, .m2, <add any others here>.
PYTHON_LOCAL=$HOME/container_env/$PREFIX/.local
MAVEN_CACHE=$HOME/container_env/$PREFIX/.m2
mkdir -p $PYTHON_LOCAL
mkdir -p $MAVEN_CACHE
PACKAGE_DIRS="\
  -v $PYTHON_LOCAL:$HOME/.local \
  -v $MAVEN_CACHE:$HOME/.m2 \
"


# Note that this section only applies to docker and won't do anything if the script
# does not detect docker (this assumes that you have not aliased podman to docker).
#
# Grab a copy of the dind docker binary if we don't already have it.
# For some reason the dind docker binary doesn't have glibc dependency issues
# that I was getting when using the local docker binary.
SCRIPT_DIR=$(dirname $(readlink -f $0))
ls $SCRIPT_DIR/docker &> /dev/null || (which docker && (
docker pull docker:dind
docker run -v $SCRIPT_DIR:/tmp --rm --entrypoint cp docker:dind /usr/local/bin/docker /tmp/docker
))
# Mount these inside the container so that we can spin up docker containers while
# inside the container.
DIND_MOUNTS="\
  `ls /var/run/docker.sock | xargs -I{} echo '-v {}:{}'` \
  `(ls $SCRIPT_DIR/docker &> /dev/null) && (readlink -f $SCRIPT_DIR/docker | xargs -I{} echo '-v {}:/usr/bin/docker')` \
"


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


DOCKER=$(which podman 2> /dev/null || which docker 2> /dev/null)

$DOCKER run --rm -ti \
  --gpus=all \
  --net=host \
  -u `id -u`:`id -g` \
  `id -G | sed 's/\s\?\([0-9]*\)/--group-add \1 /g'` \
  -v /etc/passwd:/etc/passwd:ro \
  -v /etc/group:/etc/group:ro \
  --shm-size=0 \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -e DISPLAY=$DISPLAY \
  $PACKAGE_DIRS \
  $DIND_MOUNTS \
  -v $ABS_HOME:$ABS_HOME \
  -v $HOME:$HOME \
  --entrypoint=bash \
  $IMAGE \
  -c "cd $PWD; $*"
