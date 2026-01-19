import cmd
import gleam/io
import gleam/list.{flatten}
import llm

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

/// Sync personal scripts repo
pub fn sync_scripts() -> Nil {
  let home = cmd.home_dir()
  let scripts_dir = home <> "/personal/scripts"

  sync_repo(scripts_dir, "scripts")
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

      // Add all files including untracked
      let _ = cmd.run_silent("git", flatten([git_args, ["add", "-A"]]))

      // Get diff for LLM
      let diff_result =
        cmd.run_silent("git", flatten([git_args, ["diff", "--cached"]]))
      let diff = case diff_result {
        Ok(d) -> d
        Error(_) -> ""
      }

      // Generate commit message (fallback to simple message if LLM unavailable)
      let fallback = "Auto-sync " <> name <> " updates"
      let commit_msg = case llm.generate_commit_message(diff) {
        Ok(msg) -> msg
        Error(_) -> fallback
      }

      // Commit
      let _ =
        cmd.run_with_output(
          "git",
          flatten([git_args, ["commit", "-m", commit_msg]]),
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

/// Sync a regular git repo (includes untracked files)
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

      // Add all files including untracked
      let _ = cmd.run_in_dir("git", ["add", "-A"], repo_path)

      // Get diff for LLM
      let diff_result = cmd.run_in_dir("git", ["diff", "--cached"], repo_path)
      let diff = case diff_result {
        Ok(d) -> d
        Error(_) -> ""
      }

      // Generate commit message (fallback to simple message if LLM unavailable)
      let fallback = "Auto-sync " <> name <> " updates"
      let commit_msg = case llm.generate_commit_message(diff) {
        Ok(msg) -> msg
        Error(_) -> fallback
      }

      // Commit
      let _ =
        cmd.run_in_dir_with_output(
          "git",
          ["commit", "-m", commit_msg],
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
