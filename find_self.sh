#!/bin/bash

# The general idea here is to run a command that is unique to your
# container env instance and then just find the container that it is in

# While you are inside of a container env, run sleep with a unique number.
# It can be any number, just has to be unique.
UNIQUE_CMD="sleep 53381"

# Run the command
$UNIQUE_CMD &

# Capture the pid of the command that we just ran
UNIQUE_CMD_PID="$!"

# Then find the unique command that we just ran:
docker ps  --format "{{.Names}}" |
    xargs -I{} bash -c "docker top {} | grep -q \"\s$UNIQUE_CMD\" && echo Container name: {}"

# Then clean up the unique command that was run:
kill -1 $UNIQUE_CMD_PID
