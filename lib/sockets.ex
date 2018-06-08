defmodule Bricks.Sockets do
  alias Bricks.Socket

  @doc """
  """
  defdelegate socket(socket), to: Socket
  @doc """
  """
  defdelegate send_data(socket, data), to: Socket
  @doc """
  """
  defdelegate recv_passive(socket), to: Socket
  @doc """
  """
  defdelegate recv_passive(socket, size), to: Socket
  @doc """
  """
  defdelegate recv_passive(socket, size, timeout), to: Socket
  @doc """
  """
  defdelegate recv_active(socket), to: Socket
  @doc """
  """
  defdelegate recv_active(socket, timeout), to: Socket
  @doc """
  """
  defdelegate getopts(socket, opts), to: Socket
  @doc """
  """
  defdelegate setopts(socket, opts), to: Socket
  @doc """
  """
  defdelegate transfer(socket, pid), to: Socket

  @doc """
  Turns the socket passive, clearing any active data out of the mailbox
  Success: :ok
  Error: {:error, reason}
  """
  def actify(socket, times \\ true)
  def actify(socket, times)
  when times === true or (is_integer(times) and times > 0 ),
    do: Socket.setopts(socket, active: times)
  def actify(_, _), do: {:error, {:invalid, :times}}

  @doc """
  Turns the socket passive, clearing any active data out of the mailbox
  Success: {:ok, leftover} when is_binary(leftover)
  Error: {:error, reason}
  """
  def passify(socket) do
    with :ok <- Socket.setopts(socket, active: false),
      do: passify_h(socket, "")
  end
  defp passify_h(socket, acc) do
    case Socket.recv_active(socket, 0) do
      {:ok, data} -> passify_h(socket, acc <> data)
      {:error, :timeout} -> {:ok, acc}
      other -> other
    end
  end

  @doc """
  Returns the current activity status of the socket
  Success: {:ok, active}
    when is_bool(active) or (is_integer(active) and active > 0)
  Error: {:error, reason}
  """
  def active?(socket) do
    with {:ok, active: val} <- getopts(socket, [:active]),
      do: {:ok, val}
  end

end
