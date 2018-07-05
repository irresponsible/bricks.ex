defmodule Bricks.Socket do
  alias Bricks.Socket

  def recv(socket, size, timeout), do: GenServer.call(socket, {:recv, size, timeout}, timeout)

  def send_data(socket, data), do: GenServer.call(socket, {:send, data})

  def getopts(socket, opts), do: GenServer.call(socket, {:getopts, opts})

  def setopts(socket, opts) when is_list(opts), do: GenServer.call(socket, {:setopts, opts})

  def close(socket), do: GenServer.call(socket, :close)

  def transfer!(socket, to) when is_pid(to), do: GenServer.call(socket, {:transfer, to})

  def read(socket, limit, activity \\ nil, step_timeout \\ nil)
  def read(socket, limit, activity, nil), do: read(socket, limit, activity, socket.step_timeout)
  def read(socket, limit, nil, step_timeout) do
    case active?(socket) do
      {:ok, activity} -> read(socket, limit, activity, step_timeout)
      {:error, reason} -> {:error, {{:read, reason}, nil}}
    end
  end
  def read(socket, limit, activity, step_timeout) do
    case activity do
      false ->
	case recv(socket, limit, step_timeout) do
	  {:ok, data} -> {:ok, data, false}
	  {:error, reason} -> {:error, reason}
	end
      true ->
	receive do
	  {Socket, ^socket, msg} ->
	    case msg do
	      {:data, data} -> {:ok, data, true}
	      :closed -> {:error, :closed}
	      {:error, reason} -> {:error, reason}
	    end
	after
	  step_timeout -> {:error, :timeout}
	end
    end
  end
  

  @doc """
  Turns the socket passive, clearing any active data out of the mailbox
  Success: :ok
  Error: {:error, reason}
  """
  def actify(socket, times \\ true)
  def actify(socket, times)
  when times === true or (is_integer(times) and times > 0),
    do: setopts(socket, active: times)
  def actify(_, _), do: {:error, {:invalid, :times}}

  @doc """
  Turns the socket passive, clearing any active data out of the mailbox
  Success: {:ok, leftover} when is_binary(leftover)
  Error: {:error, reason}
  """
  def passify(socket) do
    with :ok <- setopts(socket, active: false),
      do: passify_h(socket, "")
  end
  defp passify_h(socket, acc) do
    receive do
      {Socket, ^socket, msg} ->
	case msg do
	  {:data, data} -> passify_h(socket, acc <> data)
	  :closed -> {:error, {:closed, acc}}
	  {:error, reason} -> {:error, reason}
	end
    after 0 -> {:ok, acc}
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
