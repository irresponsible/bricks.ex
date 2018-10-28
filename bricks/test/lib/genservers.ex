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

defmodule Bricks.Test.Genserver.Echo1 do
  use GenServer

  alias Bricks.{Connector, Socket}
  import Bricks.Sugar

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [])
  end

  def send_data(pid, data) do
    GenServer.call(pid, {:send, data})
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  # Callbacks
  def init([conn, parent]) do
    {:ok, sock} = Connector.connect(conn)
    {:ok, sock} = Socket.extend_active(sock)
    {:ok, {sock, parent}}
  end

  def handle_call({:send, data}, _from, {sock, _} = state) do
    :ok = Socket.send_data(sock, data)
    {:reply, :ok, state}
  end

  defhandle_info data({SOCKET, parent} = state, data) do
    send(parent, {:data, data})
    {:noreply, state}
  end

  defhandle_info error({SOCKET, _expected, _buffer, _parent} = state, reason) do
    {:stop, reason, state}
  end

  defhandle_info closed({SOCKET, parent} = state) do
    send(parent, :closed)
    {:stop, :closed, state}
  end

  defhandle_info passive({SOCKET = socket, parent}) do
    {:ok, sock} = Socket.extend_active(socket)
    {:noreply, {sock, parent}}
  end
end

defmodule Bricks.Test.Genserver.EchoOnce do
  use GenServer

  alias Bricks.{Connector, Socket}
  import Bricks.Sugar

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [])
  end

  def send_data(pid, data) do
    GenServer.call(pid, {:send, data})
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  # Callbacks
  def init([conn, parent]) do
    {:ok, sock} = Connector.connect(conn)
    {:ok, sock} = Socket.extend_active(sock)
    {:ok, {sock, parent}}
  end

  def handle_call({:send, data}, _from, {sock, _} = state) do
    :ok = Socket.send_data(sock, data)
    {:reply, :ok, state}
  end

  defhandle_info data({SOCKET = socket, parent}, data) do
    send(parent, {:data, data})
    {:ok, sock} = Socket.extend_active(socket)
    {:noreply, {sock, parent}}
  end

  defhandle_info error({SOCKET, _expected, _buffer, _parent} = state, reason) do
    {:stop, reason, state}
  end

  defhandle_info closed({SOCKET, parent} = state) do
    send(parent, :closed)
    {:stop, :closed, state}
  end
end

defmodule Bricks.Test.Genserver.Fixed1 do
  use GenServer

  alias Bricks.{Connector, Socket}
  import Bricks.Sugar

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [])
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  # Callbacks
  def init([conn, target, parent]) do
    {:ok, sock} = Connector.connect(conn)
    {:ok, sock} = Socket.extend_active(sock)
    {:ok, {sock, parent, target, ""}}
  end

  defhandle_info data({SOCKET = socket, parent, target, acc} = state, data) do
    data = acc <> data

    if byte_size(data) >= target do
      send(parent, {:data, data})
      {:noreply, state}
    else
      {:noreply, {socket, parent, target, data}}
    end
  end

  defhandle_info error({SOCKET, _, _, _} = state, reason) do
    {:stop, reason, state}
  end

  defhandle_info closed({SOCKET, parent, _, _} = state) do
    send(parent, :closed)
    {:stop, :closed, state}
  end

  defhandle_info passive({SOCKET = socket, parent, target, acc}) do
    {:ok, sock} = Socket.extend_active(socket)
    {:noreply, {sock, parent, target, acc}}
  end
end

defmodule Bricks.Test.Genserver.FixedOnce do
  use GenServer

  alias Bricks.{Connector, Socket}
  import Bricks.Sugar

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [])
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  # Callbacks
  def init([conn, target, parent]) do
    {:ok, sock} = Connector.connect(conn)
    {:ok, sock} = Socket.extend_active(sock)
    {:ok, {sock, parent, target, ""}}
  end

  defhandle_info data({SOCKET = socket, parent, target, acc} = state, data) do
    data = acc <> data

    if byte_size(data) >= target do
      send(parent, {:data, data})
      {:noreply, state}
    else
      {:ok, sock} = Socket.extend_active(socket)
      {:noreply, {sock, parent, target, data}}
    end
  end

  defhandle_info error({SOCKET, _, _, _} = state, reason) do
    {:stop, reason, state}
  end

  defhandle_info closed({SOCKET, parent, _, _} = state) do
    send(parent, :closed)
    {:stop, :closed, state}
  end

  defhandle_info passive({SOCKET = socket, parent, target, acc}) do
    {:ok, sock} = Socket.extend_active(socket)
    {:noreply, {sock, parent, target, acc}}
  end
end
