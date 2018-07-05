defmodule Bricks.Socket.Tcp do
  @enforce_keys [:socket, :step_timeout, :owner]
  defstruct @enforce_keys
  alias Bricks.Socket
  alias Bricks.Socket.Tcp
  alias Bricks.Error.{Closed, Posix, Timeout}

  @default_step_timeout 5000
  defp new(socket, owner, step_timeout \\ @default_step_timeout),
    do: %Tcp{socket: socket, owner: owner, step_timeout: step_timeout}

  def start_link(socket, step_timeout) do
    me = self()
    case GenServer.start_link(__MODULE__, {socket, step_timeout, me}) do
      {:ok, who} ->
	:ok = :gen_tcp.controlling_process(socket, who)
	{:ok, who}
      other -> other
    end
  end

  # Callbacks

  def init({socket, step_timeout, owner}) do
    {:ok, new(socket, owner, step_timeout)}
  end

  ## Calls
  
  def handle_call({:getopts, opts}, _from, tcp) do
    case :inet.getopts(tcp.socket, opts) do
      {:ok, opts} -> {:reply, {:ok, opts}, tcp}
      {:error, reason} -> {:reply, {:error, Posix.new(reason)}, tcp}
    end
  end
  def handle_call({:setopts, opts}, _from, tcp) do
    case :inet.setopts(tcp.socket, opts) do
      :ok -> {:reply, :ok, tcp}
      {:error, reason} -> {:reply, {:error, Posix.new(reason)}, tcp}
    end
  end
  def handle_call({:recv, size, timeout}, _from, tcp) do
    case :gen_tcp.recv(tcp.socket, size, timeout) do
      {:ok, data} -> {:reply, {:ok, data}, tcp}
      {:error, :closed} -> {:reply, {:error, Closed.new()}, tcp}
      {:error, reason}  -> {:reply, {:error, Posix.new(reason)}, tcp}
    end
  end
  def handle_call({:send, data}, _from, tcp) do
    case :gen_tcp.send(tcp.socket, data) do
      :ok -> {:reply, :ok, tcp}
      {:error, :closed} -> {:reply, {:error, Closed.new()}, tcp}
      {:error, reason}  -> {:reply, {:error, Posix.new(reason)}, tcp}
    end
  end
  def handle_call(:close, _from, tcp) do
    ret = :gen_tcp.close(tcp.socket)
    {:reply, ret, tcp}
  end
  def handle_call({:transfer, to}, _from, tcp) do
    Process.link(to)
    {:reply, :ok, %{ tcp | owner: to }}
  end

  ## Infos

  def handle_info({:tcp, socket, data}, %Tcp{socket: s, owner: owner}=tcp) when socket === s do
    send owner, {Socket, self(), {:data, data}}
    {:noreply, tcp}
  end
  def handle_info({:tcp_error, socket, reason}, %Tcp{socket: s, owner: owner}=tcp) when socket === s do
    send owner, {Socket, self(), {:error, reason}}
    {:noreply, tcp}
  end
  def handle_info({:tcp_closed, socket}, %Tcp{socket: s, owner: owner}=tcp) when socket === s do
    send owner, {Socket, self(), :closed}
    {:noreply, tcp}
  end

end
