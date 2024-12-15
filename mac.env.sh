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

# macOS version written by ChatGPT-o1

# https://github.com/henrymai/container_env/blob/master/mac.env.sh

set -e

: "${IMAGE:?Need to set image}"

echo "Note: You are running on macOS."
echo
echo "Networking:"
echo "  - '--net=host' is not supported by Docker Desktop on macOS."
echo "  - To access a server running inside this container environment from your host machine,"
echo "    you must publish ports. For example:"
echo "      EXTRA_DOCKER_FLAGS='-p 8080:8080' IMAGE=$IMAGE ./$(basename $0)"
echo "    Then connect to 'localhost:8080' on your Mac to reach the service."
echo
echo "GUI Applications:"
echo "  - To run GUI applications, you need an X11 server on macOS (XQuartz)."
echo "    1. Install and start XQuartz: 'brew install xquartz' and then 'open -a XQuartz'."
echo "    2. Allow connections from the container: 'xhost +host.docker.internal'."
echo "    3. The DISPLAY is set to 'host.docker.internal:0' in the container environment."
echo "       If DISPLAY doesn't work, ensure XQuartz is running and 'xhost +host.docker.internal' was executed."
echo


# Resolve paths without readlink -f
ABS_HOME="$(cd "$HOME" && pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PWD="$(pwd)"

# Convert image name to prefix by replacing ":" with "/"
PREFIX="${IMAGE/:/\/}"

# Setup directories for isolating host-specific directories
PYTHON_LOCAL="$HOME/container_env/$PREFIX/.local"
MAVEN_CACHE="$HOME/container_env/$PREFIX/.m2"
mkdir -p "$PYTHON_LOCAL" "$MAVEN_CACHE"

PACKAGE_DIRS="\
  -v $PYTHON_LOCAL:$HOME/.local \
  -v $MAVEN_CACHE:$HOME/.m2 \
"

if [ ! -f "$SCRIPT_DIR/docker" ] || [ ! -f "$SCRIPT_DIR/docker-compose" ]; then
  which docker > /dev/null
  docker pull docker:dind
  docker run -v "$SCRIPT_DIR":/tmp --rm --entrypoint cp docker:dind /usr/local/bin/docker /tmp/docker
  docker run -v "$SCRIPT_DIR":/tmp --rm --entrypoint cp docker:dind /usr/local/libexec/docker/cli-plugins/docker-compose /tmp/docker-compose
fi

if [ ! -f "$SCRIPT_DIR/which" ]; then
  # Pull a minimal image and extract 'which'
  docker pull alpine:latest
  docker run --rm -v "$SCRIPT_DIR":/tmp alpine:latest sh -c "apk add --no-cache which && cp /usr/bin/which /tmp/which"
fi

# Mount docker socket and the just-copied docker binaries
DIND_MOUNTS="\
  `ls /var/run/docker.sock &> /dev/null && echo "-v /var/run/docker.sock:/var/run/docker.sock"` \
  `test -f "$SCRIPT_DIR/docker" && echo "-v $(cd "$SCRIPT_DIR" && pwd)/docker:/usr/bin/docker"` \
  `test -f "$SCRIPT_DIR/docker-compose" && echo "-v $(cd "$SCRIPT_DIR" && pwd)/docker-compose:/usr/libexec/docker/cli-plugins/docker-compose"` \
"

# Use the Linux 'which' binary we extracted
WHICH_BINARY="$SCRIPT_DIR/which"

# Only set TTY_FLAGS if not already defined by the user.
if [ -z "${TTY_FLAGS+x}" ]; then
  if [ -t 1 ]; then
    TTY_FLAGS="-ti"
  else
    TTY_FLAGS=""
  fi
fi

# Set DISPLAY for macOS via host.docker.internal
DISPLAY="host.docker.internal:0"

docker run --rm \
  $TTY_FLAGS \
  $EXTRA_DOCKER_FLAGS \
  -u "$(id -u)":"$(id -g)" \
  $(id -G | sed 's/[[:space:]]*\([0-9]*\)/--group-add \1 /g') \
  -v /etc/passwd:/etc/passwd:ro \
  -v /etc/group:/etc/group:ro \
  --shm-size=0 \
  -e DISPLAY=$DISPLAY \
  -e HOME=$HOME \
  -v "$WHICH_BINARY":/usr/bin/which \
  $PACKAGE_DIRS \
  $DIND_MOUNTS \
  -v "$ABS_HOME":"$ABS_HOME" \
  -v "$HOME":"$HOME" \
  --entrypoint=bash \
  "$IMAGE" \
  -c "cd $PWD; $*"
