#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
  echo "Usage: $0 <sync|clear|add-hook|del-hook>" >&2
  echo "  sync      - copy skills, agents, and rules into ~/.claude/ and ~/.cursor/" >&2
  echo "  clear     - remove synced items from ~/.claude/ and ~/.cursor/" >&2
  echo "  add-hook  - install git post-merge hook to auto-sync on pull" >&2
  echo "  del-hook  - remove git post-merge hook" >&2
  echo "" >&2
  echo "Flattens {skills,agents,rules}/<team>/<name> to ~/.<target>/<category>/<team>.<name>" >&2
  echo "where <target> is both 'claude' and 'cursor'." >&2
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

CMD="$1"

# Handle add-hook/del-hook before validation
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

# Sync or clear a single team within a category.
#
# Source layout:  <category>/<team>/<name>  (file or dir)
# Dest layout:    <dest_base>/<category>/<team>.<name>
#
# On sync: removes orphans, then copies each entry.
# On clear: removes all <team>.* entries from the dest category dir.
sync_team() {
  category="$1"
  team="$2"
  dest_base="$3"
  src_dir="$SCRIPT_DIR/$category/$team"
  dest_dir="$dest_base/$category"

  if [ "$CMD" = "clear" ]; then
    for item in "$dest_dir/$team".*; do
      [ -e "$item" ] || continue
      rm -rf "$item"
      echo "Removed $(basename "$item")"
    done
    return 0
  fi

  # sync
  if [ ! -d "$src_dir" ]; then
    echo "Warning: source $src_dir does not exist, skipping" >&2
    return 0
  fi

  mkdir -p "$dest_dir"

  # Remove orphans: dest entries whose source no longer exists.
  for item in "$dest_dir/$team".*; do
    [ -e "$item" ] || continue
    src_name="$(basename "$item")"
    src_name="${src_name#"$team".}"  # strip <team>. prefix
    if [ ! -e "$src_dir/$src_name" ]; then
      rm -rf "$item"
      echo "Removed orphan $(basename "$item")"
    fi
  done

  # Copy each entry with the <team>.<name> convention.
  for item in "$src_dir"/*; do
    [ -e "$item" ] || continue
    name="$(basename "$item")"
    dest="$dest_dir/$team.$name"
    rm -rf "$dest"
    cp -r "$item" "$dest"
    echo "$category/$team.$name"
  done
}

# Discover and process all team dirs under each category,
# syncing to both ~/.claude and ~/.cursor.
for dest_base in "$HOME/.claude" "$HOME/.cursor"; do
  target="$(basename "$dest_base")"
  for category in skills agents rules; do
    [ -d "$SCRIPT_DIR/$category" ] || continue
    for team_dir in "$SCRIPT_DIR/$category"/*/; do
      [ -d "$team_dir" ] || continue
      team="$(basename "$team_dir")"
      sync_team "$category" "$team" "$dest_base"
    done
  done
  echo "--- ${CMD}ed $target ---"
done
