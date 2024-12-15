#!/bin/bash

# Change directory to the original host PWD
cd "$HOST_PWD"

# Uncomment for debugging
# printf "[%s]\n" "$@"

exec "$@"
