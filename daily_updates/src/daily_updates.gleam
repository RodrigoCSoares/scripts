import cmd
import dotfiles
import gleam/io

pub fn main() -> Nil {
  io.println("=== Daily Updates ===\n")

  io.println("-> Updating Homebrew...")
  cmd.run("brew", ["update"])

  io.println("\n-> Upgrading Homebrew packages...")
  cmd.run("brew", ["upgrade"])

  io.println("\n-> Updating Brewfile...")
  cmd.run("brew", [
    "bundle",
    "dump",
    "--file=" <> cmd.home_dir() <> "/.Brewfile",
    "--force",
  ])

  io.println("\n-> Upgrading Neovim Lazy plugins...")
  cmd.run("nvim", ["--headless", "+Lazy! sync", "+qa"])

  io.println("\n-> Syncing dotfiles...")
  dotfiles.sync()

  io.println("\n-> Syncing nvim config...")
  dotfiles.sync_nvim()

  io.println("\n=== All updates complete! ===")
}
