% Holds the logic responsible for defining abstract functions and handling super.
-module(elixir_def_abstract).
-export([define/3, store_pending/1]).
-include("elixir.hrl").

abstract(Module) ->
  ets:lookup_element(elixir_module:data_table(Module), abstract, 2).

abstract(Module, Value) ->
  ets:insert(elixir_module:data_table(Module), { abstract, Value }).

define(Module, Tuple, Args) ->
  Old = abstract(Module),
  New = [{ Tuple, [Args] }],
  Abstract = orddict:merge(fun(_K, V1, _V2) -> [Args|V1] end, Old, New),
  abstract(Module, Abstract).

%% Store pending declarations that were not manually made concrete.

store_pending(Module) ->
  [store_pending(Module, X) || X <- abstract(Module)].

store_pending(_Module, { _, [] }) -> [];

store_pending(Module, { Function, [H|_] }) ->
  { Kind, Line, Module, Name, Args, RawGuards, RawExpr, RawS } = H,
  S1 = elixir_variables:deserialize_scope(RawS),
  S2 = S1#elixir_scope{function=Function, module=Module},
  elixir_def:store_definition(Kind, Line, Module, Name, Args, RawGuards, RawExpr, S2).