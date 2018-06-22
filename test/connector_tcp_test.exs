defmodule Bricks.Connector.TcpTest do
  use ExUnit.Case
  alias Bricks.{Connector,Sockets}
  import BricksTest.EchoServices
  alias Bricks.Connector.Tcp
  test "echo passive" do
    {:ok, port} = echo_tcp()
    tcp = Tcp.new({127,0,0,1}, port)
    {:ok, sock} = Connector.connect(tcp)
    {:ok, ""} = Sockets.passify(sock)
    Sockets.send_data(sock, "hello world\n")
    {:ok, "hello world\n"} = Sockets.recv_passive(sock, 0, 1000)
  end

  test "echo active" do
    {:ok, port} = echo_tcp()
    tcp = Tcp.new({127,0,0,1}, port)
    {:ok, sock} = Connector.connect(tcp)
    :ok = Sockets.actify(sock)
    Sockets.send_data(sock, "hello world\n")
    {:ok, "hello world\n"} = Sockets.recv_active(sock, 1000)
  end

  test "read passive" do
    {:ok, port} = echo_tcp()
    tcp = Tcp.new({127,0,0,1}, port)
    {:ok, sock} = Connector.connect(tcp)
    {:ok, ""} = Sockets.passify(sock)
    Sockets.send_data(sock, "hello world\n")
    {:ok, "hello world\n", false} = Sockets.read(sock, 0, nil, 1000)
    {:ok, port} = echo_tcp()
    tcp = Tcp.new({127,0,0,1}, port)
    {:ok, sock} = Connector.connect(tcp)
    {:ok, ""} = Sockets.passify(sock)
    Sockets.send_data(sock, "hello world\n")
    {:ok, "hello world\n", false} = Sockets.read(sock, 0, false, 1000)
  end

  test "read active" do
    {:ok, port} = echo_tcp()
    tcp = Tcp.new({127,0,0,1}, port)
    {:ok, sock} = Connector.connect(tcp)
    :ok = Sockets.actify(sock)
    Sockets.send_data(sock, "hello world\n")
    {:ok, "hello world\n", true} = Sockets.read(sock, 0, nil, 1000)
    {:ok, port} = echo_tcp()
    tcp = Tcp.new({127,0,0,1}, port)
    {:ok, sock} = Connector.connect(tcp)
    :ok = Sockets.actify(sock)
    Sockets.send_data(sock, "hello world\n")
    {:ok, "hello world\n", true} = Sockets.read(sock, 0, true, 1000)
  end

end
