#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
  echo "Usage: $0 <sync|clear> [target_repo]" >&2
  echo "  sync   - sync commands and rules to target repo" >&2
  echo "  clear  - remove synced commands and rules from target repo" >&2
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

CMD="$1"
TARGET_REPO="${2:-$HOME/go/src/github.com/cockroachdb/cockroach}"

case "$CMD" in
  sync|clear) ;;
  *) usage ;;
esac

if [ ! -d "$TARGET_REPO" ]; then
  echo "Error: target repo does not exist: $TARGET_REPO" >&2
  exit 1
fi

# Process a source/dest directory pair
# For sync: delete orphans, then copy
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

  # Prompt if there are files to delete
  if [ -n "$to_delete" ]; then
    echo "[$src_dir] The following files will be deleted:"
    echo "$to_delete" | sed 's|^\./|  |'
    printf "Proceed? [y/N] "
    read confirm
    case "$confirm" in
      [Yy]) ;;
      *) echo "Aborted."; exit 1 ;;
    esac
  fi

  # Delete
  find "$dest_dir" -mindepth 1 -delete 2>/dev/null || true

  # Copy (sync only)
  if [ "$CMD" = "sync" ] && [ -n "$(ls -A "$SCRIPT_DIR/$src_dir" 2>/dev/null)" ]; then
    cp -r "$SCRIPT_DIR/$src_dir"/* "$dest_dir/"
  fi

  if [ "$CMD" = "sync" ]; then
    echo "Synced $src_dir to $dest_dir"
  else
    echo "Cleared $dest_dir"
  fi
}

process_dir "kv-commands" "$TARGET_REPO/.cursor/commands/kv"
process_dir "kv-rules" "$TARGET_REPO/.cursor/rules/kv"
