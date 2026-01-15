import gleam/io
import shellout

pub fn main() -> Nil {
  io.println("=== Daily Updates ===\n")

  io.println("-> Updating Homebrew...")
  run_command("brew", ["update"])

  io.println("\n-> Upgrading Homebrew packages...")
  run_command("brew", ["upgrade"])

  io.println("\n-> Upgrading Neovim Lazy plugins...")
  run_command("nvim", ["--headless", "+Lazy! sync", "+qa"])

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
