%%%-------------------------------------------------------------------
%% @doc queueserv top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(queueserv_sup).

-behaviour(supervisor).

-export([start_link/0]).

-export([init/1, start_socket/0]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%% sup_flags() = #{strategy => strategy(),         % optional
%%                 intensity => non_neg_integer(), % optional
%%                 period => pos_integer()}        % optional
%% child_spec() = #{id => child_id(),       % mandatory
%%                  start => mfargs(),      % mandatory
%%                  restart => restart(),   % optional
%%                  shutdown => shutdown(), % optional
%%                  type => worker(),       % optional
%%                  modules => modules()}   % optional

init([]) ->
    {ok, Port} = application:get_env(queueserv, port),
    %% Set the socket into {active_once} mode.
    %% See queueserv_serv comments for more details
    {ok, ListenSocket} = gen_tcp:listen(Port, [{active,once}, {packet,line}]),
    spawn_link(fun empty_listeners/0),
    {ok, {{simple_one_for_one, 60, 3600},
    [{socket,
    {queueserv_serv, start_link, [ListenSocket]}, % pass the socket!
    temporary, 1000, worker, [queueserv_serv]}
    ]}}.
    
start_socket() ->
    supervisor:start_child(?MODULE, []).
    
%% Start with 20 listeners so that many multiple connections can
%% be started at once, without serialization. In best circumstances,
%% a process would keep the count active at all times to insure nothing
%% bad happens over time when processes get killed too much.
empty_listeners() ->
    [start_socket() || _ <- lists:seq(1,20)],
    ok.
