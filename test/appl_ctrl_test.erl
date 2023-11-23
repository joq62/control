%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2023, c50
%%% @doc
%%%
%%% @end
%%% Created : 15 Sep 2023 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(appl_ctrl_test).

-define(TestAppl,"adder").
%% API
-export([start/0]).


%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
start()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
  
    ok=setup(),
    ok=test_0(),
    ok=test_1(),

    io:format("Test OK !!! ~p~n",[?MODULE]),
    timer:sleep(2000),
%    init:stop(),
    ok.

%%%===================================================================
%%% Internal functions
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
test_1()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),

    ok.

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
test_0()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),

    io:format("nodes() ~p~n",[{nodes(),?MODULE,?FUNCTION_NAME}]),

    %% infra appl
    {ok,DeploymentId}=appl_ctrl:load_appl("resource_discovery"),
    {ok,WorkerNode}=appl_ctrl:start_appl(DeploymentId),

    {ok,DeploymentId}=appl_ctrl:load_appl("adder",DeploymentId),
    {ok,WorkerNode}=appl_ctrl:start_appl(DeploymentId),

    
    
    
    ok.


%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
setup()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    pong=node_ctrl:ping(),
   
    ok.
