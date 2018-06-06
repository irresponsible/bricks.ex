defmodule Bricks.Socket.TcpTest do
  use ExUnit.Case
  alias Bricks.{Connector, Socket, Sockets}
  import BricksTest.EchoServices
  alias Bricks.Connector.{Tcp,Unix}

  test "tcp passive" do
    {:ok, port} = echo_tcp()
    tcp = Tcp.new({127,0,0,1}, port)
    {:ok, sock} = Connector.connect(tcp)
    {:ok, ""} = Sockets.passify(sock)
    :ok = Socket.send_data(sock, "hello world\n")
    {:ok, "hello world\n"} = Socket.recv_passive(sock, 0, 1000)
  end
  test "tcp active" do
    {:ok, port} = echo_tcp()
    tcp = Tcp.new({127,0,0,1}, port)
    {:ok, sock} = Connector.connect(tcp)
    :ok = Sockets.actify(sock)
    :ok = Socket.send_data(sock, "hello world\n")
    {:ok, "hello world\n"} = Socket.recv_active(sock, 1000)
  end

  test "unix passive" do
    {:ok, path} = echo_unix()
    unix = Unix.new(path)
    {:ok, sock} = Connector.connect(unix)
    {:ok, ""} = Sockets.passify(sock)
    :ok = Socket.send_data(sock, "hello world\n")
    {:ok, "hello world\n"} = Socket.recv_passive(sock, 0, 1000)
  end
  test "unix active" do
    {:ok, path} = echo_unix()
    unix = Unix.new(path)
    {:ok, sock} = Connector.connect(unix)
    :ok = Sockets.actify(sock)
    :ok = Socket.send_data(sock, "hello world\n")
    {:ok, "hello world\n"} = Socket.recv_active(sock, 3000)
  end

end
