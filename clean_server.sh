#!/usr/bin/env bash
set -euo pipefail

TARGET_SERVER="ansible@10.62.152.123"
TARGET_DIR="/workspace"
SSH_KEY="~/IAC/.ssh/id_ed25519"


#clean up dev/shm on target server
echo "Cleaning up /dev/shm on $TARGET_SERVER..."
ssh -i $SSH_KEY "$TARGET_SERVER" "sudo rm -rf /dev/shm/**"