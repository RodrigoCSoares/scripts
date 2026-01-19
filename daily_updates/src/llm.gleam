import cmd
import gleam/string

/// Generate a commit message using a local LLM (Ollama)
pub fn generate_commit_message(diff: String) -> Result(String, String) {
  let prompt =
    "Generate a concise git commit message for these changes. Be specific about what changed. Output ONLY the commit message, nothing else. No quotes, no prefixes like 'feat:' or 'fix:', just a plain sentence.\n\nChanges:\n"
    <> diff

  case call_ollama(prompt) {
    Ok(message) -> Ok(string.trim(message))
    Error(e) -> Error(e)
  }
}

/// Call Ollama API using curl
fn call_ollama(prompt: String) -> Result(String, String) {
  // Check if Ollama is running first
  let health_check =
    cmd.run_silent("curl", [
      "-s",
      "-o",
      "/dev/null",
      "-w",
      "%{http_code}",
      "--max-time",
      "2",
      "http://localhost:11434/api/tags",
    ])

  case health_check {
    Ok(status) if status == "200" -> {
      // Ollama is running, make the actual request
      let escaped_prompt = escape_json_string(prompt)
      let body =
        "{\"model\":\"llama3\",\"prompt\":\""
        <> escaped_prompt
        <> "\",\"stream\":false,\"options\":{\"num_predict\":100}}"

      let result =
        cmd.run_silent("curl", [
          "-s",
          "--max-time",
          "30",
          "-X",
          "POST",
          "http://localhost:11434/api/generate",
          "-H",
          "Content-Type: application/json",
          "-d",
          body,
        ])

      case result {
        Ok(response) -> parse_ollama_response(response)
        Error(e) -> Error(e)
      }
    }
    _ -> Error("Ollama not available")
  }
}

/// Parse Ollama JSON response to extract the generated text
fn parse_ollama_response(response: String) -> Result(String, String) {
  // Response format: {"model":"llama3","response":"...","done":true,...}
  // Simple extraction using string manipulation since we just need the response field
  case string.split(response, "\"response\":\"") {
    [_, rest] -> {
      case string.split(rest, "\",\"") {
        [message, ..] -> Ok(unescape_json_string(message))
        _ -> Error("Could not parse response")
      }
    }
    _ -> Error("Could not find response in JSON")
  }
}

/// Escape special characters for JSON string
fn escape_json_string(s: String) -> String {
  s
  |> string.replace("\\", "\\\\")
  |> string.replace("\"", "\\\"")
  |> string.replace("\n", "\\n")
  |> string.replace("\r", "\\r")
  |> string.replace("\t", "\\t")
}

/// Unescape JSON string
fn unescape_json_string(s: String) -> String {
  s
  |> string.replace("\\n", "\n")
  |> string.replace("\\r", "\r")
  |> string.replace("\\t", "\t")
  |> string.replace("\\\"", "\"")
  |> string.replace("\\\\", "\\")
}
