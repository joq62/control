%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2023, c50
%%% @doc
%%%
%%% @end
%%% Created : 31 Jul 2023 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(lib_node_ctrl). 
-define(Iterations,100).
%% API
-export([
	 create_worker/5,
	 delete_worker/2,
	 create_workers/1,
	 create_node_info/3,
	 
	 is_node_started/1,
	 is_node_stopped/1

	 ]).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% creates worker directories and starts all workers on the host 
%% @end
%%--------------------------------------------------------------------
create_workers(ListOfNodeInfo)->
    CreateResult=[create_worker(NodeName,NodeDir,Node,HostName_1,CookieStr_1)||{NodeName,NodeDir,Node,HostName_1,CookieStr_1}<-ListOfNodeInfo],
    CreateResult.

%%--------------------------------------------------------------------
%% @doc
%% create worker directory and starts one  worker on the host 
%% @end
%%--------------------------------------------------------------------
create_worker(NodeName,NodeDir,Node,HostName,CookieStr)->
    delete_worker(NodeDir,Node),

    Result=case file:make_dir(NodeDir) of
	       {error,Reson}->
		   {error,["Failed to create a dir for ",NodeDir,Reson,?MODULE,?LINE]};
	       ok ->
		   ErlArgs=" -setcookie "++CookieStr,
		   case slave:start(HostName,NodeName,ErlArgs) of
		       {error,{already_running, Node}}->
			   {error,["Already running ",Node,NodeName,CookieStr,ErlArgs,?MODULE,?LINE]};
		       {error,Reason}->
			   {error,["Failed to start Node ",Reason,Node,NodeName,CookieStr,ErlArgs,?MODULE,?LINE]};
		       {ok,Node}->
			   erlang:monitor_node(Node,true),
			   {ok,NodeName,NodeDir,Node,HostName,CookieStr}
		   end
	   end,
    Result.


%%--------------------------------------------------------------------
%% @doc
%% create worker directory and starts one  worker on the host 
%% @end
%%--------------------------------------------------------------------
delete_worker(NodeDir,Node)->
    erlang:monitor_node(Node,false),
    file:del_dir_r(NodeDir),
    slave:stop(Node),
    ok.

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
create_node_info(NumWorkers,HostName,CookieStr)->
    create_node_info(NumWorkers,HostName,CookieStr,[]).

create_node_info(0,_HostName,_CookieStr,NodeInfo)->
    NodeInfo;
create_node_info(N,HostName,CookieStr,Acc) ->
    NStr=integer_to_list(N),						
    NodeName=NStr++"_"++CookieStr,
    NodeDir=NStr++"_"++CookieStr,
    Node=list_to_atom(NodeName++"@"++HostName),
    create_node_info(N-1,HostName,CookieStr,[{NodeName,NodeDir,Node,HostName,CookieStr}|Acc]).


					 
%%%===================================================================
%%% Internal functions
%%%===================================================================
%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
is_node_started(Node)->
    is_node_started(?Iterations,Node,false).

is_node_started(_N,_Node,true)->
    true;
is_node_started(0,_Node,Boolean) ->
    Boolean;
is_node_started(N,Node,_) ->
  %  io:format(" ~p~n",[{N,Node,erlang:get_cookie(),?MODULE,?LINE}]),
    Boolean=case net_adm:ping(Node) of
		pang->
		    timer:sleep(30),
		    false;
		pong->
		    true
	    end,
    is_node_started(N-1,Node,Boolean).

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
is_node_stopped(Node)->
    is_node_stopped(?Iterations,Node,false).

is_node_stopped(_N,_Node,true)->
    true;
is_node_stopped(0,_Node,Boolean) ->
    Boolean;
is_node_stopped(N,Node,_) ->
    Boolean=case net_adm:ping(Node) of
		pong->
		    timer:sleep(30),
		    false;
		pang->
		    true
	    end,
    is_node_stopped(N-1,Node,Boolean).
