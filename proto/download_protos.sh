#!/usr/bin/env bash

set -euo pipefail

echo "Downloading files from SMPTE/st2138-a/interface/proto (branch main)"

# Fetch directory listing from GitHub API
API_URL="https://api.github.com/repos/SMPTE/st2138-a/contents/interface/proto?ref=main"

# Get all file download URLs
urls=$(curl -s "$API_URL" \
    | grep '"download_url":' \
    | sed -E 's/ *"download_url": "([^"]+)".*/\1/')

if [[ -z "$urls" ]]; then
    echo "No files found or path not valid."
    exit 1
fi

# Download each file
for url in $urls; do
    fname=$(basename "$url")
    echo " → $fname"
    curl -s -L "$url" -o "./$fname"
done

echo "Done!"
ls -la