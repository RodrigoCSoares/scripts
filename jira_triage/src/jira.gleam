import envoy
import gleam/dynamic/decode
import gleam/json
import gleam/result
import gleam/string
import shellout
import simplifile

pub type Ticket {
  Ticket(
    key: String,
    summary: String,
    description: String,
    status: String,
    created: String,
    reporter_name: String,
    reporter_tz: String,
    labels: String,
  )
}

pub fn fetch_tickets(period: String) -> Result(List(Ticket), String) {
  use email <- result.try(
    envoy.get("JIRA_EMAIL")
    |> result.replace_error("JIRA_EMAIL environment variable not set"),
  )
  use token <- result.try(
    envoy.get("JIRA_API_TOKEN")
    |> result.replace_error("JIRA_API_TOKEN environment variable not set"),
  )
  use base_url <- result.try(
    envoy.get("JIRA_BASE_URL")
    |> result.replace_error("JIRA_BASE_URL environment variable not set"),
  )
  use project <- result.try(
    envoy.get("JIRA_PROJECT")
    |> result.replace_error("JIRA_PROJECT environment variable not set"),
  )

  let jql =
    "project = "
    <> project
    <> " AND created >= -"
    <> period
    <> " AND status in (\"Waiting for support\", \"Backlog - Pending prioritization\")"
    <> " ORDER BY created ASC"

  use raw_json <- result.try(
    shellout.command(
      run: "curl",
      with: [
        "-s",
        "-u",
        email <> ":" <> token,
        "-H",
        "Accept: application/json",
        "-G",
        "--data-urlencode",
        "jql=" <> jql,
        "--data-urlencode",
        "fields=summary,description,status,created,reporter,labels",
        "--data-urlencode",
        "expand=renderedFields",
        "--data-urlencode",
        "maxResults=100",
        base_url <> "/rest/api/3/search/jql",
      ],
      in: ".",
      opt: [],
    )
    |> result.map_error(fn(e) {
      let #(_, msg) = e
      "curl failed: " <> msg
    }),
  )

  let raw_file = "/tmp/jira-triage-raw.json"
  let filter_file = "/tmp/jira-triage-filter.jq"

  use _ <- result.try(
    simplifile.write(raw_file, raw_json)
    |> result.map_error(fn(_) { "Failed to write temp file" }),
  )
  use _ <- result.try(check_api_error(raw_file))
  use _ <- result.try(
    simplifile.write(filter_file, jq_filter())
    |> result.map_error(fn(_) { "Failed to write jq filter" }),
  )
  use processed <- result.try(
    shellout.command(
      run: "jq",
      with: ["-c", "-f", filter_file, raw_file],
      in: ".",
      opt: [],
    )
    |> result.map_error(fn(e) {
      let #(_, msg) = e
      "jq failed: " <> msg
    }),
  )

  parse_tickets(processed)
}

fn check_api_error(raw_file: String) -> Result(Nil, String) {
  case
    shellout.command(
      run: "jq",
      with: ["-e", ".issues", raw_file],
      in: ".",
      opt: [],
    )
  {
    Ok(_) -> Ok(Nil)
    Error(_) -> {
      let msg =
        shellout.command(
          run: "jq",
          with: [
            "-r",
            "(.errorMessages // [\"Unknown error\"])[0] // .message // \"Check your JIRA_API_TOKEN and JIRA_EMAIL\"",
            raw_file,
          ],
          in: ".",
          opt: [],
        )
      case msg {
        Ok(m) -> Error("Jira API error: " <> string.trim(m))
        Error(_) -> Error("Jira API error: check your credentials")
      }
    }
  }
}

fn jq_filter() -> String {
  "[(.issues // [])[] | {\n"
  <> "  key: .key,\n"
  <> "  summary: (.fields.summary // \"\"),\n"
  <> "  description: (\n"
  <> "    if .renderedFields != null and .renderedFields.description != null\n"
  <> "    then (.renderedFields.description | gsub(\"<[^>]*>\"; \" \") | .[0:500])\n"
  <> "    else \"\"\n"
  <> "    end\n"
  <> "  ),\n"
  <> "  status: (.fields.status.name // \"\"),\n"
  <> "  created: (.fields.created // \"\" | .[0:10]),\n"
  <> "  reporter_name: (.fields.reporter.displayName // \"\"),\n"
  <> "  reporter_tz: (.fields.reporter.timeZone // \"\"),\n"
  <> "  labels: (.fields.labels | join(\",\"))\n"
  <> "}]"
}

fn ticket_decoder() -> decode.Decoder(Ticket) {
  use key <- decode.field("key", decode.string)
  use summary <- decode.field("summary", decode.string)
  use description <- decode.field("description", decode.string)
  use status <- decode.field("status", decode.string)
  use created <- decode.field("created", decode.string)
  use reporter_name <- decode.field("reporter_name", decode.string)
  use reporter_tz <- decode.field("reporter_tz", decode.string)
  use labels <- decode.field("labels", decode.string)
  decode.success(Ticket(
    key:,
    summary:,
    description:,
    status:,
    created:,
    reporter_name:,
    reporter_tz:,
    labels:,
  ))
}

fn parse_tickets(json_str: String) -> Result(List(Ticket), String) {
  json.parse(json_str, decode.list(ticket_decoder()))
  |> result.map_error(fn(_) { "Failed to parse Jira response as JSON" })
}
