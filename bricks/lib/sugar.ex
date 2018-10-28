# Copyright (c) 2018 James Laver
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule Bricks.Sugar do
  @moduledoc """
  Macros for handling sockets in active mode - supporting both
  explicit receive and GenServer styles

  ## Explicit Receive Usage

  ```
  def receive_til_close(socket) do
    # Generates bindings against the socket to match against
    binding socket do
      receive do
        # Generate matches for the individual types
        match_data(data) ->
          Logger.info("Socket data: " <> data)
          receive_til_close(socket)
        match_error(reason) ->
          Logger.info("Socket error: " <> reason)
        match_closed() -> :ok
          Logger.info("Socket closed")
        match_passive() -> :ok
          :ok = Socket.extend_active(socket)
          Logger.info("Extended socket bounded active mode")
          receive_til_close(socket)
      end
    end
  end
  ```

  ## GenServer Usage

  ```
  defhandle_info data(%{socket: SOCKET}=state, data) do
    Logger.info("Socket data: " <> data)
    {:noreply, state}
  end
  defhandle_info error(%{socket: SOCKET}=state, reason) do
    Logger.info("Socket error: " <> reason)
    {:stop, reason, state}
  end
  defhandle_info closed(%{socket: SOCKET}=state) do
    Logger.info("Socket closed")
    {:stop, :closed, state}
  end
  defhandle_info passive(%{socket: SOCKET=socket}=state) do
    Logger.info("Extended socket bounded active mode")
    :ok = Socket.extend_active(socket)
    {:noreply, state}
  end
  ```
  """
  require Logger

  ### Macros

  @doc """
  Generates a handle_info clause corresponding to one of the four
  socket notification messages. Takes a match against state which must
  embed the atom `SOCKET` that identifies where in the state the
  socket to match against is. The return value from the body should be
  the same as for any `handle_info` callback.

  Forms:

  - `defhandle_info data(state_match, data_match) do ... end`
  - `defhandle_info error(state_match, reason_match) do ... end`
  - `defhandle_info closed(state_match) do ... end`
  - `defhandle_info passive(state_match) do ... end`

  See module docs for examples.
  """
  defmacro defhandle_info({:data, _meta, [match, arg]}, do: body) do
    handle_info_clause(match, :data_tag, arg, body)
  end

  defmacro defhandle_info({:error, _meta, [match, arg]}, do: body) do
    handle_info_clause(match, :error_tag, arg, body)
  end

  defmacro defhandle_info({:closed, _meta, [match]}, do: body) do
    handle_info_clause(match, :closed_tag, nil, body)
  end

  defmacro defhandle_info({:passive, _meta, [match]}, do: body) do
    handle_info_clause(match, :passive_tag, nil, body)
  end

  @doc """
  Creates a region in which the `match_*` macros will expand to
  matches against the provided socket. See module docs for examples.
  """
  defmacro binding(socket, do: body) do
    binding_socket(socket, body)
  end

  @doc """
  Expands to a match clause matching a data notification message
  for the socket within whose `binding/2` region we are in.

  Must be run within the region created by the `binding/2` macro.
  See module docs for examples.
  """
  defmacro match_data(match) do
    match_clause(match, :bricks__binding_data_tag)
  end

  @doc """
  Expands to a match clause matching an error notification message for
  the socket within whose `binding/2` region we are in. Takes an
  argument which is a match for the data (you probably want this to be
  a plain atom, i.e. simple assignment).

  Must be run within the region created by the `binding/2` macro.
  See module docs for examples.
  """
  defmacro match_error(match) do
    match_clause(match, :bricks__binding_error_tag)
  end

  @doc """
  Expands to a match clause matching a closed notification message for
  the socket within whose `binding/2` region we are in. Takes an
  argument which is a match for the error (you probably want this to
  be a plain atom, i.e. simple assignment).

  Must be run within the region created by the `binding/2` macro.
  See module docs for examples.
  """
  defmacro match_closed() do
    match_clause(nil, :bricks__binding_closed_tag)
  end

  @doc """
  Expands to a match clause matching a passive notification message
  for the socket within whose `binding/2` region we are in.

  Must be run within the region created by the `binding/2` macro.
  See module docs for examples.
  """
  defmacro match_passive() do
    match_clause(nil, :bricks__binding_passive_tag)
  end

  ### Implementation

  #### match

  # Generates a block in which certain bindings are available for use the `match` macro
  defp binding_socket(match, body) do
    body = reify_vars(body)
    body = Macro.prewalk(body, &Macro.expand(&1, __ENV__))

    ret =
      quote generated: true do
        %Bricks.Socket{
          handle: unquote({:bricks__binding_handle, [generated: true], nil}),
          data_tag: unquote({:bricks__binding_data_tag, [generated: true], nil}),
          error_tag: unquote({:bricks__binding_error_tag, [generated: true], nil}),
          closed_tag: unquote({:bricks__binding_closed_tag, [generated: true], nil}),
          passive_tag: unquote({:bricks__binding_passive_tag, [generated: true], nil})
        } = unquote(match)

        unquote(body)
      end

    ret
  end

  # generates a match clause for inside a receive
  defp match_clause(arg, tag_name) do
    tag = Macro.var(tag_name, nil)
    handle = Macro.var(:bricks__binding_handle, nil)

    case arg do
      nil ->
        quote do
          {^unquote(tag), ^unquote(handle)}
        end

      _ ->
        quote do
          {^unquote(tag), ^unquote(handle), unquote(reify_vars(arg))}
        end
    end
  end

  #### defhandle_info

  defp guards(head, guards), do: {:when, [context: nil], [head, guards]}

  defp defun(name, args, body, guards) do
    {:def, [context: nil], [guards({name, [context: nil], args}, guards), [do: body]]}
  end

  defp info_clause_args(nil, match) do
    tag = Macro.var(:bricks__binding_tag, nil)
    handle = Macro.var(:bricks__binding_handle, nil)
    [{:{}, [], [tag, handle]}, match]
  end

  defp info_clause_args({arg, _, nil}, match) when is_atom(arg) do
    tag = Macro.var(:bricks__binding_tag, nil)
    handle = Macro.var(:bricks__binding_handle, nil)
    arg = Macro.var(arg, nil)
    [{:{}, [], [tag, handle, arg]}, match]
  end

  # generates a handle_info clause
  defp handle_info_clause(match, tag_name, arg, body) do
    match = expand_info_match(match, tag_name)
    body = reify_vars(body)
    tag = Macro.var(:bricks__binding_tag, nil)
    tag2 = Macro.var(:bricks__binding_tag2, nil)
    handle = Macro.var(:bricks__binding_handle, nil)
    handle2 = Macro.var(:bricks__binding_handle2, nil)
    args = info_clause_args(arg, match)

    guards =
      quote do
        unquote(tag) == unquote(tag2) and unquote(handle) == unquote(handle2)
      end

    defun(:handle_info, args, body, guards)
  end

  defp reify_vars(body) do
    Macro.prewalk(body, fn ast ->
      case ast do
        {name, _meta, args}
        when is_atom(name) and (args == [] or is_nil(args) or is_atom(args)) ->
          Macro.var(name, nil)

        _ ->
          ast
      end
    end)
  end

  defp expand_info_match(match, tag) do
    {ret, socket?} = expand_info_match(match, tag, false)
    if not socket?, do: throw(:must_bind_socket)
    ret
  end

  defp expand_info_match({:%{}, whatever, map}, tag, seen?) do
    {list, seen?} =
      Enum.reduce(map, {[], seen?}, fn {k, v}, {acc, seen?} ->
        {v, seen?} = expand_info_match(v, tag, seen?)
        {[{k, v} | acc], seen?}
      end)

    {{:%{}, whatever, list}, seen?}
  end

  defp expand_info_match({:{}, whatever, items}, tag, seen?) do
    {val, seen?} = expand_info_match(items, tag, seen?)
    {{:{}, whatever, val}, seen?}
  end

  defp expand_info_match({:%, whatever, [name, map = {:%{}, _, _}]}, tag, seen?) do
    {r, seen?} = expand_info_match(map, tag, seen?)
    {{:%, whatever, [name, r]}, seen?}
  end

  defp expand_info_match(list, tag, seen?) when is_list(list) do
    {list, seen?} =
      Enum.reduce(list, {[], seen?}, fn val, {acc, seen?} ->
        {val, seen?} = expand_info_match(val, tag, seen?)
        {[val | acc], seen?}
      end)

    {Enum.reverse(list), seen?}
  end

  defp expand_info_match({:__aliases__, _, [:SOCKET]}, tag, false) do
    tag2 = Macro.var(:bricks__binding_tag2, nil)
    handle2 = Macro.var(:bricks__binding_handle2, nil)

    r =
      quote do
        %Bricks.Socket{
          :handle => unquote(handle2),
          unquote(tag) => unquote(tag2)
        }
      end

    {r, true}
  end

  defp expand_info_match({:__aliases__, _, [:SOCKET]}, _tag, true) do
    throw(:double_bound_socket)
  end

  defp expand_info_match({:=, meta, args}, tag, seen?) do
    {args, seen?} = expand_info_match(args, tag, seen?)
    {{:=, meta, args}, seen?}
  end

  defp expand_info_match({name, _meta, args}, _tag, seen?)
       when is_atom(name) and (args == [] or is_nil(args) or is_atom(args)) do
    {Macro.var(name, nil), seen?}
  end

  defp expand_info_match({_, _, _} = orig, _tag, _seen?) do
    throw({:unsupported_binding, :funcall, orig})
  end

  # not 3 items, plain data
  defp expand_info_match(match, tag, seen?) when is_tuple(match) do
    {ret, seen?} =
      Tuple.to_list(match)
      |> expand_info_match(tag, seen?)

    {List.to_tuple(ret), seen?}
  end

  defp expand_info_match(x, _tag, seen?)
       when is_integer(x) or is_float(x) or is_binary(x) or is_atom(x) or is_boolean(x) do
    {x, seen?}
  end
end
