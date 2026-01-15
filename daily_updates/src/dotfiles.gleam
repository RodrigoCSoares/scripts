import cmd
import gleam/io
import gleam/list.{flatten}

/// Sync dotfiles bare repo
pub fn sync() -> Nil {
  let home = cmd.home_dir()
  let git_dir = home <> "/.dotfiles"
  let git_args = ["--git-dir=" <> git_dir, "--work-tree=" <> home]

  sync_bare_repo(git_args, "dotfiles")
}

/// Sync neovim config repo
pub fn sync_nvim() -> Nil {
  let home = cmd.home_dir()
  let nvim_dir = home <> "/.config/nvim"

  sync_repo(nvim_dir, "nvim config")
}

/// Sync a bare git repo (like dotfiles)
fn sync_bare_repo(git_args: List(String), name: String) -> Nil {
  let status_result =
    cmd.run_silent("git", flatten([git_args, ["status", "--porcelain"]]))

  case status_result {
    Ok(output) if output == "" -> {
      io.println("  No changes to " <> name)
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
            ["commit", "-m", "Auto-sync " <> name <> " updates"],
          ]),
        )

      // Push
      let push_result =
        cmd.run_with_output("git", flatten([git_args, ["push"]]))

      case push_result {
        Ok(_) -> io.println("  " <> name <> " synced and pushed!")
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

/// Sync a regular git repo (like nvim config)
fn sync_repo(repo_path: String, name: String) -> Nil {
  let status_result =
    cmd.run_in_dir("git", ["status", "--porcelain"], repo_path)

  case status_result {
    Ok(output) if output == "" -> {
      io.println("  No changes to " <> name)
      Nil
    }
    Ok(_) -> {
      io.println("  Changes detected, committing...")

      // Add all tracked files that changed
      let _ = cmd.run_in_dir("git", ["add", "-u"], repo_path)

      // Commit
      let _ =
        cmd.run_in_dir_with_output(
          "git",
          ["commit", "-m", "Auto-sync " <> name <> " updates"],
          repo_path,
        )

      // Push
      let push_result = cmd.run_in_dir_with_output("git", ["push"], repo_path)

      case push_result {
        Ok(_) -> io.println("  " <> name <> " synced and pushed!")
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
