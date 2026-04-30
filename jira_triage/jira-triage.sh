#!/bin/bash
SECRETS_FILE="$HOME/.secrets"
[[ -f "$SECRETS_FILE" ]] || { echo "error: secrets file not found: $SECRETS_FILE" >&2; exit 1; }
# shellcheck source=/dev/null
source "$SECRETS_FILE"

PERIOD=$(printf 'Last day\nLast week\nLast two weeks' | fzf --prompt='Time period: ' --height=6 --border)
[[ -z "$PERIOD" ]] && exit 0

case "$PERIOD" in
  "Last day")       export JIRA_TRIAGE_PERIOD="1d" ;;
  "Last week")      export JIRA_TRIAGE_PERIOD="1w" ;;
  "Last two weeks") export JIRA_TRIAGE_PERIOD="2w" ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
"$SCRIPT_DIR/build/erlang-shipment/entrypoint.sh" run
