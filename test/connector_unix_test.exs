defmodule Bricks.Connector.UnixTest do
  use ExUnit.Case
  alias Bricks.{Connector, Socket}
  import BricksTest.EchoServices
  alias Bricks.Connector.Unix

  test "echo" do
    {:ok, path} = echo_unix()
    unix = Unix.new(path)
    {:ok, sock} = Connector.connect(unix)
    {:ok, ""} = Socket.passify(sock)
    :ok = Socket.send_data(sock, "hello world\n")
    {:ok, "hello world\n", false} = Socket.read(sock, 0, false, 1000)
  end
end
