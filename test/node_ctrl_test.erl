%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2023, c50
%%% @doc
%%%
%%% @end
%%% Created : 15 Sep 2023 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(node_ctrl_test).

-define(InfraSpec,"basic").
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

    Info=node_ctrl:create_workers(),
    io:format("Info ~p~n",[{Info,?MODULE,?FUNCTION_NAME}]),
    io:format("nodes ~p~n",[{nodes(),?MODULE,?FUNCTION_NAME}]),

    rpc:call('1_a@c50',init,stop,[],5000),
    
   
    ok.

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
test_0()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),

    NodeName="test_node_1", 
    NodeDir="test_node_1", 
    file:del_dir_r(NodeDir),
    {ok,"test_node_1",test_node_1@c50,"test_node_1"}=node_ctrl:create_worker(NodeName, NodeDir),
    true=filelib:is_dir(NodeDir),
    pong=net_adm:ping(test_node_1@c50),
    true=lists:member(test_node_1@c50,nodes()),
   
    rpc:call(test_node_1@c50,init,stop,[],5000),
    
    true=filelib:is_dir(NodeDir),
    pong=net_adm:ping(test_node_1@c50),
    true=lists:member(test_node_1@c50,nodes()),

    ok=node_ctrl:delete_worker(NodeName),
    false=filelib:is_dir(NodeDir),
    pang=net_adm:ping(test_node_1@c50),
    false=lists:member(test_node_1@c50,nodes()),
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
