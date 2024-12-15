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

# https://github.com/henrymai/container_env/blob/master/env.sh

# Wrapper script that detects the OS and calls the appropriate script:
#   - linux.env.sh for Linux
#   - mac.env.sh for macOS

# Example usage
# IMAGE=pytorch_environment:latest /path/to/container_env/env.sh bash

OS=$(uname)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$OS" = "Darwin" ]; then
  # macOS
  exec "$SCRIPT_DIR/mac.env.sh" "$@"
else
  # Linux (default)
  exec "$SCRIPT_DIR/linux.env.sh" "$@"
fi
