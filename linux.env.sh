#!/bin/bash

# Copyright 2024 Henry Mai
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# https://github.com/henrymai/container_env/blob/master/linux.env.sh


set -e

: "${IMAGE:?Need to set image}"

ABS_HOME=$(readlink -f $HOME)
HOST_PWD=`pwd`


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
ls $SCRIPT_DIR/docker &> /dev/null && ls $SCRIPT_DIR/docker-compose &> /dev/null || (which docker && (
docker pull docker:dind
docker run -v $SCRIPT_DIR:/tmp --rm --entrypoint cp docker:dind /usr/local/bin/docker /tmp/docker
docker run -v $SCRIPT_DIR:/tmp --rm --entrypoint cp docker:dind /usr/local/libexec/docker/cli-plugins/docker-compose /tmp/docker-compose
))
# Mount these inside the container so that we can spin up docker containers while
# inside the container.
DIND_MOUNTS="\
  `ls /var/run/docker.sock | xargs -I{} echo '-v {}:{}'` \
  `(ls $SCRIPT_DIR/docker &> /dev/null) && (readlink -f $SCRIPT_DIR/docker | xargs -I{} echo '-v {}:/usr/bin/docker')` \
  `(ls $SCRIPT_DIR/docker-compose &> /dev/null) && (readlink -f $SCRIPT_DIR/docker-compose | xargs -I{} echo '-v {}:/usr/libexec/docker/cli-plugins/docker-compose')` \
"

# Just attempt to run the hello-world image with --gpus=all to see if it works and only use the flag if it does work
GPUS_FLAG=$(docker run --gpus=all --rm hello-world &> /dev/null && echo '--gpus=all' || echo '')

# Get the `which` binary to pass through to the container since not all images will have `which` installed.
WHICH_BINARY=$(which which)

# Only set TTY_FLAGS if not already defined by the user.
if [ -z "${TTY_FLAGS+x}" ]; then
  if [ -t 1 ]; then
    TTY_FLAGS="-ti"
  else
    TTY_FLAGS=""
  fi
fi

REMAP_PROFILE_MOUNTS="$(ls $HOME/.profile | xargs -I{} echo '-v {}:/tmp/container_env_runtime/user_profile')"

docker run --rm \
  $TTY_FLAGS \
  $EXTRA_DOCKER_FLAGS \
  $GPUS_FLAG \
  --net=host \
  -u `id -u`:`id -g` \
  `id -G | sed 's/\s\?\([0-9]*\)/--group-add \1 /g'` \
  -v /etc/passwd:/etc/passwd:ro \
  -v /etc/group:/etc/group:ro \
  --shm-size=0 \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -e DISPLAY=$DISPLAY \
  $REMAP_PROFILE_MOUNTS \
  -e HOST_PWD=$HOST_PWD \
  -e HOME=$HOME \
  -v $SCRIPT_DIR/container_env_profile:$HOME/.profile \
  -v $SCRIPT_DIR:/tmp/container_env \
  -v $WHICH_BINARY:$WHICH_BINARY \
  $PACKAGE_DIRS \
  $DIND_MOUNTS \
  -v $ABS_HOME:$ABS_HOME \
  -v $HOME:$HOME \
  --entrypoint=bash \
  $IMAGE \
  --login /tmp/container_env/startup.sh "$@"
