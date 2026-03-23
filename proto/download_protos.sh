#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$SCRIPT_DIR"

echo "Downloading files from SMPTE/st2138-a/interface/proto (branch main)"

# Fetch directory listing from GitHub API
API_URL="https://api.github.com/repos/SMPTE/st2138-a/contents/interface/proto?ref=main"

# Get all .proto file download URLs
urls=$(curl -fsSL "$API_URL" \
    | grep '"download_url":' \
    | sed -E 's/ *"download_url": "([^"]+)".*/\1/' \
    | grep '\.proto$' || true)

if [[ -z "$urls" ]]; then
    echo "No .proto files found or path not valid."
    exit 1
fi

mkdir -p "$TARGET_DIR"

# Download each file into the proto directory next to this script
for url in $urls; do
    fname=$(basename "$url")
    echo " -> $fname"
    curl -fsSL "$url" -o "$TARGET_DIR/$fname"
done

echo "Done!"
ls -la "$TARGET_DIR"