%% The MIT License
%%
%% Copyright (c) 2013 alisdair sullivan <alisdairsullivan@yahoo.ca>
%%
%% Permission is hereby granted, free of charge, to any person obtaining a copy
%% of this software and associated documentation files (the "Software"), to deal
%% in the Software without restriction, including without limitation the rights
%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the Software is
%% furnished to do so, subject to the following conditions:
%%
%% The above copyright notice and this permission notice shall be included in
%% all copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%% THE SOFTWARE.


-module(redactor).


%% otp callbacks
-export([start/2, start/0, stop/1, init/1, terminate/2]).
-export([redactor_profiles/0]).
%% bash script entry point
-export([red/0]).


%% application machinery
start() -> application:start(redactor).

start(_Type, _Args) -> redactor_supervisor().

stop(_State) -> ok.

%% application internals
redactor_supervisor() -> supervisor:start_link(redactor, {supervisor, []}).

redactor_profiles() ->
    gen_server:start_link({local, redactor_profiles}, redactor, {redactor_profiles, []}, []).

%% don't do this
init({supervisor, _Args}) ->
    {ok, {
        {one_for_one, 1, 5},
        [{profiles, {?MODULE, redactor_profiles, []}, permanent, brutal_kill, worker, [?MODULE]}]
    }};
init({redactor_profiles, _Args}) ->
    {ok, gb_trees:empty()}.

terminate(_, _) -> ok.


%% let's not get crazy! for now just print out the args to `red' and halt
red() -> io:format("~p~n", [init:get_plain_arguments()]), halt(0).



-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

tty(OnOff) -> error_logger:tty(OnOff).


application_start_test_() ->
    {setup, fun() -> tty(false) end, fun(_) -> application:stop(redactor), tty(true) end, [
        {"application starts cleanly", ?_assertEqual(ok, application:start(redactor))}
    ]}.

application_stop_test_() ->
    {setup, fun() -> tty(false), application:start(redactor) end, fun(_) -> tty(true) end, [
        {"application stops cleanly", ?_assertEqual(ok, application:stop(redactor))}
    ]}.

-endif.