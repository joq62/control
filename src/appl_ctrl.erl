%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2023, c50
%%% @doc
%%%
%%% @end
%%% Created : 18 Apr 2023 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(appl_ctrl).
 
-behaviour(gen_server).
%%--------------------------------------------------------------------
%% Include 
%%
%%--------------------------------------------------------------------

-include("log.api").
 

%% API

-export([
	 load_appl/1,
	 start_appl/1,
	 stop_appl/1,
	 unload_appl/1,
	 loaded_appls/0,
	 running_appls/0,
	 is_alive/2,

	 ping/0,
	 stop/0
	]).

-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3, format_status/2]).

-define(SERVER, ?MODULE).

% Data
% deployed_appl {DeploymentId,App,AppDir, WorkerNode}
-record(state, {
		monitored_nodes,
		deployed_appl
		
	       }).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% load application   
%% @end
%%--------------------------------------------------------------------
-spec load_appl(ApplSpec :: string()) -> ok | {error, Error :: term()}.
load_appl(ApplSpec)->
    gen_server:call(?SERVER, {load_appl,ApplSpec},infinity).
%%--------------------------------------------------------------------
%% @doc
%%  application   
%% @end
%%--------------------------------------------------------------------
-spec start_appl(DeploymentId :: integer()) -> ok | {error, Error :: term()}.
start_appl(DeploymentId)->
    gen_server:call(?SERVER, {start_appl,DeploymentId},infinity).

%%--------------------------------------------------------------------
%% @doc
%%  application   
%% @end
%%--------------------------------------------------------------------
-spec stop_appl(DeploymentId :: integer()) -> ok | {error, Error :: term()}.
stop_appl(DeploymentId)->
    gen_server:call(?SERVER, {stop_appl,DeploymentId},infinity).

%%--------------------------------------------------------------------
%% @doc
%%  application   
%% @end
%%--------------------------------------------------------------------
-spec unload_appl(DeploymentId :: term()) -> ok | {error, Error :: term()}.
unload_appl(DeploymentId)->
    gen_server:call(?SERVER, {unload_appl,DeploymentId},infinity).

%%--------------------------------------------------------------------
%% @doc
%% Get all information related to host HostName  
%% @end
%%--------------------------------------------------------------------
-spec loaded_appls() -> ListOfAppls :: term().

loaded_appls()->
    gen_server:call(?SERVER, {loaded_appls},infinity).

%%--------------------------------------------------------------------
%% @doc
%% Get all information related to host HostName  
%% @end
%%--------------------------------------------------------------------
-spec running_appls() -> ListOfAppls :: term().

running_appls()->
    gen_server:call(?SERVER, {running_appls},infinity).

%%--------------------------------------------------------------------
%% @doc
%% Get all information related to host HostName  
%% @end
%%--------------------------------------------------------------------
-spec is_alive(App :: atom(),WorkerNode :: node()) -> IsDeployed :: boolean() | {error, Error :: term()}.

is_alive(App,WorkerNode)->
    gen_server:call(?SERVER, {is_alive,App,WorkerNode},infinity).


%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
-spec ping() -> pong | Error::term().
ping()-> 
    gen_server:call(?SERVER, {ping},infinity).
%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%% @end
%%--------------------------------------------------------------------
-spec start_link() -> {ok, Pid :: pid()} |
	  {error, Error :: {already_started, pid()}} |
	  {error, Error :: term()} |
	  ignore.
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).


stop()-> gen_server:call(?SERVER, {stop},infinity).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%% @end
%%--------------------------------------------------------------------
-spec init(Args :: term()) -> {ok, State :: term()} |
	  {ok, State :: term(), Timeout :: timeout()} |
	  {ok, State :: term(), hibernate} |
	  {stop, Reason :: term()} |
	  ignore.

init([]) ->
    
    
    ?LOG_NOTICE("Server started ",[]),
    {ok, #state{
	    monitored_nodes=[],
	    deployed_appl=[]
	   }}.


%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%% @end
%%--------------------------------------------------------------------
-spec handle_call(Request :: term(), From :: {pid(), term()}, State :: term()) ->
	  {reply, Reply :: term(), NewState :: term()} |
	  {reply, Reply :: term(), NewState :: term(), Timeout :: timeout()} |
	  {reply, Reply :: term(), NewState :: term(), hibernate} |
	  {noreply, NewState :: term()} |
	  {noreply, NewState :: term(), Timeout :: timeout()} |
	  {noreply, NewState :: term(), hibernate} |
	  {stop, Reason :: term(), Reply :: term(), NewState :: term()} |
	  {stop, Reason :: term(), NewState :: term()}.


handle_call({load_appl,ApplSpec}, _From, State) ->
    Reply=case lib_appl_ctrl:load_appl(ApplSpec) of
	      {error,Reason}->
		  NewState=State,
		  {error,Reason};
	      {ok,DeploymentId,WorkerNode,WorkerDir,ApplicationDir,ApplSpec,App}->
		  NewState=State#state{deployed_appl=[{DeploymentId,WorkerNode,WorkerDir,ApplicationDir,ApplSpec,App}|State#state.deployed_appl]},
		  {ok,DeploymentId}
	  end,
    {reply, Reply, NewState};

handle_call({start_appl,DeploymentId}, _From, State) ->
    Reply=case lists:keyfind(DeploymentId,1,State#state.deployed_appl) of
	      false->
		  {error,["DeployedId doesnt exists",DeploymentId,?MODULE,?LINE]};
	      {_DeploymentId,WorkerNode,_WorkerDir,ApplicationDir,_ApplSpec,App}->
		  case lib_appl_ctrl:start_appl(WorkerNode,App) of
		      {error,Reason}->
			  {error,Reason};
		      ok->
			  {ok,WorkerNode}
		  end
	  end,
    {reply, Reply, State};

handle_call({stop_appl,DeploymentId}, _From, State) ->
    Reply=case lists:keyfind(DeploymentId,1,State#state.deployed_appl) of
	      false->
		  {error,["DeployedId doesnt exists",DeploymentId,?MODULE,?LINE]};
	      {_DeploymentId,WorkerNode,_WorkerDir,ApplicationDir,_ApplSpec,App}->
		  case lib_appl_ctrl:stop_appl(App,ApplicationDir, WorkerNode) of
		      {error,Reason}->
			  {error,Reason};
		      ok->
			  ok
		  end
	  end,
    {reply, Reply,State};

handle_call({unload_appl,DeploymentId}, _From, State) ->
    Reply=case lists:keyfind(DeploymentId,1,State#state.deployed_appl) of
	      false->
		  NewState=State,
		  {error,["DeployedId doesnt exists",DeploymentId,?MODULE,?LINE]};
	      {DeploymentId,WorkerNode,WorkerDir,ApplicationDir,ApplSpec,App}->
		  case lib_appl_ctrl:unload_appl(ApplicationDir) of
		      {error,Reason}->
			  NewState=State,
			  {error,Reason};
		      ok->
			  NewState=State#state{deployed_appl=lists:delete({DeploymentId,WorkerNode,WorkerDir,ApplicationDir,ApplSpec,App},State#state.deployed_appl)},
			  ok
		  end
	  end,
    {reply, Reply, NewState};


handle_call({loaded_appls}, _From, State) ->
    Reply=[{App,WorkerNode}||{DeploymentId,WorkerNode,WorkerDir,ApplicationDir,ApplSpec,App}<-State#state.deployed_appl],
    {reply, Reply, State};

handle_call({running_appls}, _From, State) ->
    Reply={error,not_implemented},
    {reply, Reply, State};

handle_call({is_alive,App,WorkerNode}, _From, State) ->
    Reply=case rpc:call(WorkerNode,App,ping,[],5000) of
	      {badrpc,Reason}->
		  false;
	      pong->
		  true;
	      _->
		  false
	  end,
    {reply, Reply, State};

handle_call({ping}, _From, State) ->
    Reply=pong,
    {reply, Reply, State};

handle_call(UnMatchedSignal, From, State) ->
    io:format("unmatched_signal ~p~n",[{UnMatchedSignal, From,?MODULE,?LINE}]),
    Reply = {error,[unmatched_signal,UnMatchedSignal, From]},
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%% @end
%%--------------------------------------------------------------------
handle_cast(UnMatchedSignal, State) ->
    io:format("unmatched_signal ~p~n",[{UnMatchedSignal,?MODULE,?LINE}]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%% @end
%%--------------------------------------------------------------------
-spec handle_info(Info :: timeout() | term(), State :: term()) ->
	  {noreply, NewState :: term()} |
	  {noreply, NewState :: term(), Timeout :: timeout()} |
	  {noreply, NewState :: term(), hibernate} |
	  {stop, Reason :: normal | term(), NewState :: term()}.

%% Monitored Node down
%% Stop monitoring that node 
%% Remove from  State#state.monitored_nodes
%% Get the deployment on that node 
%% Remove Deployment from deployment list
%% 

handle_info({nodedown,WorkerNode}, State) ->
    io:format("nodedown ~p~n",[{WorkerNode,?MODULE,?LINE}]),
    erlang:monitor_node(WorkerNode,false),
    case lists:keyfind(WorkerNode,2,State#state.deployed_appl) of
	false->
	    io:format("error ~p~n",[{"eexists WorkerNode ",WorkerNode,?MODULE,?LINE}]),
	    NewState=State#state{monitored_nodes=lists:delete(WorkerNode,State#state.monitored_nodes)},
	    {error,["eexists WorkerNode ",WorkerNode,?MODULE,?LINE]};
	{DeploymentId,WorkerNode,WorkerDir,ApplicationDir,ApplSpec,App}->
	    io:format("ok  ~p~n",[{?MODULE,?LINE}]),
	    L1=lists:delete({DeploymentId,WorkerNode,WorkerDir,ApplicationDir,ApplSpec,App},State#state.deployed_appl),
	    case lib_appl_ctrl:load_appl(ApplSpec) of
		{error,Reason}->
		    io:format("error  ~p~n",[{Reason,?MODULE,?LINE}]),
		    NewState=State#state{deployed_appl=L1,
					 monitored_nodes=lists:delete(WorkerNode,State#state.monitored_nodes)};
		{ok,NewDeploymentId,NewWorkerNode,NewWorkerDir,ApplicationDir,ApplSpec,App}->
		    case lib_appl_ctrl:start_appl(WorkerNode,App) of
			{error,Reason}->
			    io:format("error  ~p~n",[{Reason,?MODULE,?LINE}]),
			    NewState=State#state{deployed_appl=L1,
						 monitored_nodes=lists:delete(WorkerNode,State#state.monitored_nodes)};
			ok->
			    io:format("NewDeploymentId,NewWorkerNode,NewWorkerDir,ApplicationDir,ApplSpec,App ~p~n",[{NewDeploymentId,NewWorkerNode,NewWorkerDir,ApplicationDir,ApplSpec,App,?MODULE,?LINE}]),
			    erlang:monitor_node(NewWorkerNode,true),
			    NodesToMonitor=lists:usort([NewWorkerNode|State#state.monitored_nodes]),		  
			    NewState=State#state{deployed_appl=[{NewDeploymentId,NewWorkerNode,NewWorkerDir,ApplicationDir,ApplSpec,App}|L1],
						 monitored_nodes=NodesToMonitor}
		    end
	    end
    end,
    {noreply, NewState};

handle_info(Info, State) ->
    io:format("unmatched_signal ~p~n",[{Info,?MODULE,?LINE}]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%% @end
%%--------------------------------------------------------------------
-spec terminate(Reason :: normal | shutdown | {shutdown, term()} | term(),
		State :: term()) -> any().
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%% @end
%%--------------------------------------------------------------------
-spec code_change(OldVsn :: term() | {down, term()},
		  State :: term(),
		  Extra :: term()) -> {ok, NewState :: term()} |
	  {error, Reason :: term()}.
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called for changing the form and appearance
%% of gen_server status when it is returned from sys:get_status/1,2
%% or when it appears in termination error logs.
%% @end
%%--------------------------------------------------------------------
-spec format_status(Opt :: normal | terminate,
		    Status :: list()) -> Status :: term().
format_status(_Opt, Status) ->
    Status.

%%%===================================================================
%%% Internal functions
%%%===================================================================
