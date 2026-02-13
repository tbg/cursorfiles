#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
  echo "Usage: $0 <sync|clear> [--include-optional <group>]..." >&2
  echo "  sync  - copy skills, agents, and rules into ~/.claude/ and ~/.cursor/" >&2
  echo "  clear - remove synced items from ~/.claude/ and ~/.cursor/" >&2
  echo "" >&2
  echo "Flattens {skills,agents,rules}/<team>/<name> to ~/.<target>/<category>/<team>.<name>" >&2
  echo "where <target> is both 'claude' and 'cursor'." >&2
  echo "" >&2
  echo "Optional skill groups (under skills/optional/) are skipped by default." >&2
  echo "Use --include-optional <group> to sync them (repeatable)." >&2
  echo "" >&2
  echo "Example:" >&2
  echo "  $0 sync --include-optional commit-voices" >&2
  echo "" >&2
  echo "Tip: auto-sync on pull/push by setting:" >&2
  echo "  git config core.hooksPath ./githooks" >&2
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

CMD="$1"
shift

case "$CMD" in
  sync|clear) ;;
  *) usage ;;
esac

# Parse --include-optional flags.
OPTIONAL_GROUPS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --include-optional)
      if [ $# -lt 2 ]; then
        echo "Error: --include-optional requires a group name" >&2
        exit 1
      fi
      OPTIONAL_GROUPS="$OPTIONAL_GROUPS $2"
      shift 2
      ;;
    *)
      echo "Error: unknown argument '$1'" >&2
      usage
      ;;
  esac
done

# Check if a group name is in the opted-in list.
is_opted_in() {
  group="$1"
  for g in $OPTIONAL_GROUPS; do
    if [ "$g" = "$group" ]; then
      return 0
    fi
  done
  return 1
}

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

# Sync or clear optional skill groups.
#
# Source layout:  skills/optional/<group>/<name>
# Dest layout:    <dest_base>/skills/<name>  (no prefix)
#
# On sync: only processes groups listed in OPTIONAL_GROUPS.
# On clear: removes all skills from all optional groups.
sync_optional() {
  dest_base="$1"
  optional_dir="$SCRIPT_DIR/skills/optional"
  dest_dir="$dest_base/skills"

  [ -d "$optional_dir" ] || return 0

  for group_dir in "$optional_dir"/*/; do
    [ -d "$group_dir" ] || continue
    group="$(basename "$group_dir")"

    if [ "$CMD" = "clear" ]; then
      # Remove all skills from this group.
      for item in "$group_dir"/*; do
        [ -e "$item" ] || continue
        name="$(basename "$item")"
        if [ -e "$dest_dir/$name" ]; then
          rm -rf "$dest_dir/$name"
          echo "Removed optional $name"
        fi
      done
      continue
    fi

    # sync: skip groups not opted in.
    if ! is_opted_in "$group"; then
      continue
    fi

    mkdir -p "$dest_dir"

    for item in "$group_dir"/*; do
      [ -e "$item" ] || continue
      name="$(basename "$item")"
      dest="$dest_dir/$name"
      rm -rf "$dest"
      cp -r "$item" "$dest"
      echo "skills/$name (optional: $group)"
    done
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
      # Skip the "optional" directory -- handled separately.
      [ "$team" = "optional" ] && continue
      sync_team "$category" "$team" "$dest_base"
    done
  done
  sync_optional "$dest_base"
  echo "--- ${CMD}ed $target ---"
done
