%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2023, c50
%%% @doc
%%%
%%% @end
%%% Created : 15 Sep 2023 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(node_ctrl_test).

-include("node.hrl").
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
test_0()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),

    NodeName="test_node_1", 
    NodeDir="test_node_1", 
    file:del_dir_r(NodeDir),
    {ok,Nir}=node_ctrl:create_worker(NodeName, NodeDir),
    true=filelib:is_dir(NodeDir),
    pong=net_adm:ping(Nir#node_info.worker_node),
    true=lists:member(Nir#node_info.worker_node,nodes()),
   
    slave:stop(Nir#node_info.worker_node),
    timer:sleep(1000),

    true=filelib:is_dir(Nir#node_info.worker_dir),
    pong=net_adm:ping(Nir#node_info.worker_node),
    true=lists:member(Nir#node_info.worker_node,nodes()),

    ok=node_ctrl:delete_worker(Nir),
    false=filelib:is_dir(Nir#node_info.worker_node),
    pang=net_adm:ping(Nir#node_info.worker_node),
    false=lists:member(Nir#node_info.worker_node,nodes()),
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
