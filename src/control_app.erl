%%%-------------------------------------------------------------------
%% @doc control public API
%% @end
%%%-------------------------------------------------------------------

-module(control_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    application:start(log),   
    application:start(rd),    
    application:start(etcd),
    control_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
