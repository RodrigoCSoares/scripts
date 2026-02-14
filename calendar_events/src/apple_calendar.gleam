import gleam/string
import llm.{type CalendarEvent}
import shellout

/// Creates an event in Apple Calendar using osascript (AppleScript).
/// Date format expected: YYYY-MM-DD
/// Time format expected: HH:MM (24-hour)
pub fn create_event(event: CalendarEvent) -> Result(String, String) {
  let date_parts = string.split(event.date, "-")
  let #(year, month, day) = case date_parts {
    [y, m, d] -> #(y, m, d)
    _ -> #("2026", "01", "01")
  }

  let start_parts = string.split(event.start_time, ":")
  let #(start_hour, start_minute) = case start_parts {
    [h, m] -> #(h, m)
    _ -> #("09", "00")
  }

  let end_parts = string.split(event.end_time, ":")
  let #(end_hour, end_minute) = case end_parts {
    [h, m] -> #(h, m)
    _ -> #("10", "00")
  }

  let location_line = case event.location {
    "" -> ""
    loc ->
      "\n            set location of newEvent to \""
      <> escape_applescript(loc)
      <> "\""
  }

  let notes_line = case event.notes {
    "" -> ""
    n ->
      "\n            set description of newEvent to \""
      <> escape_applescript(n)
      <> "\""
  }

  let recurrence_line = case event.recurrence {
    "" -> ""
    rrule ->
      "\n            set recurrence of newEvent to \""
      <> escape_applescript(rrule)
      <> "\""
  }

  let script = "
    tell application \"Calendar\"
        tell calendar \"Calendar\"
            set startDate to current date
            set year of startDate to " <> year <> "
            set month of startDate to " <> month <> "
            set day of startDate to " <> day <> "
            set hours of startDate to " <> start_hour <> "
            set minutes of startDate to " <> start_minute <> "
            set seconds of startDate to 0

            set endDate to current date
            set year of endDate to " <> year <> "
            set month of endDate to " <> month <> "
            set day of endDate to " <> day <> "
            set hours of endDate to " <> end_hour <> "
            set minutes of endDate to " <> end_minute <> "
            set seconds of endDate to 0

            set newEvent to make new event with properties {summary:\"" <> escape_applescript(
      event.title,
    ) <> "\", start date:startDate, end date:endDate}" <> location_line <> notes_line <> recurrence_line <> "
        end tell
    end tell
    "

  case
    shellout.command(run: "osascript", with: ["-e", script], in: ".", opt: [])
  {
    Ok(_) -> Ok("Event created successfully!")
    Error(#(_, msg)) -> Error("Failed to create calendar event: " <> msg)
  }
}

fn escape_applescript(input: String) -> String {
  input
  |> string.replace("\\", "\\\\")
  |> string.replace("\"", "\\\"")
}
