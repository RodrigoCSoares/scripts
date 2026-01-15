import cmd
import gleam/io
import gleam/list.{flatten}

/// Sync dotfiles bare repo - check for changes, commit and push
pub fn sync() -> Nil {
  let home = cmd.home_dir()
  let git_dir = home <> "/.dotfiles"
  let git_args = ["--git-dir=" <> git_dir, "--work-tree=" <> home]

  // Check if there are any changes
  let status_result =
    cmd.run_silent("git", flatten([git_args, ["status", "--porcelain"]]))

  case status_result {
    Ok(output) if output == "" -> {
      io.println("  No changes to dotfiles")
      Nil
    }
    Ok(_) -> {
      io.println("  Changes detected, committing...")

      // Add all tracked files that changed
      let _ = cmd.run_silent("git", flatten([git_args, ["add", "-u"]]))

      // Commit
      let _ =
        cmd.run_with_output(
          "git",
          flatten([
            git_args,
            ["commit", "-m", "Auto-sync dotfiles updates"],
          ]),
        )

      // Push
      let push_result =
        cmd.run_with_output("git", flatten([git_args, ["push"]]))

      case push_result {
        Ok(_) -> io.println("  Dotfiles synced and pushed!")
        Error(msg) -> io.println("  Push failed: " <> msg)
      }
      Nil
    }
    Error(msg) -> {
      io.println("  Error checking status: " <> msg)
      Nil
    }
  }
}
