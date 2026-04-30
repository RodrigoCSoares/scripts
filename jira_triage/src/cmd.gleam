import envoy
import shellout

pub fn run_silent(cmd: String, args: List(String)) -> Result(String, String) {
  case shellout.command(run: cmd, with: args, in: ".", opt: []) {
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
