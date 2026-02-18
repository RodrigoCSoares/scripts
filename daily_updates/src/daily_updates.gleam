import brewfile
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
  let brewfile_path = cmd.home_dir() <> "/.Brewfile"
  cmd.run("brew", [
    "bundle",
    "dump",
    "--file=" <> brewfile_path,
    "--force",
    "--describe",
  ])
  brewfile.fix_tap_paths(brewfile_path)

  io.println("\n-> Upgrading Neovim Lazy plugins...")
  cmd.run("nvim", ["--headless", "+Lazy! sync", "+qa"])

  io.println("\n-> Syncing dotfiles...")
  dotfiles.sync()

  io.println("\n-> Syncing nvim config...")
  dotfiles.sync_nvim()

  io.println("\n-> Syncing scripts...")
  dotfiles.sync_scripts()

  io.println("\n=== All updates complete! ===")
}
