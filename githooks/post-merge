#!/bin/sh
# Auto-sync cursorfiles after pulling master
SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
BRANCH="$(git -C "$SCRIPT_DIR" rev-parse --abbrev-ref HEAD)"
if [ "$BRANCH" = "master" ] || [ "$BRANCH" = "main" ]; then
  echo "[cursorfiles] Auto-syncing after pull..."
  "$SCRIPT_DIR/sync.sh" sync
fi
