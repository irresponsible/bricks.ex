defmodule Bricks.Client.SimpleTest do
  use ExUnit.Case
  alias Bricks.{Connector, Client, Socket, Sockets}
  import BricksTest.EchoServices
  alias Bricks.Connector.Tcp
  alias Bricks.Client.Simple

  test "echo passive" do
    {:ok, port} = echo_tcp()
    tcp = Tcp.new({127,0,0,1}, port)
    client = Simple.new(tcp, 1000)
    {:ok, sock} = Client.connect(client)
    {:ok, ""} = Sockets.passify(sock)
    :ok = Socket.send_data(sock, "hello world\n")
    {:ok, "hello world\n"} = Socket.recv_passive(sock, 0, 1000)
  end

  test "echo active" do
    {:ok, port} = echo_tcp()
    tcp = Tcp.new({127,0,0,1}, port)
    client = Simple.new(tcp, 1000)
    {:ok, sock} = Client.connect(client)
    :ok = Sockets.actify(sock)
    :ok = Socket.send_data(sock, "hello world\n")
    {:ok, "hello world\n"} = Socket.recv_active(sock, 1000)
  end
end
