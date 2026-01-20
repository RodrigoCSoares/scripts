import cmd
import gleam/io
import gleam/list.{flatten}
import llm

pub fn sync() -> Nil {
  let home = cmd.home_dir()
  let git_dir = home <> "/.dotfiles"
  let git_prefix = ["--git-dir=" <> git_dir, "--work-tree=" <> home]

  sync_repo(home, "dotfiles", git_prefix)
}

pub fn sync_nvim() -> Nil {
  let home = cmd.home_dir()
  let nvim_dir = home <> "/.config/nvim"

  sync_repo(nvim_dir, "nvim config", [])
}

pub fn sync_scripts() -> Nil {
  let home = cmd.home_dir()
  let scripts_dir = home <> "/personal/scripts"

  sync_repo(scripts_dir, "scripts", [])
}

/// For bare repos (like dotfiles), only tracked files are added (-u)
/// For regular repos, all files including untracked are added (-A)
fn sync_repo(repo_path: String, name: String, git_prefix: List(String)) -> Nil {
  let git_args = fn(args) { flatten([git_prefix, args]) }
  let is_bare_repo = git_prefix != []

  let status_result =
    cmd.run_in_dir("git", git_args(["status", "--porcelain"]), repo_path)

  case status_result {
    Ok(output) if output == "" -> {
      io.println("  No changes to " <> name)
      Nil
    }
    Ok(_) -> {
      io.println("  Changes detected, committing...")

      let add_flag = case is_bare_repo {
        True -> "-u"
        False -> "-A"
      }
      let _ = cmd.run_in_dir("git", git_args(["add", add_flag]), repo_path)

      let diff = case
        cmd.run_in_dir("git", git_args(["diff", "--cached"]), repo_path)
      {
        Ok(d) -> d
        Error(_) -> ""
      }

      let fallback = "Auto-sync " <> name <> " updates"
      let commit_msg = case llm.generate_commit_message(diff) {
        Ok(msg) -> msg
        Error(_) -> fallback
      }

      let _ =
        cmd.run_in_dir_with_output(
          "git",
          git_args(["commit", "-m", commit_msg]),
          repo_path,
        )

      let push_result =
        cmd.run_in_dir_with_output("git", git_args(["push"]), repo_path)

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
