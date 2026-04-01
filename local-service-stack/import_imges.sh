#!/usr/bin/env bash
set -euo pipefail

echo "Importing images into local registry..."
for image in $(find images -type f -name "*.t*"); do
  echo "Importing $image..."
  docker load -i "$image"
done
echo "All images imported successfully."
