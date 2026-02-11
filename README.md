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

# Point git hooks at the githooks/ directory so that
# pulling/pushing master automatically runs sync.
git config core.hooksPath ./githooks
```

## Usage

```sh
./sync.sh sync   # copy skills, agents, and rules into ~/.claude/ and ~/.cursor/
./sync.sh clear  # remove synced items from ~/.claude/ and ~/.cursor/
```

With `core.hooksPath` configured, `git pull` and `git push` on master/main
automatically run `./sync.sh sync`.

## Configuration

Target repo defaults to `~/go/src/github.com/cockroachdb/cockroach`. To customize:

```sh
git config cursorfiles.target /path/to/your/repo
```

