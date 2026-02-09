#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
  echo "Usage: $0 <sync|clear|add-hook|del-hook>" >&2
  echo "  sync      - symlink skills, agents, and rules into ~/.claude/" >&2
  echo "  clear     - remove symlinks from ~/.claude/" >&2
  echo "  add-hook  - install git post-merge hook to auto-sync on pull" >&2
  echo "  del-hook  - remove git post-merge hook" >&2
  echo "" >&2
  echo "Symlinks {skills,agents,rules}/<team>/ dirs into ~/.claude/" >&2
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

# Symlink a source directory to a destination path.
# For sync: create symlink (replacing any existing file/dir/symlink)
# For clear: remove symlink
link_dir() {
  src="$SCRIPT_DIR/$1"
  dest="$2"

  if [ "$CMD" = "clear" ]; then
    if [ -L "$dest" ]; then
      rm "$dest"
      echo "Removed $dest"
    elif [ -e "$dest" ]; then
      echo "Warning: $dest exists but is not a symlink, skipping" >&2
    fi
    return 0
  fi

  # sync
  if [ ! -d "$src" ]; then
    echo "Warning: source $src does not exist, skipping" >&2
    return 0
  fi

  mkdir -p "$(dirname "$dest")"

  if [ -L "$dest" ]; then
    rm "$dest"
  elif [ -e "$dest" ]; then
    echo "Warning: $dest exists but is not a symlink, replacing" >&2
    rm -rf "$dest"
  fi

  ln -s "$src" "$dest"
  echo "$dest -> $src"
}

# For each category, symlink every team-level subdirectory (e.g. skills/kv, agents/kv).
for category in skills agents rules; do
  if [ -d "$SCRIPT_DIR/$category" ]; then
    for team_dir in "$SCRIPT_DIR/$category"/*/; do
      [ -d "$team_dir" ] || continue
      team="$(basename "$team_dir")"
      link_dir "$category/$team" "$HOME/.claude/$category/$team"
    done
  fi
done
