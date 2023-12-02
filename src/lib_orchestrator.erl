%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2023, c50
%%% @doc
%%%
%%% @end
%%% Created :  2 Dec 2023 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(lib_orchestrator).

-include("node.hrl").
%% API
-export([
	 create_workers/0,
	 load_start_infra/2
	 
	]).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% load and start infra appls
%% @end
%%--------------------------------------------------------------------
load_start_infra(InfraAppls,NodeInfoList)->
    {ok,[glurk]}.


%%--------------------------------------------------------------------
%% @doc
%% create workers
%% @end
%%--------------------------------------------------------------------
create_workers()->
    Result=case rpc:call(node(),node_ctrl,ping,[],5000) of
	       {badrpc,Reason}->
		   {error,["node_ctrl not available ",badrpc,Reason,?MODULE,?LINE]};
	       pong ->
		   case node_ctrl:node_info_list() of
		       []->
			   {error,["node_ctrl has not created NodeInfo list ",?MODULE,?LINE]};
		       NodeInfoList->
			   io:format("NodeInfoList ~p~n",[{NodeInfoList,?MODULE,?LINE}]),
			   StartResult=[node_ctrl:create_worker(N#node_info.nodename,N#node_info.worker_dir)||N<-NodeInfoList],
			   Error=[{error,Reason}||{error,Reason}<-StartResult],
			   case Error of
			       []->
				   OkStart=[NodeInfo||{ok,NodeInfo}<-StartResult],
				   case OkStart of
				       []->
					   {error,["No worker were created ",?MODULE,?LINE]};
				       OkStart->
					   {ok,OkStart}
				   end;
			       Error ->
				   {error,["Failed to start workers ",Error,?MODULE,?LINE]}
			   end
		   end
	   end,
    Result.
					  
%%%===================================================================
%%% Internal functions
%%%===================================================================
