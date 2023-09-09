#!/bin/bash

# Copyright 2023 Henry Mai
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

# https://github.com/henrymai/container_env/blob/master/find_self.sh

# The general idea here is to run a command that is unique to your
# container env instance and then just find the container that it is in

# While you are inside of a container env, run sleep with a unique number.
UNIQUE_CMD="sleep $(( (RANDOM%1000) + 53381 ))"

# Run the command
$UNIQUE_CMD &

# Capture the pid of the command that we just ran
UNIQUE_CMD_PID="$!"

# Clean up the unique command that gets run upon exit:
trap "kill -1 $UNIQUE_CMD_PID" EXIT

# Then find the unique command that we just ran:
docker ps  --format "{{.Names}}" |
    xargs -I{} bash -c "docker top {} | grep -q \"\s$UNIQUE_CMD\" && echo Container name: {}"
