defmodule Bricks.Client.SimpleTest do
  use ExUnit.Case
  import BricksTest.EchoServices

  alias Bricks.{Client, Socket}
  alias Bricks.Connector.Tcp
  alias Bricks.Client.Simple

  test "echo passive" do
    {:ok, port} = echo_tcp()
    tcp = Tcp.new({127, 0, 0, 1}, port)
    client = Simple.new(tcp, 1000)
    {:ok, sock} = Client.connect(client)
    {:ok, ""} = Socket.passify(sock)
    :ok = Socket.send_data(sock, "hello world\n")
    {:ok, "hello world\n"} = Socket.recv(sock, 0, 1000)
  end

  test "echo active" do
    {:ok, port} = echo_tcp()
    tcp = Tcp.new({127, 0, 0, 1}, port)
    client = Simple.new(tcp, 1000)
    {:ok, sock} = Client.connect(client)
    :ok = Socket.actify(sock)
    :ok = Socket.send_data(sock, "hello world\n")
    assert_receive {Socket, ^sock, {:data, "hello world\n"}}, 1000
  end
end
