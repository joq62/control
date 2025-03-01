%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2024, c50
%%% @doc
%%% Control is securing that the host is reaching wanted state
%%% Supports the developer and operator with cluster/node/application status
%%% @end
%%% Created : 21 Dec 2024 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(control). 

-behaviour(gen_server).


-include("log.api").
%% API

-export([
	 is_wanted_state/0,

	 update/0
	]).

-export([
	 ping/0,
	 start_link/0
	]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3, format_status/2]).

-define(SERVER, ?MODULE).
-define(LoopTime,30*1000).

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
-spec is_wanted_state() -> {ok,WantedState::boolean(),[MissingApplication::string()]}.
is_wanted_state() ->
    gen_server:call(?SERVER,{is_wanted_state},infinity).


%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
-spec update() -> ok.
update()-> 
    gen_server:cast(?SERVER, {update}).

%%--------------------------------------------------------------------
%% @doc
%% Ping
%% @end
%%--------------------------------------------------------------------
-spec ping() -> pong.
ping() ->
    gen_server:call(?SERVER,{ping},infinity).

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
    process_flag(trap_exit, true),
    
    
    {ok, #state{}}.

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



handle_call({is_wanted_state}, _From, State) ->
    Reply = lib_control_server:is_wanted_state(),
    {reply, Reply, State};


handle_call({ping}, _From, State) ->
    Reply = pong,
    {reply, Reply, State};

handle_call(Request, _From, State) ->
    Reply = {error,["Unmatched signal ",Request]},
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%% @end
%%--------------------------------------------------------------------
-spec handle_cast(Request :: term(), State :: term()) ->
	  {noreply, NewState :: term()} |
	  {noreply, NewState :: term(), Timeout :: timeout()} |
	  {noreply, NewState :: term(), hibernate} |
	  {stop, Reason :: term(), NewState :: term()}.

handle_cast({update}, State) ->
    R=case rpc:call(node(),lib_control_server,update,[],?LoopTime-1000) of
	  {badrpc,timeout}->
	      ?LOG_WARNING("badrpc Timeout when updating ",[]),
	      {badrpc,timeout};
	  {badrpc,Reason}->
	      ?LOG_WARNING("badrpc Reason when updating ",[Reason]),
	      {badrpc,Reason};
	  ok->
	      ok;
	  {ok,UpdateInfo}->
	      ?LOG_NOTICE("Update info ",[UpdateInfo]),
	      {ok,UpdateInfo}
      end,
    spawn(fun()->update_loop() end),
    {noreply, State};

handle_cast(_Request, State) ->
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
%%--------------------------------------------------------------------
%% @doc
%% Admin 
%% @end
%%--------------------------------------------------------------------
handle_info({Pid,{ping}}, State) ->
  Pid!{self(),pong},
  {noreply, State};

handle_info(Info, State) ->
    ?LOG_WARNING("Unmatched signal",[Info]),
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
update_loop()->
    timer:sleep(?LoopTime),
    rpc:cast(node(),?MODULE,update,[]).
