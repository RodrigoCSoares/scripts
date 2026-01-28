#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Daily Updates
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🔄
# @raycast.packageName Daily Updates

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/build/erlang-shipment/entrypoint.sh" run
