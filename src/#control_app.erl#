%%%-------------------------------------------------------------------
%% @doc control public API
%% @end
%%%-------------------------------------------------------------------

-module(control_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    ok=application:start(log),   
    ok=application:start(rd),    
    ok=application:start(etcd),
    control_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
