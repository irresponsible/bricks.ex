defmodule Bricks.Connector.TcpTest do
  use ExUnit.Case
  import BricksTest.EchoServices

  alias Bricks.{Connector,Socket}
  alias Bricks.Connector.Tcp

  test "echo passive" do
    {:ok, port} = echo_tcp()
    tcp = Tcp.new({127,0,0,1}, port)
    {:ok, sock} = Connector.connect(tcp)
    {:ok, ""} = Socket.passify(sock)
    Socket.send_data(sock, "hello world\n")
    {:ok, "hello world\n", false} = Socket.read(sock, 0, false, 1000)
  end

  test "echo active" do
    {:ok, port} = echo_tcp()
    tcp = Tcp.new({127,0,0,1}, port)
    {:ok, sock} = Connector.connect(tcp)
    :ok = Socket.actify(sock)
    Socket.send_data(sock, "hello world\n")
    {:ok, "hello world\n", true} = Socket.read(sock, 0, true, 1000)
  end

  test "read passive" do
    {:ok, port} = echo_tcp()
    tcp = Tcp.new({127,0,0,1}, port)
    {:ok, sock} = Connector.connect(tcp)
    {:ok, ""} = Socket.passify(sock)
    Socket.send_data(sock, "hello world\n")
    {:ok, "hello world\n", false} = Socket.read(sock, 0, nil, 1000)
    {:ok, port} = echo_tcp()
    tcp = Tcp.new({127,0,0,1}, port)
    {:ok, sock} = Connector.connect(tcp)
    {:ok, ""} = Socket.passify(sock)
    Socket.send_data(sock, "hello world\n")
    {:ok, "hello world\n", false} = Socket.read(sock, 0, false, 1000)
  end

  test "read active" do
    {:ok, port} = echo_tcp()
    tcp = Tcp.new({127,0,0,1}, port)
    {:ok, sock} = Connector.connect(tcp)
    :ok = Socket.actify(sock)
    Socket.send_data(sock, "hello world\n")
    {:ok, "hello world\n", true} = Socket.read(sock, 0, nil, 1000)
    {:ok, port} = echo_tcp()
    tcp = Tcp.new({127,0,0,1}, port)
    {:ok, sock} = Connector.connect(tcp)
    :ok = Socket.actify(sock)
    Socket.send_data(sock, "hello world\n")
    {:ok, "hello world\n", true} = Socket.read(sock, 0, true, 1000)
  end

end
