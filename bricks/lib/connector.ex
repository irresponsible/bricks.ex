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

defmodule Bricks.Connector do
  @moduledoc """
  A struct, behaviour and functions for working with Socket Connectors
  """
  @enforce_keys [:module, :connector]
  defstruct @enforce_keys

  alias Bricks.{Connector, Socket}

  @typedoc "A function which borrows a Socket"
  @type lessee :: (Socket.t() -> {:ok, term()} | {:error, term()})

  @typedoc "State passed to the underlying Connector"
  @type state :: term()

  @typedoc "A Socket Connector"
  @type t :: %Connector{
          module: atom(),
          connector: term()
        }

  @doc "Create a Socket according to the configuration state"
  @callback connect(state()) :: {:ok, Socket.t()} | {:error, term()}

  @spec new(atom(), term()) :: t()
  @doc """
  Creates a new Connector from a callback module and a connector object
  """
  def new(module, connector) when is_atom(module) do
    %Connector{module: module, connector: connector}
  end

  @spec connect(t()) :: {:ok, Socket.t()} | {:error, term()}
  @doc """
  Attempts to create a connected Socket with the provided Connector
  """
  def connect(%Connector{module: m, connector: c}) do
    apply(m, :connect, [c])
  end

  @spec lease(t(), lessee()) :: {:error, term()} | term()
  @doc """
  Calls the provided function with a Socket leased from the provided pool

  Returns the socket to the pool or burns it, depending on the return
  of the provided function.

  In the event of error, burns the socket
  """
  def lease(%Connector{} = conn, fun) when is_function(fun, 1) do
    with {:ok, socket} <- connect(conn) do
      try do
        ret = fun.(socket)
        Socket.close(socket)
        ret
      rescue
        e ->
          Socket.close(socket)
          {:error, e}
      end
    end
  end
end
