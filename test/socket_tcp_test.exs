defmodule Bricks.Socket.TcpTest do
  use ExUnit.Case
  alias Bricks.{Connector, Socket}
  import BricksTest.EchoServices
  alias Bricks.Connector.{Tcp,Unix}

  test "tcp passive" do
    {:ok, port} = echo_tcp()
    tcp = Tcp.new({127,0,0,1}, port)
    {:ok, sock} = Connector.connect(tcp)
    {:ok, ""} = Socket.passify(sock)
    :ok = Socket.send_data(sock, "hello world\n")
    {:ok, "hello world\n", false} = Socket.read(sock, 0, false, 1000)
  end
  test "tcp active" do
    {:ok, port} = echo_tcp()
    tcp = Tcp.new({127,0,0,1}, port)
    {:ok, sock} = Connector.connect(tcp)
    :ok = Socket.actify(sock)
    :ok = Socket.send_data(sock, "hello world\n")
    {:ok, "hello world\n", true} = Socket.read(sock, 0, true, 1000)
  end

  test "unix passive" do
    {:ok, path} = echo_unix()
    unix = Unix.new(path)
    {:ok, sock} = Connector.connect(unix)
    {:ok, ""} = Socket.passify(sock)
    :ok = Socket.send_data(sock, "hello world\n")
    {:ok, "hello world\n", false} = Socket.read(sock, 0, false, 1000)
  end
  test "unix active" do
    {:ok, path} = echo_unix()
    unix = Unix.new(path)
    {:ok, sock} = Connector.connect(unix)
    :ok = Socket.actify(sock)
    :ok = Socket.send_data(sock, "hello world\n")
    {:ok, "hello world\n", true} = Socket.read(sock, 0, true, 1000)
  end

end
