#!/bin/sh
# Auto-sync cursorfiles before pushing master
SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

while read local_ref local_sha remote_ref remote_sha; do
  if [ "$local_ref" = "refs/heads/master" ] || [ "$local_ref" = "refs/heads/main" ]; then
    echo "[cursorfiles] Auto-syncing before push..."
    "$SCRIPT_DIR/sync.sh" sync
    break
  fi
done
