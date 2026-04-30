{application, jira_triage, [
    {vsn, "1.0.0"},
    {applications, [envoy,
                    gleam_http,
                    gleam_httpc,
                    gleam_json,
                    gleam_stdlib,
                    shellout,
                    simplifile]},
    {description, ""},
    {modules, [cmd,
               jira,
               jira_triage,
               jira_triage@@main,
               llm]},
    {registered, []}
]}.
