defmodule Bricks.IntegrationTest do
  use ExUnit.Case
  import BricksTest.EchoServices

  alias Bricks.{Connector, Socket}
  alias Bricks.Connector.{Tcp, Unix}

  describe "unix" do
    test "echo" do
      {:ok, path} = echo_unix()
      unix = Unix.new(path)
      {:ok, sock} = Connector.connect(unix)
      {:ok, ""} = Socket.passify(sock)
      :ok = Socket.send_data(sock, "hello world\n")
      {:ok, "hello world\n", false} = Socket.read(sock, 0, false, 1000)
    end
  end

  def open_and_send!(address, data, active?, tcp_opts \\ []) do
    {:ok, port} = echo_tcp(tcp_opts)
    tcp = Tcp.new(address, port)
    {:ok, sock} = Connector.connect(tcp)
    if active? do
      :ok = Socket.actify(sock)
    else
      {:ok, ""} = Socket.passify(sock)
    end
    Socket.send_data(sock, data)
    sock
  end

  describe "tcp" do
    @test_address {127, 0, 0, 1}

    test "echo active" do
      sock = open_and_send!(@test_address, "hello world\n", true)
      {:ok, "hello world\n", true} = Socket.read(sock, 0, true, 1000)
    end

    test "read active" do
      sock = open_and_send!(@test_address, "hello world\n", true)
      {:ok, "hello world\n", true} = Socket.read(sock, 0, nil, 1000)
      sock = open_and_send!(@test_address, "hello world\n", true)
      {:ok, "hello world\n", true} = Socket.read(sock, 0, true, 1000)
    end

    test "read passive" do
      sock = open_and_send!(@test_address, "hello world\n", false)
      {:ok, "hello world\n", false} = Socket.read(sock, 0, nil, 1000)
      sock = open_and_send!(@test_address, "hello world\n", false)
      {:ok, "hello world\n", false} = Socket.read(sock, 0, false, 1000)
    end

    test "echo passive" do
      sock = open_and_send!(@test_address, "hello world\n", false)
      {:ok, "hello world\n", false} = Socket.read(sock, 0, false, 1000)
    end
  end

  # FIXME: test duplication
  describe "tcp IPv6" do
    @test_address {0, 0, 0, 0, 0, 0, 0, 1}

    test "echo active" do
      sock = open_and_send!(@test_address, "hello world\n", true, [:inet6])
      {:ok, "hello world\n", true} = Socket.read(sock, 0, true, 1000)
    end

    test "read active" do
      sock = open_and_send!(@test_address, "hello world\n", true, [:inet6])
      {:ok, "hello world\n", true} = Socket.read(sock, 0, nil, 1000)
      sock = open_and_send!(@test_address, "hello world\n", true, [:inet6])
      {:ok, "hello world\n", true} = Socket.read(sock, 0, true, 1000)
    end

    test "read passive" do
      sock = open_and_send!(@test_address, "hello world\n", false, [:inet6])
      {:ok, "hello world\n", false} = Socket.read(sock, 0, nil, 1000)
      sock = open_and_send!(@test_address, "hello world\n", false, [:inet6])
      {:ok, "hello world\n", false} = Socket.read(sock, 0, false, 1000)
    end

    test "echo passive" do
      sock = open_and_send!(@test_address, "hello world\n", false, [:inet6])
      {:ok, "hello world\n", false} = Socket.read(sock, 0, false, 1000)
    end
  end
end
