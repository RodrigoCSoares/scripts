import gleam/io
import gleam/string
import shellout

/// Run a command and print the result
pub fn run(cmd: String, args: List(String)) -> Nil {
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

/// Run a command silently and return the output
pub fn run_silent(cmd: String, args: List(String)) -> Result(String, String) {
  let result = shellout.command(run: cmd, with: args, in: ".", opt: [])
  case result {
    Ok(output) -> Ok(output)
    Error(#(_, msg)) -> Error(msg)
  }
}

/// Run a command with output shown
pub fn run_with_output(
  cmd: String,
  args: List(String),
) -> Result(String, String) {
  let result =
    shellout.command(run: cmd, with: args, in: ".", opt: [
      shellout.LetBeStdout,
      shellout.LetBeStderr,
    ])
  case result {
    Ok(output) -> Ok(output)
    Error(#(_, msg)) -> Error(msg)
  }
}

/// Get the home directory
pub fn home_dir() -> String {
  let result =
    shellout.command(run: "sh", with: ["-c", "echo $HOME"], in: ".", opt: [])
  case result {
    Ok(home) -> string.trim(home)
    Error(_) -> "/Users/rodrigo.soares"
  }
}

/// Run a command silently in a specific directory
pub fn run_in_dir(
  cmd: String,
  args: List(String),
  dir: String,
) -> Result(String, String) {
  let result = shellout.command(run: cmd, with: args, in: dir, opt: [])
  case result {
    Ok(output) -> Ok(output)
    Error(#(_, msg)) -> Error(msg)
  }
}

/// Run a command with output in a specific directory
pub fn run_in_dir_with_output(
  cmd: String,
  args: List(String),
  dir: String,
) -> Result(String, String) {
  let result =
    shellout.command(run: cmd, with: args, in: dir, opt: [
      shellout.LetBeStdout,
      shellout.LetBeStderr,
    ])
  case result {
    Ok(output) -> Ok(output)
    Error(#(_, msg)) -> Error(msg)
  }
}
