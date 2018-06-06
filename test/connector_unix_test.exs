defmodule Bricks.Connector.UnixTest do
  use ExUnit.Case
  alias Bricks.{Client, Connector, Socket}
  import BricksTest.EchoServices
  alias Bricks.Connector.Unix
  test "echo" do
    {:ok, path} = echo_unix()
    unix = Unix.new(path)
    {:ok, sock} = Connector.connect(unix)
    :ok = :gen_tcp.send(sock.socket, "hello world\n")
    {:ok, "hello world\n"} = :gen_tcp.recv(sock.socket, 0)
  end
end
