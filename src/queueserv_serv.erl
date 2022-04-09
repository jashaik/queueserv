%%% Handles socket connections
-module(queueserv_serv).
-behaviour(gen_server).

-export([start_link/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, code_change/3, terminate/2]).

-record(state, {
            socket,
            queue = queue:new()
        }).

start_link(Socket) ->
  gen_server:start_link(?MODULE, Socket, []).

init(Socket) ->
  %% Start accepting requests
  %% We must cast this to the worker's process, as it blocks it.
  gen_server:cast(self(), accept),
  {ok, #state{socket=Socket}}.

handle_cast(accept, State = #state{socket=ListenSocket}) ->
  {ok, AcceptSocket} = gen_tcp:accept(ListenSocket),
  %% Boot a new listener to replace this one.
  queueserv_sup:start_socket(),
  send(AcceptSocket, "Welcome to the Queue server", []),
  send(AcceptSocket, "Supported Messages: \'in:payload\' or \'out\'", []),
  {noreply, State#state{socket=AcceptSocket}};
handle_cast(_, State) ->
  {noreply, State}.


handle_info({tcp, Socket, "quit"++_}, State) ->
  gen_tcp:close(Socket),
  {stop, normal, State};
handle_info({tcp, Socket, "in:" ++ Payload}, #state{queue = Q} = State) ->
  Q1 = queue:in(line(Payload), Q),
  send(Socket, "Value queued", []),
  {noreply, State#state{queue = Q1}};
handle_info({tcp, Socket, "out" ++ _}, #state{queue = Q} = State) ->
  Q1 = case queue:out(Q) of
         {{value, Item}, Q2} ->
            send(Socket, Item, []),
            Q2;
         {empty, Q} ->
            send(Socket, "Queue is empty", []),
            Q
      end,
  {noreply, State#state{queue = Q1}};
handle_info({tcp, Socket, Msg}, State) ->
  send(Socket, Msg, []),
  {noreply, State};
handle_info({tcp_closed, _Socket}, State) -> {stop, normal, State};
handle_info({tcp_error, _Socket, _}, State) -> {stop, normal, State};
handle_info(E, State) ->
  io:fwrite("unexpected: ~p~n", [E]),
  {noreply, State}.

handle_call(_E, _From, State) -> {noreply, State}.
terminate(_Reason, _Tab) -> ok.
code_change(_OldVersion, Tab, _Extra) -> {ok, Tab}.

%% Send a message back to the client
send(Socket, Str, Args) ->
  ok = gen_tcp:send(Socket, io_lib:format(Str++"~n", Args)),
  ok = inet:setopts(Socket, [{active, once}]),
  ok.

%% Remove the line breaks
line(Str) ->
  hd(string:tokens(Str, "\r\n ")).
