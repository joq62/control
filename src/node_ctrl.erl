%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2023, c50
%%% @doc
%%% Data: Nodename,cookie, node, status(allocated,free,stopped)
%%% @end
%%% Created : 18 Apr 2023 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(node_ctrl).

-behaviour(gen_server).
%%--------------------------------------------------------------------
%% Include 
%%
%%--------------------------------------------------------------------

-include("log.api").
-include("node_record.hrl").
-include("control_config.hrl").


%% API
-export([
	 create_workers/0,
	 create_worker/2,
	 delete_worker/1
	]).

%% admin




-export([
	 kill/0,
	 ping/0,
	 stop/0
	]).

-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3, format_status/2]).

-define(SERVER, ?MODULE).
		     
-record(state, {
		worker_list,
		worker_info,
		num_workers,
		hostname,
		cookie_str

	       }).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Creates all the worers that are specified in the file InfraSpec.
%% worker is a running vm and a dir 
%% 
%% @end
%%--------------------------------------------------------------------
-spec  create_workers() -> {ok,ListOFWorkers :: term()} | 
	  {error, Error :: term()}.
create_workers() ->
    gen_server:call(?SERVER,{create_workers},infinity).

%%--------------------------------------------------------------------
%% @doc
%% Create a worker with a node name = NodeName and node dir=NodeDir. It's implict tha
%% the worker starts at current host and has the same cookie.
%% If the worker exists it will be killed and the dir will be deleted
%%  
%% @end
%%--------------------------------------------------------------------
-spec  create_worker(NodeName :: string(), NodeDir :: string()) -> {ok,Node :: node()} | 
	  {error, Error :: term()}.
create_worker(NodeName, NodeDir) ->
    gen_server:call(?SERVER,{create_worker,NodeName, NodeDir},infinity).

%%--------------------------------------------------------------------
%% @doc
%% Worker vm is stopped and worker dir is deleted
%%  
%% @end
%%--------------------------------------------------------------------
-spec  delete_worker(NodeName :: string()) -> {ok,Node :: node()} | 
	  {error, Error :: term()}.
delete_worker(NodeName) ->
    gen_server:call(?SERVER,{delete_worker,NodeName},infinity).

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
kill()->
    gen_server:call(?SERVER, {kill},infinity).


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


%stop()-> gen_server:cast(?SERVER, {stop}).
stop()-> gen_server:stop(?SERVER).

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
  
    {ok,HostName}=net:gethostname(),
    {ok,NumWorkers}=etcd_infra:get_num_workers(?InfraSpec,HostName),
    {ok,CookieStr}=etcd_infra:get_cookie_str(?InfraSpec),
    ListOfNodeInfo=lib_node_ctrl:create_node_info(NumWorkers,HostName,CookieStr),
    
  %  io:format("ListOfNodeInfo ~p~n",[{ListOfNodeInfo,?MODULE,?LINE}]),
    
     
    ?LOG_NOTICE("Server started ",[node()]),
    {ok, #state{
	    worker_list=[],
	    worker_info=ListOfNodeInfo,
	    num_workers=NumWorkers,
	    hostname=HostName,
	    cookie_str=CookieStr
	    
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





handle_call({create_workers}, _From, State) ->
    Result=lib_node_ctrl:create_workers(State#state.worker_info),
    NodeInfoToAdd=[{NodeName,NodeDir,Node,HostName,CookieStr}||{ok,NodeName,NodeDir,Node,HostName,CookieStr}<-Result],
    NewWorkerList=lists:usort(lists:append(NodeInfoToAdd,State#state.worker_list)),
    NewState=State#state{worker_list=NewWorkerList},
    Reply= Result,
    {reply, Reply, NewState};

handle_call({create_worker,NodeName,NodeDir}, _From, State) ->
    Node=list_to_atom(NodeName++"@"++State#state.hostname),    
    Reply=case lib_node_ctrl:create_worker(NodeName,NodeDir,Node,State#state.hostname,State#state.cookie_str) of
	      {error,Reason}->
		  NewState=State,
		  {error,Reason};
	      {ok,NodeName,NodeDir,Node,HostName,CookieStr}->
		  NewWorkerList=lists:usort([{NodeName,NodeDir,Node,HostName,CookieStr}|State#state.worker_list]),
		  NewState=State#state{worker_list=NewWorkerList},
		  {ok,NodeName,Node,NodeDir}
	  end,
    
    {reply, Reply, NewState};

handle_call({delete_worker,NodeName}, _From, State) ->
    Reply=case lists:keyfind(NodeName,1,State#state.worker_list) of
	      false->
		  NewState=State,
		  {error,["Nodename doesnt exists in worker_list",NodeName,State#state.worker_list]};
	      {NodeName,NodeDir,Node,HostName,CookieStr}->
		  
		  lib_node_ctrl:delete_worker(NodeDir,Node),
		  
		  NewWorkerList=lists:delete({NodeName,NodeDir,Node,HostName,CookieStr},State#state.worker_list),
		  NewState=State#state{worker_list=NewWorkerList},
		  ok
	  end,
    io:format("State ~p~n",[{State,?MODULE,?LINE}]),
    
    {reply, Reply, NewState};


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
handle_cast({stop}, State) ->
    
    {stop,normal,ok,State};

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

handle_info({nodedown,Node}, State) ->
    io:format("nodedown,Node  ~p~n",[{Node,?MODULE,?LINE}]),
    Result=case lists:keyfind(Node,3,State#state.worker_list) of
	       false->
		   NewState=State,
		   {error,["Node doesnt exist i worker_list ",Node,?MODULE,?LINE]};
	       {NodeName,NodeDir,Node,HostName,CookieStr}->
		   case lib_node_ctrl:create_worker(NodeName,NodeDir,Node,HostName,CookieStr) of
		       {error,Reason}->
			   NewState=State,
			   {error,Reason};
		       {ok,NodeName,NodeDir,Node,HostName,CookieStr}->
			   io:format("Restarted node  ~p~n",[{Node,?MODULE,?LINE}]),
			   NewWorkerList=lists:usort([{NodeName,NodeDir,Node,HostName,CookieStr}|State#state.worker_list]),
			   NewState=State#state{worker_list=NewWorkerList}
			       
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
