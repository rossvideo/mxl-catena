#!/usr/bin/env bash
set -euo pipefail

# Load target server IP from opentofu/target_server.auto.tfvars, allowing optional spaces.
TARGET_SERVER_IP=$(sed -n 's/^[[:space:]]*target_ip[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' opentofu/target_server.auto.tfvars | head -n1)

if [[ -z "$TARGET_SERVER_IP" ]]; then
  echo "Error: could not parse target_ip from opentofu/target_server.auto.tfvars" >&2
  exit 1
fi

TARGET_SERVER="ansible@$TARGET_SERVER_IP"
TARGET_DIR="/workspace"
SSH_KEY="$HOME/IAC/.ssh/id_ed25519"

if [[ ! -f "$SSH_KEY" ]]; then
  echo "Error: SSH key not found at $SSH_KEY" >&2
  exit 1
fi

# Make sure target dir exists.
ssh -i "$SSH_KEY" "$TARGET_SERVER" "sudo mkdir -p $TARGET_DIR && sudo chown ansible:ansible $TARGET_DIR"

# Flag to track if images were uploaded
IMAGES_UPLOADED=0

# Things to upload - use rsync with checksum to only sync changed files.
echo "Uploading external directory to $TARGET_SERVER:$TARGET_DIR (if changed)..."
rsync -av --checksum -e "ssh -i $SSH_KEY" external/ "$TARGET_SERVER:$TARGET_DIR/external/" || true

echo "Uploading images to $TARGET_SERVER:$TARGET_DIR (if changed)..."
RSYNC_OUTPUT=$(rsync -av --checksum -e "ssh -i $SSH_KEY" images/ "$TARGET_SERVER:$TARGET_DIR/images/" 2>&1 || true)
echo "$RSYNC_OUTPUT"
# Check if any image files were actually transferred
if echo "$RSYNC_OUTPUT" | grep -E "\.tar|\.tgz" | grep -qv "^total\|^sent\|^received"; then
  IMAGES_UPLOADED=1
fi

echo "Uploading import script to $TARGET_SERVER:$TARGET_DIR (if changed)..."
rsync -av --checksum -e "ssh -i $SSH_KEY" import_multivewer.sh "$TARGET_SERVER:$TARGET_DIR/" || true

echo "Uploading metrics to $TARGET_SERVER:$TARGET_DIR (if changed)..."
rsync -av --checksum -e "ssh -i $SSH_KEY" metrics/ "$TARGET_SERVER:$TARGET_DIR/metrics/" || true

# Run import script only if images were uploaded.
if [[ $IMAGES_UPLOADED -eq 1 ]]; then
  echo "Running import script on target server..."
  ssh -i "$SSH_KEY" "$TARGET_SERVER" "cd $TARGET_DIR && sudo chmod +x import_multivewer.sh && ./import_multivewer.sh"
else
  echo "No images were uploaded, skipping import script."
  echo "ssh -i \"$SSH_KEY\" \"$TARGET_SERVER\" \"cd $TARGET_DIR && sudo chmod +x import_multivewer.sh && ./import_multivewer.sh\""
fi

