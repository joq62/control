%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2023, c50
%%% @doc
%%%
%%% @end
%%% Created : 23 Nov 2023 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(lib_appl_ctrl).

%% API
-export([
	load_appl/1,
	 unload_appl/3,
	 start_appl/2,
	 stop_appl/3
	]).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
load_appl(ApplSpec)->
     Result=case node_ctrl:allocate() of
	       {error,Reason}->
		   {error,[ApplSpec,Reason,?MODULE,?LINE]};
	       {ok,WorkerNode,WorkerDir}->
		    case etcd_application:get_app(ApplSpec) of
		       {error,Reason}->
			   {error,[ApplSpec,Reason]};
		       {ok,App}->
			   case etcd_application:get_git_path(ApplSpec) of
			       {error,Reason}->
				   {error,[ApplSpec,Reason]};
			       {ok,GitPath}->
				   case load(WorkerNode,WorkerDir,ApplSpec,App,GitPath) of
				       {error,Reason}->
					   {error,[ApplSpec,Reason]};
				       {ok,ApplicationDir}->
					   {ok,WorkerNode,WorkerDir,ApplicationDir,ApplSpec,App}
				   end
			   end
		   end
	   end,
    Result.

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
unload_appl(WorkerNode,ApplicationDir,App)->
    Result=case rpc:call(WorkerNode,application,unload,[App],5*5000) of
	       {badrpc,Reason}->
		   {error,["Failed to unload  Application on Node ",App,WorkerNode,Reason,?MODULE,?LINE]};
	       {error,Reason}->
		   {error,["Failed to unload Application on Node ",App,WorkerNode,Reason,?MODULE,?LINE]};
	       ok->
		   case rpc:call(WorkerNode,file,del_dir_r,[ApplicationDir],5000) of
		       {badrpc,Reason}->
			   {error,["Failed to delete ApplicationDir on Node ",ApplicationDir,App,WorkerNode,Reason,?MODULE,?LINE]};
		       {error,Reason}->
			   {error,["Failed to delete ApplicationDir on Node ",ApplicationDir,App,WorkerNode,Reason,?MODULE,?LINE]};
		       ok->
			   ok
		   end
	   end,
    Result.
   
%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
start_appl(WorkerNode,App)->
    Result=case rpc:call(WorkerNode,application,start,[App],5*5000) of
	       {badrpc,Reason}->
		   {error,["badrpc Failed to start Application on Node ",App,WorkerNode,Reason,?MODULE,?LINE]};
	       {error,Reason}->
		   {error,["Failed to start Application on Node ",App,WorkerNode,Reason,?MODULE,?LINE]};
	       ok->
		   ok
	   end,
    Result.

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
stop_appl(WorkerNode,ApplicationDir,App)->
    Result=case rpc:call(WorkerNode,application,stop,[App],5000) of
	       {badrpc,Reason}->
		   {error,["Failed to stop Application on Node ",App,WorkerNode,Reason,?MODULE,?LINE]};
	       {error,Reason}->
		   {error,["Failed to stop Application on Node ",App,WorkerNode,Reason,?MODULE,?LINE]};
	       ok->
		   Ebin=filename:join(ApplicationDir,"ebin"),
		   Priv=filename:join(ApplicationDir,"priv"),		   
		   rpc:call(WorkerNode,code,del_paths,[[Ebin,Priv]],5000)
	   end,
    Result.
			    


    
%%%===================================================================
%%% Internal functions
%%%===================================================================
%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
load(WorkerNode,WorkerDir,Application,App,GitPath)->
    %% Create dir for provider in IaasDir
    ApplicationDir=filename:join(WorkerDir,Application),
    rpc:call(WorkerNode,file,del_dir_r,[ApplicationDir],5000),
    Result=case  rpc:call(WorkerNode,file,make_dir,[ApplicationDir],5000) of
	       {badrpc,Reason}->
		   {error,[badrpc,Reason,?MODULE,?LINE]};
	       {error,Reason}->
		   {error,["Failed to create ApplicationDir ",ApplicationDir,?MODULE,?LINE,Reason]};
	       ok->
		   case rpc:call(node(),os,cmd,["git clone "++GitPath++" "++ApplicationDir],3*5000) of
		       {badrpc,Reason}->
			   {error,["Failed to git clone ",?MODULE,?LINE,Reason]};
		       _GitResult-> 
			   %% Add dir paths for erlang vm 
			   %% Ebin allways
			   Ebin=filename:join(ApplicationDir,"ebin"),
			   %% Check if a priv dir is a available to add into 
			   PrivDir=filename:join(ApplicationDir,"priv"),
			   AddPatha=case filelib:is_dir(PrivDir) of
					false->
					     [Ebin];
					true->
					     [Ebin,PrivDir]
				    end,
			   case rpc:call(WorkerNode,code,add_pathsa,[AddPatha],5000) of 
			       {error,bad_directory}->
				   {error,[" Failed to add Ebin path in node , bad_directory ",AddPatha,WorkerNode,?MODULE,?LINE]};
			        {badrpc,Reason}->
				   {error,["Failed to add path to Ebin dir ",Ebin,?MODULE,?LINE,Reason]};
			       ok->
				   case rpc:call(WorkerNode,application,load,[App],5000) of
				       {badrpc,Reason}->
					   {error,["Failed to load Application  ",App,?MODULE,?LINE,Reason]};
				       {error,Reason}->
					   {error,["Failed to load Application  ",App,?MODULE,?LINE,Reason]};
				       ok->
					   {ok,WorkerDir}
				   end
			   end
		   end
	   end,
    Result.
