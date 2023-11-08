%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2023, c50
%%% @doc
%%%
%%% @end
%%% Created : 15 Sep 2023 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(control_test).

%% API
-export([start/0]).
-define(DeploymentSpec,"test_c50").

-define(LocalResourceTuples,[]).
-define(TargetTypes,[adder,etcd,log,control]). 

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
    ok=test_kill(),
      
    io:format("Test OK !!! ~p~n",[?MODULE]),
    timer:sleep(2000),
 %   init:stop(),
    ok.

%%%===================================================================
%%% Internal functions
%%%===================================================================
%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
test_kill()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    L1=rd:fetch_resources(adder),
    io:format("L1 ~p~n",[{L1,?MODULE,?LINE}]),
    [{adder,Node1},_,_]=L1,
    io:format("Node1 ~p~n",[{Node1,?MODULE,?LINE}]),
    slave:stop(Node1),
    timer:sleep(5000),
    L2=rd:fetch_resources(adder),
    io:format("L2 ~p~n",[{L2,?MODULE,?LINE}]),
    [slave:stop(N)||{_,N}<-L2],
    timer:sleep(5000),
    L3=rd:fetch_resources(adder),
    io:format("L3 ~p~n",[{L3,?MODULE,?LINE}]),

    ok.
%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
test_0()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),

    [_,_]=rd:fetch_resources(adder),
    42=rd:call(adder,adder,add,[20,22],5000),
    42=rd:call(adder,add,[20,22],5000),
    {ok,Id1}=control:load_start("adder"),
    
    
    
    [_,_,_]=rd:fetch_resources(adder),

    pong=rd:call(control,ping,[],5000),
    pong=rd:call(etcd,ping,[],5000), 
    {error,[eexists_resources]}=rd:call(log,ping,[],5000),
 

    ok.
    

%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
test_1()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
  
  
    ok.
%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
test_2()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    
     
    ok.



%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
setup()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    
    pong=control:ping(),
    [rd:add_local_resource(ResourceType,Resource)||{ResourceType,Resource}<-?LocalResourceTuples],
    [rd:add_target_resource_type(TargetType)||TargetType<-?TargetTypes],
    rd:trade_resources(),
    timer:sleep(2000),
    ok.
   
