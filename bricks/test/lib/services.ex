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

defmodule Bricks.Test.Services do
  def echo_tcp(timeout \\ 1000) do
    {:ok, listen} = :gen_tcp.listen(0, [:binary])
    {:ok, port} = :inet.port(listen)
    pid = spawn_link(fn -> echo_server(listen, timeout) end)
    {:ok, port, pid}
  end

  @test_sock "/tmp/bricks-test.sock"
  def echo_unix(timeout \\ 1000) do
    # It's okay for it not to exist but nothing else
    case :file.delete(@test_sock) do
      :ok -> :ok
      {:error, :enoent} -> :ok
    end

    {:ok, listen} = :gen_tcp.listen(0, [:binary, {:ifaddr, {:local, @test_sock}}])
    pid = spawn_link(fn -> echo_server(listen, timeout) end)
    {:ok, @test_sock, pid}
  end

  def echo_server(listen, timeout) do
    {:ok, socket} = :gen_tcp.accept(listen, timeout)
    echo_server(socket)
  end

  defp echo_server(socket) do
    receive do
      :close ->
        :gen_tcp.close(socket)

      {:tcp, ^socket, data} ->
        :gen_tcp.send(socket, data)
        echo_server(socket)

      {:tcp_error, ^socket, reason} ->
        throw({:socket_error, reason})

      {:tcp_closed, ^socket} ->
        :ok = :gen_tcp.close(socket)
    end
  end

  def fixed_tcp(payloads) do
    {:ok, listen} = :gen_tcp.listen(0, [:binary])
    {:ok, port} = :inet.port(listen)
    pid = spawn_link(fn -> fixed_server(listen, payloads) end)
    {:ok, port, pid}
  end

  def fixed_unix(payloads) do
    # It's okay for it not to exist but nothing else
    case :file.delete(@test_sock) do
      :ok -> :ok
      {:error, :enoent} -> :ok
    end

    {:ok, listen} = :gen_tcp.listen(0, [:binary, {:ifaddr, {:local, @test_sock}}])
    pid = spawn_link(fn -> fixed_server(listen, payloads) end)
    {:ok, @test_sock, pid}
  end

  def fixed_server(listen, payloads) do
    {:ok, socket} = :gen_tcp.accept(listen, 1000)

    for p <- payloads do
      :gen_tcp.send(socket, p)
    end

    receive do
      {:tcp_closed, ^socket} ->
        :gen_tcp.close(socket)

      {:tcp_error, ^socket, reason} ->
        throw({:socket_error, reason})
    end
  end
end
