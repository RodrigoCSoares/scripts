import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/string

pub type CalendarEvent {
  CalendarEvent(
    title: String,
    date: String,
    start_time: String,
    end_time: String,
    location: String,
    notes: String,
    recurrence: String,
  )
}

pub fn parse_event(
  input: String,
  today: String,
  today_day: String,
) -> Result(CalendarEvent, String) {
  let prompt =
    "You are a calendar event parser. Extract event details from the user's natural language input. Today is "
    <> today_day
    <> ", "
    <> today
    <> ".

Respond with ONLY a valid JSON object (no markdown, no code fences, no explanation) with these exact fields:
- \"title\": string (event title/summary, NEVER empty, infer from context if needed)
- \"date\": string (the FIRST occurrence date in YYYY-MM-DD format. Resolve relative dates based on today's date and day of week. The date MUST fall on the correct day of week)
- \"start_time\": string (start time in HH:MM format, 24-hour clock)
- \"end_time\": string (end time in HH:MM format, 24-hour clock. If no duration specified, default to 1 hour after start)
- \"location\": string (location if mentioned, otherwise empty string)
- \"notes\": string (any additional details mentioned, otherwise empty string)
- \"recurrence\": string (iCalendar RRULE format if the event is recurring, otherwise empty string. Important rules:
  * 'every weekday' or 'except weekends' means FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR (NOT FREQ=DAILY)
  * 'every Monday' means FREQ=WEEKLY;INTERVAL=1;BYDAY=MO
  * 'every other Thursday' means FREQ=WEEKLY;INTERVAL=2;BYDAY=TH
  * 'last Friday of every month' means FREQ=MONTHLY;INTERVAL=1;BYDAY=-1FR
  * 'first Tuesday of every month' means FREQ=MONTHLY;INTERVAL=1;BYDAY=1TU
  * For weekday-only recurrence, the start date MUST be a weekday, never a Saturday or Sunday)

User input: "
    <> input

  case call_ollama(prompt) {
    Ok(response) -> parse_event_response(response)
    Error(e) -> Error(e)
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
          #("num_predict", json.int(300)),
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
        200 -> extract_ollama_response(resp.body)
        _ -> Error("Ollama returned status: " <> string.inspect(resp.status))
      }
    }
    Error(_) ->
      Error(
        "Could not connect to Ollama. Make sure it is running on localhost:11434",
      )
  }
}

fn extract_ollama_response(body: String) -> Result(String, String) {
  let decoder = {
    use response_text <- decode.field("response", decode.string)
    decode.success(response_text)
  }

  case json.parse(body, decoder) {
    Ok(text) -> Ok(string.trim(text))
    Error(_) -> Error("Could not parse Ollama response envelope")
  }
}

fn parse_event_response(response: String) -> Result(CalendarEvent, String) {
  let decoder = {
    use title <- decode.field("title", decode.string)
    use date <- decode.field("date", decode.string)
    use start_time <- decode.field("start_time", decode.string)
    use end_time <- decode.field("end_time", decode.string)
    use location <- decode.optional_field("location", "", decode.string)
    use notes <- decode.optional_field("notes", "", decode.string)
    use recurrence <- decode.optional_field("recurrence", "", decode.string)
    decode.success(CalendarEvent(
      title: title,
      date: date,
      start_time: start_time,
      end_time: end_time,
      location: location,
      notes: notes,
      recurrence: recurrence,
    ))
  }

  case json.parse(response, decoder) {
    Ok(event) -> Ok(event)
    Error(_) ->
      Error(
        "Could not parse event from LLM response. Raw response: " <> response,
      )
  }
}
