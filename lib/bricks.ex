defmodule Bricks do
  @moduledoc """
  Bricks provides a set of abstractions for working with low level sockets.

  # Opening an TCP connection

    # iex> tcp = Bricks.Connector.Tcp.new("localhost", 6969)
    # %Bricks.Connector.Tcp{
    #   host: "localhost",
    #   port: 6969,
    #   step_timeout: 5000,
    #   tcp_opts: [:binary]
    # }

  First, we declare a connector, the configuration and logic for initializing
  a TCP request. It has a default number of milliseconds before the attempt to
  establish a connection fails and uses binary encoding by default.

    # iex> _client = Bricks.Client.Simple.new(tcp)
    # %Bricks.Client.Simple{
    #   connector: %Bricks.Connector.Tcp{
    #     host: "localhost",
    #     port: 6969,
    #     step_timeout: 5000,
    #     tcp_opts: [:binary]
    #   },
    #   timeout: 30000
    # }

  The client is now defined. This just handles the TCP sockets that are passed
  in to it, closing them when finished or when errored.

  TODO
  """

  import ProtocolEx

  defprotocolEx Client do
    def connect(client)
    def done(client, socket)
    def error(client, socket)
  end

  defprotocolEx Connector do
    def connect(self)
  end

  defprotocolEx ToIoData do
    def to_iodata(self)
  end

  defdelegate to_iodata(thing), to: Bricks.ToIoData
end
