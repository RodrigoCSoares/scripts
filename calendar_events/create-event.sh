#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Create Quick Event
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 📅
# @raycast.packageName Calendar Events
# @raycast.argument1 { "type": "text", "placeholder": "e.g. Lunch with Sarah tomorrow at noon" }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/build/erlang-shipment/entrypoint.sh" run "$1"
