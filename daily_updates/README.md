# daily_updates

A Gleam script that automates daily maintenance tasks, run via Raycast.

## What it does

1. **Homebrew** — runs `brew update` and `brew upgrade`
2. **Brewfile** — dumps the current Homebrew bundle to `~/.Brewfile`, fixes cask tap paths, and removes packages listed in `~/.brewfile-ignore`
3. **Neovim plugins** — syncs Lazy.nvim plugins headlessly
4. **Dotfiles sync** — auto-commits and pushes changes in the `~/.dotfiles` bare repo, which tracks:
   - Shell config, git config, and other dotfiles in `$HOME`
   - `~/.config/opencode/opencode.json` (OpenCode config)
5. **Nvim config sync** — auto-commits and pushes `~/.config/nvim`
6. **Scripts sync** — auto-commits and pushes `~/personal/scripts`

Commit messages are generated via a local Ollama instance (llama3).

## Adding new config files to the dotfiles repo

The dotfiles sync only tracks files that have been explicitly added. To start tracking a new config file or directory:

```sh
git --git-dir=$HOME/.dotfiles --work-tree=$HOME add ~/.config/<tool>/config-file
```

Once tracked, any future changes will be automatically committed and pushed by the daily updates script.

## Development

```sh
gleam run   # Run the project
gleam build # Build the project
```
