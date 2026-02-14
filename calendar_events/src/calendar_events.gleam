import apple_calendar
import argv
import gleam/io
import gleam/string
import llm
import shellout

pub fn main() -> Nil {
  let args = argv.load().arguments

  case args {
    [] -> {
      io.println("Error: Please provide an event description.")
      io.println("Usage: calendar_events \"Lunch with Sarah tomorrow at noon\"")
    }
    _ -> {
      let input = string.join(args, " ")
      io.println("Parsing: \"" <> input <> "\"")
      io.println("")

      let today = get_today()
      let today_day = get_day_of_week(today)
      io.println("Today is: " <> today <> " (" <> today_day <> ")")
      io.println("")

      io.println("Asking LLM to parse your event...")
      io.println("")

      case llm.parse_event(input, today, today_day) {
        Ok(event) -> {
          io.println("Event details:")
          io.println("  Title:    " <> event.title)
          let day_name = get_day_of_week(event.date)
          io.println("  Date:     " <> event.date <> " (" <> day_name <> ")")
          io.println("  Start:    " <> event.start_time)
          io.println("  End:      " <> event.end_time)
          case event.location {
            "" -> Nil
            loc -> {
              io.println("  Location: " <> loc)
              Nil
            }
          }
          case event.notes {
            "" -> Nil
            notes -> {
              io.println("  Notes:    " <> notes)
              Nil
            }
          }
          case event.recurrence {
            "" -> Nil
            rrule -> {
              io.println("  Repeats:  " <> rrule)
              Nil
            }
          }
          io.println("")

          io.println("Creating event in Apple Calendar...")
          case apple_calendar.create_event(event) {
            Ok(msg) -> io.println(msg)
            Error(e) -> io.println("Error: " <> e)
          }
        }
        Error(e) -> io.println("Error: " <> e)
      }
    }
  }
}

fn get_today() -> String {
  case shellout.command(run: "date", with: ["+%Y-%m-%d"], in: ".", opt: []) {
    Ok(date) -> string.trim(date)
    Error(_) -> "2026-02-14"
  }
}

fn get_day_of_week(date: String) -> String {
  case
    shellout.command(
      run: "date",
      with: ["-j", "-f", "%Y-%m-%d", date, "+%A"],
      in: ".",
      opt: [],
    )
  {
    Ok(day) -> string.trim(day)
    Error(_) -> "Unknown"
  }
}
