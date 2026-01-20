import envoy
import gleam/io
import shellout

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

pub fn run_silent(cmd: String, args: List(String)) -> Result(String, String) {
  let result = shellout.command(run: cmd, with: args, in: ".", opt: [])
  case result {
    Ok(output) -> Ok(output)
    Error(#(_, msg)) -> Error(msg)
  }
}

pub fn home_dir() -> String {
  case envoy.get("HOME") {
    Ok(home) -> home
    Error(_) -> "/Users/rodrigo.soares"
  }
}

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
