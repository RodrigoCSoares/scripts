-module(jira).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/jira.gleam").
-export([fetch_tickets/1]).
-export_type([ticket/0]).

-type ticket() :: {ticket,
        binary(),
        binary(),
        binary(),
        binary(),
        binary(),
        binary(),
        binary(),
        binary()}.

-file("src/jira.gleam", 120).
-spec ticket_decoder() -> gleam@dynamic@decode:decoder(ticket()).
ticket_decoder() ->
    gleam@dynamic@decode:field(
        <<"key"/utf8>>,
        {decoder, fun gleam@dynamic@decode:decode_string/1},
        fun(Key) ->
            gleam@dynamic@decode:field(
                <<"summary"/utf8>>,
                {decoder, fun gleam@dynamic@decode:decode_string/1},
                fun(Summary) ->
                    gleam@dynamic@decode:field(
                        <<"description"/utf8>>,
                        {decoder, fun gleam@dynamic@decode:decode_string/1},
                        fun(Description) ->
                            gleam@dynamic@decode:field(
                                <<"status"/utf8>>,
                                {decoder,
                                    fun gleam@dynamic@decode:decode_string/1},
                                fun(Status) ->
                                    gleam@dynamic@decode:field(
                                        <<"created"/utf8>>,
                                        {decoder,
                                            fun gleam@dynamic@decode:decode_string/1},
                                        fun(Created) ->
                                            gleam@dynamic@decode:field(
                                                <<"reporter_name"/utf8>>,
                                                {decoder,
                                                    fun gleam@dynamic@decode:decode_string/1},
                                                fun(Reporter_name) ->
                                                    gleam@dynamic@decode:field(
                                                        <<"reporter_tz"/utf8>>,
                                                        {decoder,
                                                            fun gleam@dynamic@decode:decode_string/1},
                                                        fun(Reporter_tz) ->
                                                            gleam@dynamic@decode:field(
                                                                <<"labels"/utf8>>,
                                                                {decoder,
                                                                    fun gleam@dynamic@decode:decode_string/1},
                                                                fun(Labels) ->
                                                                    gleam@dynamic@decode:success(
                                                                        {ticket,
                                                                            Key,
                                                                            Summary,
                                                                            Description,
                                                                            Status,
                                                                            Created,
                                                                            Reporter_name,
                                                                            Reporter_tz,
                                                                            Labels}
                                                                    )
                                                                end
                                                            )
                                                        end
                                                    )
                                                end
                                            )
                                        end
                                    )
                                end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/jira.gleam", 141).
-spec parse_tickets(binary()) -> {ok, list(ticket())} | {error, binary()}.
parse_tickets(Json_str) ->
    _pipe = gleam@json:parse(
        Json_str,
        gleam@dynamic@decode:list(ticket_decoder())
    ),
    gleam@result:map_error(
        _pipe,
        fun(_) -> <<"Failed to parse Jira response as JSON"/utf8>> end
    ).

-file("src/jira.gleam", 102).
-spec jq_filter() -> binary().
jq_filter() ->
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<"[.issues[] | {\n"/utf8, "  key: .key,\n"/utf8>>/binary,
                                                        "  summary: (.fields.summary // \"\"),\n"/utf8>>/binary,
                                                    "  description: (\n"/utf8>>/binary,
                                                "    if .renderedFields != null and .renderedFields.description != null\n"/utf8>>/binary,
                                            "    then (.renderedFields.description | gsub(\"<[^>]*>\"; \" \") | .[0:500])\n"/utf8>>/binary,
                                        "    else \"\"\n"/utf8>>/binary,
                                    "    end\n"/utf8>>/binary,
                                "  ),\n"/utf8>>/binary,
                            "  status: (.fields.status.name // \"\"),\n"/utf8>>/binary,
                        "  created: (.fields.created // \"\" | .[0:10]),\n"/utf8>>/binary,
                    "  reporter_name: (.fields.reporter.displayName // \"\"),\n"/utf8>>/binary,
                "  reporter_tz: (.fields.reporter.timeZone // \"\"),\n"/utf8>>/binary,
            "  labels: (.fields.labels | join(\",\"))\n"/utf8>>/binary,
        "}]"/utf8>>.

-file("src/jira.gleam", 21).
-spec fetch_tickets(binary()) -> {ok, list(ticket())} | {error, binary()}.
fetch_tickets(Period) ->
    gleam@result:'try'(
        begin
            _pipe = envoy_ffi:get(<<"JIRA_EMAIL"/utf8>>),
            gleam@result:replace_error(
                _pipe,
                <<"JIRA_EMAIL environment variable not set"/utf8>>
            )
        end,
        fun(Email) ->
            gleam@result:'try'(
                begin
                    _pipe@1 = envoy_ffi:get(<<"JIRA_API_TOKEN"/utf8>>),
                    gleam@result:replace_error(
                        _pipe@1,
                        <<"JIRA_API_TOKEN environment variable not set"/utf8>>
                    )
                end,
                fun(Token) ->
                    gleam@result:'try'(
                        begin
                            _pipe@2 = envoy_ffi:get(<<"JIRA_BASE_URL"/utf8>>),
                            gleam@result:replace_error(
                                _pipe@2,
                                <<"JIRA_BASE_URL environment variable not set"/utf8>>
                            )
                        end,
                        fun(Base_url) ->
                            gleam@result:'try'(
                                begin
                                    _pipe@3 = envoy_ffi:get(
                                        <<"JIRA_PROJECT"/utf8>>
                                    ),
                                    gleam@result:replace_error(
                                        _pipe@3,
                                        <<"JIRA_PROJECT environment variable not set"/utf8>>
                                    )
                                end,
                                fun(Project) ->
                                    Jql = <<<<<<<<"project = "/utf8,
                                                    Project/binary>>/binary,
                                                " AND created >= -"/utf8>>/binary,
                                            Period/binary>>/binary,
                                        " ORDER BY created DESC"/utf8>>,
                                    gleam@result:'try'(
                                        begin
                                            _pipe@4 = shellout:command(
                                                <<"curl"/utf8>>,
                                                [<<"-s"/utf8>>,
                                                    <<"-u"/utf8>>,
                                                    <<<<Email/binary, ":"/utf8>>/binary,
                                                        Token/binary>>,
                                                    <<"-H"/utf8>>,
                                                    <<"Accept: application/json"/utf8>>,
                                                    <<"-G"/utf8>>,
                                                    <<"--data-urlencode"/utf8>>,
                                                    <<"jql="/utf8, Jql/binary>>,
                                                    <<"--data-urlencode"/utf8>>,
                                                    <<"fields=summary,description,status,created,reporter,labels"/utf8>>,
                                                    <<"--data-urlencode"/utf8>>,
                                                    <<"expand=renderedFields"/utf8>>,
                                                    <<"--data-urlencode"/utf8>>,
                                                    <<"maxResults=100"/utf8>>,
                                                    <<Base_url/binary,
                                                        "/rest/api/3/search"/utf8>>],
                                                <<"."/utf8>>,
                                                []
                                            ),
                                            gleam@result:map_error(
                                                _pipe@4,
                                                fun(E) ->
                                                    {_, Msg} = E,
                                                    <<"curl failed: "/utf8,
                                                        Msg/binary>>
                                                end
                                            )
                                        end,
                                        fun(Raw_json) ->
                                            Raw_file = <<"/tmp/jira-triage-raw.json"/utf8>>,
                                            Filter_file = <<"/tmp/jira-triage-filter.jq"/utf8>>,
                                            gleam@result:'try'(
                                                begin
                                                    _pipe@5 = simplifile:write(
                                                        Raw_file,
                                                        Raw_json
                                                    ),
                                                    gleam@result:map_error(
                                                        _pipe@5,
                                                        fun(_) ->
                                                            <<"Failed to write temp file"/utf8>>
                                                        end
                                                    )
                                                end,
                                                fun(_) ->
                                                    gleam@result:'try'(
                                                        begin
                                                            _pipe@6 = simplifile:write(
                                                                Filter_file,
                                                                jq_filter()
                                                            ),
                                                            gleam@result:map_error(
                                                                _pipe@6,
                                                                fun(_) ->
                                                                    <<"Failed to write jq filter"/utf8>>
                                                                end
                                                            )
                                                        end,
                                                        fun(_) ->
                                                            gleam@result:'try'(
                                                                begin
                                                                    _pipe@7 = shellout:command(
                                                                        <<"jq"/utf8>>,
                                                                        [<<"-c"/utf8>>,
                                                                            <<"-f"/utf8>>,
                                                                            Filter_file,
                                                                            Raw_file],
                                                                        <<"."/utf8>>,
                                                                        []
                                                                    ),
                                                                    gleam@result:map_error(
                                                                        _pipe@7,
                                                                        fun(E@1) ->
                                                                            {_,
                                                                                Msg@1} = E@1,
                                                                            <<"jq failed: "/utf8,
                                                                                Msg@1/binary>>
                                                                        end
                                                                    )
                                                                end,
                                                                fun(Processed) ->
                                                                    parse_tickets(
                                                                        Processed
                                                                    )
                                                                end
                                                            )
                                                        end
                                                    )
                                                end
                                            )
                                        end
                                    )
                                end
                            )
                        end
                    )
                end
            )
        end
    ).
