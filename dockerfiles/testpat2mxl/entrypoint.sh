#!/usr/bin/env sh
set -eu

FLOW_FILE="/mxl/app/v210_flow.json"

if [ -n "${FLOW:-}" ]; then
  echo "FLOW provided; updating flow id to: $FLOW"
  /usr/bin/python3 /usr/local/bin/update_flow_id.py --file "$FLOW_FILE" --id "$FLOW"
else
  echo "FLOW not set; generating a new UUID for flow."
  /usr/bin/python3 /usr/local/bin/update_flow_id.py --file "$FLOW_FILE"
fi

exec /mxl/app/mxl-gst-videotestsrc "$@" -v "$FLOW_FILE"
