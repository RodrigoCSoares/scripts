import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json
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

/// Call Ollama API using gleam_httpc
fn call_ollama(prompt: String) -> Result(String, String) {
  // Build the request body as JSON
  let body =
    json.object([
      #("model", json.string("llama3")),
      #("prompt", json.string(prompt)),
      #("stream", json.bool(False)),
      #("options", json.object([#("num_predict", json.int(100))])),
    ])
    |> json.to_string

  // Create the request
  let req =
    request.new()
    |> request.set_method(http.Post)
    |> request.set_host("localhost")
    |> request.set_port(11_434)
    |> request.set_path("/api/generate")
    |> request.set_body(body)
    |> request.prepend_header("content-type", "application/json")

  // Send the request
  case httpc.send(req) {
    Ok(resp) -> {
      case resp.status {
        200 -> parse_ollama_response(resp.body)
        _ -> Error("Ollama returned status: " <> string.inspect(resp.status))
      }
    }
    Error(_) -> Error("Ollama not available")
  }
}

/// Parse Ollama JSON response to extract the generated text
fn parse_ollama_response(response: String) -> Result(String, String) {
  let decoder = {
    use response_text <- decode.field("response", decode.string)
    decode.success(response_text)
  }

  case json.parse(response, decoder) {
    Ok(message) -> Ok(message)
    Error(_) -> Error("Could not parse Ollama response")
  }
}
