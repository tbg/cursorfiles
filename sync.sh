#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
  echo "Usage: $0 <sync|clear|add-hook|del-hook>" >&2
  echo "  sync      - sync commands and rules to target repo" >&2
  echo "  clear     - remove synced commands and rules from target repo" >&2
  echo "  add-hook  - install git post-merge hook to auto-sync on pull" >&2
  echo "  del-hook  - remove git post-merge hook" >&2
  echo "" >&2
  echo "Target repo: git config cursorfiles.target (default: ~/go/src/github.com/cockroachdb/cockroach)" >&2
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

CMD="$1"
DEFAULT_TARGET="$HOME/go/src/github.com/cockroachdb/cockroach"
TARGET_REPO="$(git -C "$SCRIPT_DIR" config --get cursorfiles.target 2>/dev/null || echo "$DEFAULT_TARGET")"

# Handle add-hook/del-hook before target repo validation
if [ "$CMD" = "add-hook" ]; then
  HOOK_FILE="$SCRIPT_DIR/.git/hooks/post-merge"
  mkdir -p "$SCRIPT_DIR/.git/hooks"
  cp "$SCRIPT_DIR/githooks/post-merge.sh" "$HOOK_FILE"
  chmod +x "$HOOK_FILE"
  echo "Installed post-merge hook at $HOOK_FILE"
  exit 0
fi

if [ "$CMD" = "del-hook" ]; then
  HOOK_FILE="$SCRIPT_DIR/.git/hooks/post-merge"
  if [ -f "$HOOK_FILE" ]; then
    rm "$HOOK_FILE"
    echo "Removed post-merge hook at $HOOK_FILE"
  else
    echo "No post-merge hook found at $HOOK_FILE"
  fi
  exit 0
fi

case "$CMD" in
  sync|clear) ;;
  *) usage ;;
esac

if [ ! -d "$TARGET_REPO" ]; then
  echo "Error: target repo does not exist: $TARGET_REPO" >&2
  exit 1
fi

# Process a source/dest directory pair
# For sync: delete orphans, then symlink
# For clear: delete everything
process_dir() {
  src_dir="$1"
  dest_dir="$2"

  if [ ! -d "$dest_dir" ]; then
    if [ "$CMD" = "sync" ] && [ -d "$SCRIPT_DIR/$src_dir" ]; then
      mkdir -p "$dest_dir"
    else
      return 0
    fi
  fi

  # Find files to delete
  if [ "$CMD" = "sync" ]; then
    # Orphans: files in dest but not in source
    src_files=$(cd "$SCRIPT_DIR/$src_dir" && find . -type f 2>/dev/null | sort)
    dest_files=$(cd "$dest_dir" && find . -type f 2>/dev/null | sort)
    tmp_src=$(mktemp)
    tmp_dest=$(mktemp)
    echo "$src_files" > "$tmp_src"
    echo "$dest_files" > "$tmp_dest"
    to_delete=$(comm -23 "$tmp_dest" "$tmp_src")
    rm -f "$tmp_src" "$tmp_dest"
  else
    # Clear: all files in dest
    to_delete=$(cd "$dest_dir" && find . -type f 2>/dev/null | sort)
  fi

  # Log files being deleted
  if [ -n "$to_delete" ]; then
    echo "[$src_dir] Deleting orphaned files:"
    echo "$to_delete" | sed 's|^\./|  |'
  fi

  # Delete
  find "$dest_dir" -mindepth 1 -delete 2>/dev/null || true

  # Create symlinks (sync only)
  if [ "$CMD" = "sync" ] && [ -n "$(ls -A "$SCRIPT_DIR/$src_dir" 2>/dev/null)" ]; then
    (cd "$SCRIPT_DIR/$src_dir" && find . -type f) | while read -r file; do
      file="${file#./}"
      src_file="$SCRIPT_DIR/$src_dir/$file"
      dest_file="$dest_dir/$file"
      mkdir -p "$(dirname "$dest_file")"
      ln -s "$src_file" "$dest_file"
    done
  fi

  if [ "$CMD" = "sync" ]; then
    echo "Symlinked $src_dir to $dest_dir"
  else
    echo "Cleared $dest_dir"
  fi
}

process_dir "kv-commands" "$TARGET_REPO/.cursor/commands/kv"
process_dir "kv-rules" "$TARGET_REPO/.cursor/rules/kv"
