#!/usr/bin/env bash
set -euo pipefail

TARGET_SERVER="ansible@10.62.152.123"
TARGET_DIR="/workspace"
SSH_KEY="~/IAC/.ssh/id_ed25519"

#make sure target dir exists
ssh -i $SSH_KEY "$TARGET_SERVER" "sudo mkdir -p $TARGET_DIR && sudo chown ansible:ansible $TARGET_DIR"
# things to upload
echo "Uploading external directory to $TARGET_SERVER:$TARGET_DIR ..."
scp -r -i $SSH_KEY external "$TARGET_SERVER:$TARGET_DIR"

echo "Uploading images and import script to $TARGET_SERVER:$TARGET_DIR ..."
scp -r -i $SSH_KEY images "$TARGET_SERVER:$TARGET_DIR"
scp -i $SSH_KEY import_multivewer.sh "$TARGET_SERVER:$TARGET_DIR"

# run import script on target server
echo "Running import script on target server..."
ssh -i $SSH_KEY "$TARGET_SERVER" "cd $TARGET_DIR && sudo chmod +x import_multivewer.sh && ./import_multivewer.sh"

