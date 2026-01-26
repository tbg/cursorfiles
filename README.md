# cursorfiles

Cursor IDE customizations (commands and rules) for syncing into other repositories.
Cursor allows pulling in rules from a Github repository, but as of writing does not
allow this for commands, hence the approach in this repository.

## Setup

```
DEST=$HOME/go/src/github.com/tbg
mkdir -p "$DEST"
git clone https://github.com/tbg/cursorfiles "$DEST"
```

## Usage

`[target_repo]` defaults to the cockroach repo if no target is specified.

Commands prompts before deleting files.

```sh
git pull
./sync.sh sync [target_repo]   # sync commands and rules to target
```

To remove installed rules:

```
./sync.sh clear [target_repo]
```

