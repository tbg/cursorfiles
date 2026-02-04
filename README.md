# cursorfiles

Cursor IDE customizations (commands and rules) for syncing into other repositories.
Cursor allows pulling in rules from a Github repository, but as of writing does not
allow this for commands, hence the approach in this repository.

## Setup

```sh
DEST=$HOME/go/src/github.com/tbg/cursorfiles
mkdir -p "$(dirname "$DEST")"
git clone https://github.com/tbg/cursorfiles "$DEST"
cd "$DEST"

# Optional: install git hook to auto-sync on pull
./sync.sh add-hook
```

## Usage

```sh
./sync.sh sync       # create symlinks in target repo
./sync.sh clear      # remove symlinks from target repo
./sync.sh add-hook   # install post-merge hook for auto-sync
./sync.sh del-hook   # remove post-merge hook
```

With the hook installed, `git pull` on master/main automatically runs `sync`.

## Configuration

Target repo defaults to `~/go/src/github.com/cockroachdb/cockroach`. To customize:

```sh
git config cursorfiles.target /path/to/your/repo
```

