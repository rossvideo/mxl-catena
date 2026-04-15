#!/usr/bin/env bash
set -euo pipefail

# Load target server IP from opentofu/target_server.auto.tfvars, allowing optional spaces.
TARGET_SERVER_IP=$(sed -n 's/^[[:space:]]*target_ip[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' opentofu/target_server.auto.tfvars | head -n1)
TARGET_SERVER_URL=$(sed -n 's/^[[:space:]]*base_domain[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' opentofu/target_server.auto.tfvars | head -n1 )

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

# Common rsync options:
# - itemize-changes: machine-readable changed-file lines for detection logic
# - info=progress2: overall transfer progress in real time
RSYNC_OPTS=(-av --checksum --itemize-changes --human-readable --info=progress2)

# Things to upload - use rsync with checksum to only sync changed files.
echo "Uploading external directory to $TARGET_SERVER:$TARGET_DIR (if changed)..."
rsync "${RSYNC_OPTS[@]}" -e "ssh -i $SSH_KEY" external/ "$TARGET_SERVER:$TARGET_DIR/external/" || true

echo "Uploading images to $TARGET_SERVER:$TARGET_DIR (if changed)..."
IMG_RSYNC_LOG=$(mktemp)
rsync "${RSYNC_OPTS[@]}" -e "ssh -i $SSH_KEY" images/ "$TARGET_SERVER:$TARGET_DIR/images/" 2>&1 | tee "$IMG_RSYNC_LOG" || true
# Check if any image files were actually transferred
if grep -E '^>f' "$IMG_RSYNC_LOG" | grep -Eq '\.(tar|tgz)$'; then
  IMAGES_UPLOADED=1
fi
rm -f "$IMG_RSYNC_LOG"

echo "Uploading import script to $TARGET_SERVER:$TARGET_DIR (if changed)..."
rsync "${RSYNC_OPTS[@]}" -e "ssh -i $SSH_KEY" import_multivewer.sh "$TARGET_SERVER:$TARGET_DIR/" || true

echo "Uploading metrics to $TARGET_SERVER:$TARGET_DIR (if changed)..."
rsync "${RSYNC_OPTS[@]}" -e "ssh -i $SSH_KEY" metrics/ "$TARGET_SERVER:$TARGET_DIR/metrics/" || true



echo "easy commands to run on target server:"
echo "ssh -i \"$SSH_KEY\" \"$TARGET_SERVER\" \"cd $TARGET_DIR && sudo chmod +x import_multivewer.sh && ./import_multivewer.sh\""
echo "ssh -i \"$SSH_KEY\" \"$TARGET_SERVER\" \"cd $TARGET_DIR/external/certs && sudo chmod +x certbot.sh && ./certbot.sh -f *.$TARGET_SERVER_URL\""


