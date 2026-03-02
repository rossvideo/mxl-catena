#!/usr/bin/env bash
set -eoa pipefail
cd "$(dirname "$0")"

# Check if images directory exists
if [ ! -d "images" ]; then
    echo "Error: images/ directory not found" >&2
    echo "Please extract the tarball first: tar -xzf mxl-mv-demo.tar.gz" >&2
    echo "Then run this script inside the created directory" >&2
    exit 1
fi

echo "Loading Docker images..."
printf '%s\n' \
  "images/mxl_tools.tar" \
  "images/mxl_input.tar" \
  "images/mxl_output.tar" \
  "images/multiviewer.tar" \
  "images/control.tar" \
  "images/cheetah-lite.tar" \
  | xargs -P 6 -n 1 sh -c 'docker load -i "$1"' sh || { echo "One or more docker load commands failed."; exit 1; }

wait

echo "Import Done"
