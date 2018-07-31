defmodule Bricks.Clients do
  alias Bricks.Client

  @doc """
  Gets a connection
  """
  defdelegate connect(client), to: Client

  @doc """
  Notify the client that we're done with the connection
  """
  defdelegate done(client, socket), to: Client

  @doc """
  Notifies the client that there was an error on the socket so we gave up
  """
  defdelegate error(client, socket), to: Client
end
