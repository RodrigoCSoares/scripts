-module(jira_triage).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/jira_triage.gleam").
-export([main/0]).

-file("src/jira_triage.gleam", 93).
-spec hyperlink(binary(), binary()) -> binary().
hyperlink(Url, Text) ->
    <<<<<<<<"\x{1B}]8;;"/utf8, Url/binary>>/binary, "\x{1B}\\"/utf8>>/binary,
            Text/binary>>/binary,
        "\x{1B}]8;;\x{1B}\\"/utf8>>.

-file("src/jira_triage.gleam", 97).
-spec period_label(binary()) -> binary().
period_label(Period) ->
    case Period of
        <<"1d"/utf8>> ->
            <<"day"/utf8>>;

        <<"1w"/utf8>> ->
            <<"week"/utf8>>;

        <<"2w"/utf8>> ->
            <<"two weeks"/utf8>>;

        _ ->
            Period
    end.

-file("src/jira_triage.gleam", 18).
-spec run_triage(binary()) -> nil.
run_triage(Period) ->
    Project = case envoy_ffi:get(<<"JIRA_PROJECT"/utf8>>) of
        {ok, P} ->
            P;

        {error, _} ->
            <<"CPPI"/utf8>>
    end,
    gleam_stdlib:println(
        <<<<<<<<"\nFetching "/utf8, Project/binary>>/binary,
                    " tickets from the last "/utf8>>/binary,
                (period_label(Period))/binary>>/binary,
            "..."/utf8>>
    ),
    Base_url = case envoy_ffi:get(<<"JIRA_BASE_URL"/utf8>>) of
        {ok, Url} ->
            Url;

        {error, _} ->
            <<""/utf8>>
    end,
    case jira:fetch_tickets(Period) of
        {error, Msg} ->
            gleam_stdlib:println(<<"Error: "/utf8, Msg/binary>>);

        {ok, []} ->
            gleam_stdlib:println(<<"No tickets found."/utf8>>);

        {ok, Tickets} ->
            Total = erlang:length(Tickets),
            gleam_stdlib:println(
                <<<<"Found "/utf8, (erlang:integer_to_binary(Total))/binary>>/binary,
                    " tickets. Analysing with Ollama...\n"/utf8>>
            ),
            Divider = gleam@string:repeat(<<"-"/utf8>>, 80),
            gleam_stdlib:println(Divider),
            Ie_count = gleam@list:fold(
                Tickets,
                0,
                fun(Count, Ticket) ->
                    Result = llm:triage_ticket(Ticket),
                    Marker = case erlang:element(2, Result) of
                        true ->
                            <<"[IE]"/utf8>>;

                        false ->
                            <<"[--]"/utf8>>
                    end,
                    Url@1 = <<<<Base_url/binary, "/browse/"/utf8>>/binary,
                        (erlang:element(2, Ticket))/binary>>,
                    Linked_key = hyperlink(
                        Url@1,
                        gleam@string:pad_end(
                            erlang:element(2, Ticket),
                            13,
                            <<" "/utf8>>
                        )
                    ),
                    gleam_stdlib:println(
                        <<<<<<<<<<<<Linked_key/binary, "  "/utf8>>/binary,
                                            Marker/binary>>/binary,
                                        "  "/utf8>>/binary,
                                    (erlang:element(6, Ticket))/binary>>/binary,
                                "  "/utf8>>/binary,
                            (gleam@string:slice(
                                erlang:element(3, Ticket),
                                0,
                                44
                            ))/binary>>
                    ),
                    gleam_stdlib:println(
                        <<<<(gleam@string:repeat(<<" "/utf8>>, 17))/binary,
                                (gleam@string:pad_end(
                                    erlang:element(5, Ticket),
                                    24,
                                    <<" "/utf8>>
                                ))/binary>>/binary,
                            (erlang:element(3, Result))/binary>>
                    ),
                    gleam_stdlib:println(<<""/utf8>>),
                    case erlang:element(2, Result) of
                        true ->
                            Count + 1;

                        false ->
                            Count
                    end
                end
            ),
            gleam_stdlib:println(Divider),
            gleam_stdlib:println(
                <<<<<<<<"IE: "/utf8,
                                (erlang:integer_to_binary(Ie_count))/binary>>/binary,
                            " / "/utf8>>/binary,
                        (erlang:integer_to_binary(Total))/binary>>/binary,
                    " tickets"/utf8>>
            )
    end.

-file("src/jira_triage.gleam", 9).
-spec main() -> nil.
main() ->
    gleam_stdlib:println(<<"=== Jira IE Triage ===\n"/utf8>>),
    case envoy_ffi:get(<<"JIRA_TRIAGE_PERIOD"/utf8>>) of
        {error, _} ->
            gleam_stdlib:println(<<"No period selected."/utf8>>);

        {ok, Period} ->
            run_triage(Period)
    end.
