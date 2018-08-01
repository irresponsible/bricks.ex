defmodule Bricks.Client.Simple do
  @moduledoc """
  A minimal client for handling TCP connections.

  # Examples

    iex> tcp_client = Simple.new(Bricks.Connector.Tcp("localhost", 25))
    iex> unix_client = Simple.new(Bricks.Connector.Unix("/var/run/echo.sock"))
  """

  @enforce_keys [:timeout, :connector]
  defstruct @enforce_keys

  alias Bricks.Client.Simple

  @default_timeout 30_000

  @doc """
  Create a new client using a socket connector (i.e. `Bricks.Connector`).
  Accepts an optional timeout parameter which indicates how many
  milliseconds
  """
  def new(connector, timeout \\ @default_timeout),
    do: %Simple{timeout: timeout, connector: connector}
end

import ProtocolEx

alias Bricks.Client
alias Bricks.Client.Simple

defimplEx ClientSimple, %Simple{}, for: Client do
  alias Bricks.{Connector, Socket}

  def connect(client), do: Connector.connect(client.connector)
  def done(_, socket), do: Socket.close(socket)
  def error(_, socket), do: Socket.close(socket)
end

# TODO: https://github.com/OvermindDL1/protocol_ex/issues/11
# defimplEx ClientSimpleTls, {%Bricks.Client.Simple{}, %Bricks.Socket.Tls{}}, for: Done do
#   def connect({client, tls}), do: Client.co
#   def return({client, tls}), do: :ssl.close(tls.socket)
#   def errored({client, tls}), do: :ssl.close(tls.socket)
# end
