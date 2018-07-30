defmodule Bricks.Connector.TcpTest do
  use ExUnit.Case

  alias Bricks.Connector.Tcp

  describe "new/4" do
    test "parses IPv4 hostnames encoded in a binary" do
      assert Tcp.new("127.0.0.1", 80).host == {127, 0, 0, 1}
    end

    test "parses IPv6 hostnames encoded in a binary" do
      assert Tcp.new("::1", 80).host == {0, 0, 0, 0, 0, 0, 0, 1}
    end
  end
end
