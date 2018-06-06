defmodule Bricks.Connector.TcpTest do
  use ExUnit.Case
  alias Bricks.Connector
  import BricksTest.EchoServices
  alias Bricks.Connector.Tcp
  test "echo" do
    {:ok, port} = echo_tcp()
    tcp = Tcp.new({127,0,0,1}, port)
    {:ok, sock} = Connector.connect(tcp)
    :inet.setopts(sock.socket, active: false)
    :ok = :gen_tcp.send(sock.socket, "hello world\n")
    {:ok, "hello world\n"} = :gen_tcp.recv(sock.socket, 0, 1000)
  end
end
