import envoy
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import jira
import llm

pub fn main() -> Nil {
  io.println("=== Jira IE Triage ===\n")

  case envoy.get("JIRA_TRIAGE_PERIOD") {
    Error(_) -> io.println("No period selected.")
    Ok(period) -> run_triage(period)
  }
}

fn run_triage(period: String) -> Nil {
  let project = case envoy.get("JIRA_PROJECT") {
    Ok(p) -> p
    Error(_) -> "CPPI"
  }
  io.println(
    "\nFetching "
    <> project
    <> " tickets from the last "
    <> period_label(period)
    <> "...",
  )

  let base_url = case envoy.get("JIRA_BASE_URL") {
    Ok(url) -> url
    Error(_) -> ""
  }

  case jira.fetch_tickets(period) {
    Error(msg) -> io.println("Error: " <> msg)
    Ok([]) -> io.println("No tickets found.")
    Ok(tickets) -> {
      let total = list.length(tickets)
      io.println(
        "Found "
        <> int.to_string(total)
        <> " tickets. Analysing with Ollama...\n",
      )

      let divider = string.repeat("-", 80)
      io.println(divider)

      let ie_count =
        list.fold(tickets, 0, fn(count, ticket) {
          let result = llm.triage_ticket(ticket)
          let marker = case result.is_ie {
            True -> "[IE]"
            False -> "[--]"
          }
          let url = base_url <> "/browse/" <> ticket.key
          let linked_key =
            hyperlink(url, string.pad_end(ticket.key, 13, " "))
          io.println(
            linked_key
            <> "  "
            <> marker
            <> "  "
            <> ticket.created
            <> "  "
            <> string.slice(ticket.summary, 0, 44),
          )
          io.println(
            string.repeat(" ", 17)
            <> string.pad_end(ticket.status, 24, " ")
            <> result.reason,
          )
          io.println("")
          case result.is_ie {
            True -> count + 1
            False -> count
          }
        })

      io.println(divider)
      io.println(
        "IE: "
        <> int.to_string(ie_count)
        <> " / "
        <> int.to_string(total)
        <> " tickets",
      )
    }
  }
}

fn hyperlink(url: String, text: String) -> String {
  "\u{1B}]8;;" <> url <> "\u{1B}\\" <> text <> "\u{1B}]8;;\u{1B}\\"
}

fn period_label(period: String) -> String {
  case period {
    "1d" -> "day"
    "1w" -> "week"
    "2w" -> "two weeks"
    _ -> period
  }
}
