-module(statman_tests).

-compile(export_all).

-include_lib("eunit/include/eunit.hrl").

%% =============================================================================
statman_test_() ->
    {setup,
        fun setup/0, fun teardown/1,
        [
         {timeout, 200, {"Add/remove pollers", fun test_start_remove_pollers/0}}
        ]
    }.

%% =============================================================================
setup() ->
    {ok, _Pid} = statman_poller_sup:start_link(),

    statman_counter:init(),
    statman_gauge:init(),
    statman_histogram:init(),
    ok.

teardown(_) ->
    [ets:delete(T) || T <- [statman_counters, statman_gauges, statman_histograms]],
    ok.

test_start_remove_pollers() ->
    GaugeF     = fun() -> [{gauge, 5}] end,
    CounterF   = fun() -> [{counter, 5}] end,
    HistogramF = fun() -> [{histogram, 5}, {histogram, 10}] end,

    ?assertEqual([], statman_gauge:get_all()),
    ?assertEqual([], statman_counter:get_all()),
    ?assertEqual([], statman_histogram:keys()),

    {ok, _} = statman_poller_sup:add_gauge(GaugeF, 100),
    {ok, _} = statman_poller_sup:add_counter(CounterF, 100),
    {ok, _} = statman_poller_sup:add_histogram(HistogramF, 100),

    timer:sleep(250),

    ?assertMatch([{gauge, _}], statman_gauge:get_all()),
    ?assertEqual([counter], statman_counter:counters()),
    ?assertEqual([histogram], statman_histogram:keys()),

    ok = statman_poller_sup:remove_gauge(GaugeF),
    ok = statman_poller_sup:remove_counter(CounterF),
    ok = statman_poller_sup:remove_histogram(HistogramF),

    ?assertEqual([], statman_poller_sup:get_workers()).
