import gleam/io
import gleam/list.{flatten}
import gleam/string
import shellout

pub fn main() -> Nil {
  io.println("=== Daily Updates ===\n")

  io.println("-> Updating Homebrew...")
  run_command("brew", ["update"])

  io.println("\n-> Upgrading Homebrew packages...")
  run_command("brew", ["upgrade"])

  io.println("\n-> Upgrading Neovim Lazy plugins...")
  run_command("nvim", ["--headless", "+Lazy! sync", "+qa"])

  io.println("\n-> Syncing dotfiles...")
  sync_dotfiles()

  io.println("\n=== All updates complete! ===")
}

fn run_command(cmd: String, args: List(String)) -> Nil {
  let result =
    shellout.command(run: cmd, with: args, in: ".", opt: [
      shellout.LetBeStdout,
      shellout.LetBeStderr,
    ])

  case result {
    Ok(_) -> io.println("  Done!")
    Error(#(_, msg)) -> {
      io.println("  Error: " <> msg)
      Nil
    }
  }
}

fn sync_dotfiles() -> Nil {
  let home = get_home_dir()
  let git_dir = home <> "/.dotfiles"
  let git_args = ["--git-dir=" <> git_dir, "--work-tree=" <> home]

  // Check if there are any changes
  let status_result =
    shellout.command(
      run: "git",
      with: flatten([git_args, ["status", "--porcelain"]]),
      in: ".",
      opt: [],
    )

  case status_result {
    Ok(output) if output == "" -> {
      io.println("  No changes to dotfiles")
      Nil
    }
    Ok(_) -> {
      io.println("  Changes detected, committing...")
      // Add all tracked files that changed
      let _ =
        shellout.command(
          run: "git",
          with: flatten([git_args, ["add", "-u"]]),
          in: ".",
          opt: [],
        )
      // Commit
      let _ =
        shellout.command(
          run: "git",
          with: flatten([
            git_args,
            ["commit", "-m", "Auto-sync dotfiles updates"],
          ]),
          in: ".",
          opt: [shellout.LetBeStdout, shellout.LetBeStderr],
        )
      // Push
      let push_result =
        shellout.command(
          run: "git",
          with: flatten([git_args, ["push"]]),
          in: ".",
          opt: [shellout.LetBeStdout, shellout.LetBeStderr],
        )
      case push_result {
        Ok(_) -> io.println("  Dotfiles synced and pushed!")
        Error(#(_, msg)) -> io.println("  Push failed: " <> msg)
      }
      Nil
    }
    Error(#(_, msg)) -> {
      io.println("  Error checking status: " <> msg)
      Nil
    }
  }
}

fn get_home_dir() -> String {
  let result =
    shellout.command(run: "sh", with: ["-c", "echo $HOME"], in: ".", opt: [])
  case result {
    Ok(home) -> string.trim(home)
    Error(_) -> "/Users/rodrigo.soares"
  }
}
