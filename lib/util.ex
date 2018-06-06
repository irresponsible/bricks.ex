defmodule Bricks.Util do

  @doc "Attempts to resolve a hostname"
  @spec resolve_host(binary) ::
    {:ok, binary(), atom(), [binary()]} | {:error, {:invalid_host, binary(), any()}}

  def resolve_host(host) do
    case :inet_res.gethostbyname(host, :inet6) do
      {:ok, {:hostent, name, _aliases, addrtype, _length, ips}} ->
	{:ok, name, addrtype, ips}
      other -> {:error, {:invalid_host, host, other}}
    end
  end

end
