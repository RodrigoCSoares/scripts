-module(cmd).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/cmd.gleam").
-export([run_silent/2, home_dir/0]).

-file("src/cmd.gleam", 4).
-spec run_silent(binary(), list(binary())) -> {ok, binary()} | {error, binary()}.
run_silent(Cmd, Args) ->
    case shellout:command(Cmd, Args, <<"."/utf8>>, []) of
        {ok, Output} ->
            {ok, Output};

        {error, {_, Msg}} ->
            {error, Msg}
    end.

-file("src/cmd.gleam", 11).
-spec home_dir() -> binary().
home_dir() ->
    case envoy_ffi:get(<<"HOME"/utf8>>) of
        {ok, Home} ->
            Home;

        {error, _} ->
            <<"/Users/rodrigo.soares"/utf8>>
    end.
