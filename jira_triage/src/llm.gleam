import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/result
import gleam/string
import jira

pub type TriageResult {
  TriageResult(is_ie: Bool, reason: String)
}

pub fn triage_ticket(ticket: jira.Ticket) -> TriageResult {
  case call_ollama(build_prompt(ticket)) {
    Ok(response) -> parse_response(response)
    Error(_) -> TriageResult(is_ie: False, reason: "Could not analyse (Ollama unavailable)")
  }
}

fn build_prompt(ticket: jira.Ticket) -> String {
  "You are triaging Jira support tickets for the JustEat Ireland (IE) market team. "
  <> "Determine if this ticket is related to the IE (Ireland) market.\n\n"
  <> "Key: "
  <> ticket.key
  <> "\nSummary: "
  <> ticket.summary
  <> "\nStatus: "
  <> ticket.status
  <> "\nCreated: "
  <> ticket.created
  <> "\nReporter: "
  <> ticket.reporter_name
  <> " (timezone: "
  <> ticket.reporter_tz
  <> ")\nLabels: "
  <> ticket.labels
  <> "\nDescription: "
  <> ticket.description
  <> "\n\nIE market signals: text says 'IE' or 'Ireland', Europe/Dublin timezone, IBAN + sort code (Irish banking), just-eat.ie, invoicing execution with IE listed.\n"
  <> "Non-IE signals: 'BTW' (Dutch VAT), 'Thuisbezorgd', '/nl/' in URLs, explicit DE/NL/BG/AT/UK/PL/SK/BE/ES/IT market mentions, 'p' or 'pence' (UK currency).\n\n"
  <> "Respond with a JSON object: {\"ie\": true or false, \"reason\": \"one sentence\"}"
}

fn parse_response(response: String) -> TriageResult {
  let decoder = {
    use is_ie <- decode.field("ie", decode.bool)
    use reason <- decode.field("reason", decode.string)
    decode.success(TriageResult(is_ie:, reason:))
  }
  case json.parse(response, decoder) {
    Ok(r) -> r
    Error(_) -> {
      let is_ie = string.contains(string.lowercase(response), "\"ie\": true")
      TriageResult(is_ie:, reason: string.slice(response, 0, 120))
    }
  }
}

fn call_ollama(prompt: String) -> Result(String, String) {
  let body =
    json.object([
      #("model", json.string("llama3")),
      #("prompt", json.string(prompt)),
      #("stream", json.bool(False)),
      #("format", json.string("json")),
      #(
        "options",
        json.object([
          #("num_predict", json.int(150)),
          #("temperature", json.float(0.1)),
        ]),
      ),
    ])
    |> json.to_string

  let req =
    request.new()
    |> request.set_scheme(http.Http)
    |> request.set_method(http.Post)
    |> request.set_host("localhost")
    |> request.set_port(11_434)
    |> request.set_path("/api/generate")
    |> request.set_body(body)
    |> request.prepend_header("content-type", "application/json")

  case httpc.send(req) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          let decoder = {
            use text <- decode.field("response", decode.string)
            decode.success(text)
          }
          json.parse(resp.body, decoder)
          |> result.map_error(fn(_) { "Could not parse Ollama response" })
        }
        status ->
          Error("Ollama returned status " <> string.inspect(status))
      }
    }
    Error(_) -> Error("Ollama not available on localhost:11434")
  }
}
