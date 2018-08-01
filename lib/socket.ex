defmodule Bricks.Socket do
  alias Bricks.Socket
  alias Bricks.Error.Timeout

  @type socket :: any # FIXME

  @type packet :: charlist | binary | term

  @spec recv(socket :: socket, size :: size, timeout :: timeout) :: {:ok, packet} | {:error, term}
  when
    size: non_neg_integer,
    timeout: non_neg_integer

  @doc """
  Wait `timeout` milliseconds for a response the size of `bytes` from the socket.

  Note that this may read less than `size` bytes in the case that the stream is
  exhausted.
  """
  def recv(socket, size, timeout),
    do: GenServer.call(socket, {:recv, size, timeout}, timeout)

  @spec send_data(socket :: socket, data :: packet) :: :ok | {:error, reason}
  when reason: :closed | term

  @doc """
  Send binary data to the socket.
  """
  def send_data(socket, data),
    do: GenServer.call(socket, {:send, data})

  @spec getopts(socket :: socket, opts :: opts) :: {:ok, opt_values} | {:error, term}
  when opts: [term], opt_values: [term]

  @doc """
  Return the options the socket is using.
  """
  def getopts(socket, opts),
    do: GenServer.call(socket, {:getopts, opts})

  @spec setopts(socket :: socket, opts :: opts) :: :ok | {:error, term}
  when opts: [term]

  @doc """
  Overwrite the options for a socket.
  """
  def setopts(socket, opts) when is_list(opts),
    do: GenServer.call(socket, {:setopts, opts})

  @spec close(socket :: any) :: :ok

  # TODO: does this flush?
  @doc """
  Close a socket connection.
  """
  def close(socket),
    do: GenServer.call(socket, :close)

  @spec transfer!(socket :: any, to :: pid) :: :ok

  @doc """
  Transfer the socket to the given process. This will change the receiver
  of TCP events.
  """
  def transfer!(socket, to) when is_pid(to),
    do: GenServer.call(socket, {:transfer, to})

  @spec read(socket :: socket, limit :: limit, activity :: activity) :: {:ok, packet, activity}
  when
    limit: non_neg_integer,
    activity: boolean | nil

  def read(socket, limit, activity \\ nil, step_timeout \\ nil)

  def read(socket, limit, activity, nil),
    do: read(socket, limit, activity, 5000)

  def read(socket, limit, nil, step_timeout) do
    case active?(socket) do
      {:ok, activity} -> read(socket, limit, activity, step_timeout)
      {:error, reason} -> {:error, reason, nil}
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
          step_timeout -> {:error, Timeout.new(step_timeout)}
        end
    end
  end

  @spec actify(socket :: socket, times :: times) :: :ok | {:error, reason}
  when
    times: non_neg_integer | boolean,
    reason: {:invalid, :times} | term

  @doc """
  Turns the socket passive, clearing any active data out of the mailbox
  """
  def actify(socket, times \\ true)
  def actify(socket, times)
      when times === true or (is_integer(times) and times > 0),
      do: setopts(socket, active: times)

  def actify(_, _), do: {:error, {:invalid, :times}}

  @spec passify(socket :: socket) :: {:ok, packet} | {:error, reason}
  when reason: :closed | term

  @doc """
  Turns the socket passive, clearing any active data out of the mailbox
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
    after
      0 -> {:ok, acc}
    end
  end

  @spec active?(socket :: socket) :: {:ok, times} | {:error, term}
  when times: non_neg_integer | boolean

  @doc """
  Returns the current activity status of the socket
  """
  def active?(socket) do
    with {:ok, active: times} <- getopts(socket, [:active]),
         do: {:ok, times}
  end
end
