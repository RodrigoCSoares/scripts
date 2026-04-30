{application, jira_triage, [
    {vsn, "1.0.0"},
    {applications, [envoy,
                    gleam_http,
                    gleam_httpc,
                    gleam_json,
                    gleam_stdlib,
                    gleeunit,
                    shellout,
                    simplifile]},
    {description, ""},
    {modules, [jira,
               jira_triage,
               llm]},
    {registered, []}
]}.
