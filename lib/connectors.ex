defmodule Bricks.Connectors do
  alias Bricks.Connector

  @doc """
  Attempts to connect
  Returns: {:ok, conn} | {:error, reason}
  """
  defdelegate connect(conn), to: Connector
end
