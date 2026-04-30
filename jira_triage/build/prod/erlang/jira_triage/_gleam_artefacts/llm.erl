-module(llm).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/llm.gleam").
-export([triage_ticket/1]).
-export_type([triage_result/0]).

-type triage_result() :: {triage_result, boolean(), binary()}.

-file("src/llm.gleam", 45).
-spec parse_response(binary()) -> triage_result().
parse_response(Response) ->
    Decoder = begin
        gleam@dynamic@decode:field(
            <<"ie"/utf8>>,
            {decoder, fun gleam@dynamic@decode:decode_bool/1},
            fun(Is_ie) ->
                gleam@dynamic@decode:field(
                    <<"reason"/utf8>>,
                    {decoder, fun gleam@dynamic@decode:decode_string/1},
                    fun(Reason) ->
                        gleam@dynamic@decode:success(
                            {triage_result, Is_ie, Reason}
                        )
                    end
                )
            end
        )
    end,
    case gleam@json:parse(Response, Decoder) of
        {ok, R} ->
            R;

        {error, _} ->
            Is_ie@1 = gleam_stdlib:contains_string(
                string:lowercase(Response),
                <<"\"ie\": true"/utf8>>
            ),
            {triage_result, Is_ie@1, gleam@string:slice(Response, 0, 120)}
    end.

-file("src/llm.gleam", 21).
-spec build_prompt(jira:ticket()) -> binary().
build_prompt(Ticket) ->
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"You are triaging Jira support tickets for the JustEat Ireland (IE) market team. "/utf8,
                                                                                    "Determine if this ticket is related to the IE (Ireland) market.\n\n"/utf8>>/binary,
                                                                                "Key: "/utf8>>/binary,
                                                                            (erlang:element(
                                                                                2,
                                                                                Ticket
                                                                            ))/binary>>/binary,
                                                                        "\nSummary: "/utf8>>/binary,
                                                                    (erlang:element(
                                                                        3,
                                                                        Ticket
                                                                    ))/binary>>/binary,
                                                                "\nStatus: "/utf8>>/binary,
                                                            (erlang:element(
                                                                5,
                                                                Ticket
                                                            ))/binary>>/binary,
                                                        "\nCreated: "/utf8>>/binary,
                                                    (erlang:element(6, Ticket))/binary>>/binary,
                                                "\nReporter: "/utf8>>/binary,
                                            (erlang:element(7, Ticket))/binary>>/binary,
                                        " (timezone: "/utf8>>/binary,
                                    (erlang:element(8, Ticket))/binary>>/binary,
                                ")\nLabels: "/utf8>>/binary,
                            (erlang:element(9, Ticket))/binary>>/binary,
                        "\nDescription: "/utf8>>/binary,
                    (erlang:element(4, Ticket))/binary>>/binary,
                "\n\nIE market signals: text says 'IE' or 'Ireland', Europe/Dublin timezone, IBAN + sort code (Irish banking), just-eat.ie, invoicing execution with IE listed.\n"/utf8>>/binary,
            "Non-IE signals: 'BTW' (Dutch VAT), 'Thuisbezorgd', '/nl/' in URLs, explicit DE/NL/BG/AT/UK/PL/SK/BE/ES/IT market mentions, 'p' or 'pence' (UK currency).\n\n"/utf8>>/binary,
        "Respond with a JSON object: {\"ie\": true or false, \"reason\": \"one sentence\"}"/utf8>>.

-file("src/llm.gleam", 60).
-spec call_ollama(binary()) -> {ok, binary()} | {error, binary()}.
call_ollama(Prompt) ->
    Body = begin
        _pipe = gleam@json:object(
            [{<<"model"/utf8>>, gleam@json:string(<<"llama3"/utf8>>)},
                {<<"prompt"/utf8>>, gleam@json:string(Prompt)},
                {<<"stream"/utf8>>, gleam@json:bool(false)},
                {<<"format"/utf8>>, gleam@json:string(<<"json"/utf8>>)},
                {<<"options"/utf8>>,
                    gleam@json:object(
                        [{<<"num_predict"/utf8>>, gleam@json:int(150)},
                            {<<"temperature"/utf8>>, gleam@json:float(0.1)}]
                    )}]
        ),
        gleam@json:to_string(_pipe)
    end,
    Req = begin
        _pipe@1 = gleam@http@request:new(),
        _pipe@2 = gleam@http@request:set_scheme(_pipe@1, http),
        _pipe@3 = gleam@http@request:set_method(_pipe@2, post),
        _pipe@4 = gleam@http@request:set_host(_pipe@3, <<"localhost"/utf8>>),
        _pipe@5 = gleam@http@request:set_port(_pipe@4, 11434),
        _pipe@6 = gleam@http@request:set_path(_pipe@5, <<"/api/generate"/utf8>>),
        _pipe@7 = gleam@http@request:set_body(_pipe@6, Body),
        gleam@http@request:prepend_header(
            _pipe@7,
            <<"content-type"/utf8>>,
            <<"application/json"/utf8>>
        )
    end,
    case gleam@httpc:send(Req) of
        {ok, Resp} ->
            case erlang:element(2, Resp) of
                200 ->
                    Decoder = begin
                        gleam@dynamic@decode:field(
                            <<"response"/utf8>>,
                            {decoder, fun gleam@dynamic@decode:decode_string/1},
                            fun(Text) -> gleam@dynamic@decode:success(Text) end
                        )
                    end,
                    _pipe@8 = gleam@json:parse(erlang:element(4, Resp), Decoder),
                    gleam@result:map_error(
                        _pipe@8,
                        fun(_) -> <<"Could not parse Ollama response"/utf8>> end
                    );

                Status ->
                    {error,
                        <<"Ollama returned status "/utf8,
                            (gleam@string:inspect(Status))/binary>>}
            end;

        {error, _} ->
            {error, <<"Ollama not available on localhost:11434"/utf8>>}
    end.

-file("src/llm.gleam", 14).
-spec triage_ticket(jira:ticket()) -> triage_result().
triage_ticket(Ticket) ->
    case call_ollama(build_prompt(Ticket)) of
        {ok, Response} ->
            parse_response(Response);

        {error, _} ->
            {triage_result,
                false,
                <<"Could not analyse (Ollama unavailable)"/utf8>>}
    end.
