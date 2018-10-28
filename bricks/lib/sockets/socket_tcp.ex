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

defmodule Bricks.Socket.Tcp do
  @moduledoc """
  A TCP socket or unix domain socket managed by gen_tcp
  """
  alias Bricks.Socket
  alias Bricks.Error.{BadOption, Closed, Posix}
  import Bricks.Guards

  @behaviour Socket

  @default_bam_window 10
  @default_receive_timeout 5000
  @default_active false

  @typedoc "The options accepted by `create/2`"
  @type create_opts :: %{
          :host => Socket.host(),
          :port => Socket.port_num() | :local,
          optional(:active) => Socket.active(),
          optional(:receive_timeout) => timeout(),
          optional(:bam_window) => Socket.window()
        }

  @spec create(port(), create_opts()) :: {:ok, Socket.t()} | {:error, Socket.new_error()}
  @doc """
  Creates a new `Socket` wrapping the provided tcp port and obeying the provided options
  """
  def create(tcp_port, opts = %{host: host, port: port})
      when is_port(tcp_port) do
    active = Map.get(opts, :active, @default_active)
    bam_window = Map.get(opts, :bam_window, @default_bam_window)
    receive_timeout = Map.get(opts, :receive_timeout, @default_receive_timeout)

    cond do
      not is_active(active) ->
        {:error, BadOption.new(:active, active, [:bool, :integer, :once])}

      not is_window(bam_window) ->
        {:error, BadOption.new(:bam_window, bam_window, [:once, :pos_integer])}

      not is_timeout(receive_timeout) ->
        {:error, BadOption.new(:receive_timeout, receive_timeout, [:infinity, :non_neg_integer])}

      true ->
        :ok = :inet.setopts(tcp_port, active: active)

        Socket.new(%{
          host: host,
          port: port,
          handle: tcp_port,
          active: active,
          receive_timeout: receive_timeout,
          bam_window: bam_window,
          module: __MODULE__,
          data_tag: :tcp,
          error_tag: :tcp_error,
          closed_tag: :tcp_closed,
          passive_tag: :tcp_passive
        })
    end
  end

  # Behaviour implementations

  @doc false
  def fetch_active(%Socket{handle: tcp}) do
    case :inet.getopts(tcp, [:active]) do
      {:ok, active: val} -> {:ok, val}
      {:error, code} -> {:error, Posix.new(code)}
    end
  end

  @doc false
  def set_active(%Socket{handle: tcp} = socket, active) do
    case :inet.setopts(tcp, active: active) do
      :ok -> {:ok, %{socket | active: active}}
      {:error, code} -> {:error, Posix.new(code)}
    end
  end

  @doc false
  def recv(%Socket{handle: tcp, active: false} = socket, size, timeout) do
    case :gen_tcp.recv(tcp, size, timeout) do
      {:ok, data} -> {:ok, data, socket}
      {:error, :closed} -> {:error, Closed.new()}
      {:error, reason} -> {:error, Posix.new(reason)}
    end
  end

  @doc false
  def send_data(%Socket{handle: tcp}, data) do
    case :gen_tcp.send(tcp, data) do
      :ok -> :ok
      {:error, :closed} -> {:error, Closed.new()}
      {:error, reason} -> {:error, Posix.new(reason)}
    end
  end

  @doc false
  def close(%Socket{handle: tcp}) do
    :gen_tcp.close(tcp)
  end

  @doc false
  def handoff(%Socket{handle: tcp} = socket, pid) do
    case :gen_tcp.controlling_process(tcp, pid) do
      :ok -> {:ok, socket}
      {:error, :closed} -> {:error, Closed.new()}
      {:error, :badarg} -> {:error, BadOption.new(:pid, pid, [:pid])}
      {:error, posix} -> {:error, Posix.new(posix)}
    end
  end
end
