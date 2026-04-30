-module(cmd).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/cmd.gleam").
-export([run_silent/2, home_dir/0, fzf_select/2]).

-file("src/cmd.gleam", 5).
-spec run_silent(binary(), list(binary())) -> {ok, binary()} | {error, binary()}.
run_silent(Cmd, Args) ->
    case shellout:command(Cmd, Args, <<"."/utf8>>, []) of
        {ok, Output} ->
            {ok, Output};

        {error, {_, Msg}} ->
            {error, Msg}
    end.

-file("src/cmd.gleam", 12).
-spec home_dir() -> binary().
home_dir() ->
    case envoy_ffi:get(<<"HOME"/utf8>>) of
        {ok, Home} ->
            Home;

        {error, _} ->
            <<"/Users/rodrigo.soares"/utf8>>
    end.

-file("src/cmd.gleam", 19).
-spec fzf_select(binary(), binary()) -> {ok, binary()} | {error, binary()}.
fzf_select(Options, Prompt) ->
    Cmd = <<<<<<<<"printf '"/utf8, Options/binary>>/binary,
                "' | fzf --prompt='"/utf8>>/binary,
            Prompt/binary>>/binary,
        "' --height=6 --border"/utf8>>,
    case shellout:command(<<"sh"/utf8>>, [<<"-c"/utf8>>, Cmd], <<"."/utf8>>, []) of
        {ok, Selection} ->
            {ok, gleam@string:trim(Selection)};

        {error, {_, _}} ->
            {error, <<"fzf cancelled"/utf8>>}
    end.
