import cmd
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/io
import gleam/json
import gleam/list
import gleam/string

/// Load ignored packages from ~/.brewfile-ignore
fn load_ignored_packages() -> List(String) {
  let home = cmd.home_dir()
  let ignore_file = home <> "/.brewfile-ignore"

  case cmd.run_silent("cat", [ignore_file]) {
    Ok(content) ->
      content
      |> string.split("\n")
      |> list.map(string.trim)
      |> list.filter(fn(s) { s != "" && !string.starts_with(s, "#") })
    Error(_) -> []
  }
}

/// Check if a line contains an ignored package
fn is_ignored_line(line: String, ignored: List(String)) -> Bool {
  list.any(ignored, fn(pkg) { string.contains(line, "\"" <> pkg <> "\"") })
}

/// Cask info from brew
type CaskInfo {
  CaskInfo(token: String, tap: String)
}

/// Decoder for cask info from brew JSON
fn cask_info_decoder() -> decode.Decoder(CaskInfo) {
  use token <- decode.field("token", decode.string)
  use tap <- decode.field("tap", decode.string)
  decode.success(CaskInfo(token:, tap:))
}

/// Get a map of cask token -> tap for all installed casks
fn get_cask_taps() -> Dict(String, String) {
  let result =
    cmd.run_silent("brew", ["info", "--json=v2", "--installed", "--cask"])

  case result {
    Ok(json_str) -> parse_cask_json(json_str)
    Error(_) -> dict.new()
  }
}

/// Parse the brew JSON output to extract cask -> tap mapping
fn parse_cask_json(json_str: String) -> Dict(String, String) {
  let casks_decoder = decode.at(["casks"], decode.list(cask_info_decoder()))

  case json.parse(json_str, casks_decoder) {
    Ok(casks) ->
      casks
      |> list.map(fn(c) { #(c.token, c.tap) })
      |> dict.from_list
    Error(_) -> dict.new()
  }
}

/// Standard taps that don't need full path
fn is_standard_tap(tap: String) -> Bool {
  tap == "homebrew/cask"
  || tap == "homebrew/cask-fonts"
  || tap == "homebrew/cask-versions"
  || tap == "homebrew/core"
}

/// Fix a single line if it's a cask that needs a full tap path
fn fix_cask_line(line: String, taps: Dict(String, String)) -> String {
  case string.starts_with(line, "cask \"") {
    False -> line
    True -> {
      // Extract cask name from: cask "name"
      let trimmed =
        line
        |> string.drop_start(6)
        |> string.drop_end(1)

      // Skip if already has tap path
      case string.contains(trimmed, "/") {
        True -> line
        False -> {
          case dict.get(taps, trimmed) {
            Ok(tap) -> {
              case is_standard_tap(tap) {
                True -> line
                False -> "cask \"" <> tap <> "/" <> trimmed <> "\""
              }
            }
            _ -> line
          }
        }
      }
    }
  }
}

/// Fix all cask entries in a Brewfile to include full tap paths
/// Also removes packages listed in ~/.brewfile-ignore
pub fn fix_tap_paths(brewfile_path: String) -> Nil {
  io.println("  Resolving cask tap paths...")

  let taps = get_cask_taps()
  let ignored = load_ignored_packages()

  case ignored != [] {
    True -> io.println("  Ignoring packages: " <> string.join(ignored, ", "))
    False -> Nil
  }

  // Read the brewfile
  let read_result = cmd.run_silent("cat", [brewfile_path])

  case read_result {
    Error(msg) -> {
      io.println("  Error reading Brewfile: " <> msg)
      Nil
    }
    Ok(content) -> {
      let lines = string.split(content, "\n")
      let fixed_lines =
        lines
        |> list.filter(fn(line) { !is_ignored_line(line, ignored) })
        |> list.map(fn(line) { fix_cask_line(line, taps) })
      let fixed_content = string.join(fixed_lines, "\n")

      // Write back
      let write_result =
        cmd.run_silent("sh", [
          "-c",
          "cat > "
            <> brewfile_path
            <> " << 'BREWFILE_EOF'\n"
            <> fixed_content
            <> "\nBREWFILE_EOF",
        ])

      case write_result {
        Ok(_) -> io.println("  Tap paths fixed!")
        Error(msg) -> io.println("  Error writing Brewfile: " <> msg)
      }
      Nil
    }
  }
}
