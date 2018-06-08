defmodule Bricks.Socket.Tcp do
  @enforce_keys [:socket, :step_timeout]
  defstruct @enforce_keys
  alias Bricks.Socket.Tcp

  @default_step_timeout 5000
  def new(socket, step_timeout \\ @default_step_timeout),
    do: %Tcp{socket: socket, step_timeout: step_timeout}
end

import ProtocolEx

alias Bricks.Socket
alias Bricks.Socket.Tcp # {Tcp, Tls}
defimplEx SocketTcp, %Tcp{}, for: Socket do
  @priority -1
  def socket(tcp), do: tcp.socket

  def send_data(tcp, data) do
    with {:error, reason} <- :gen_tcp.send(tcp.socket, data),
      do: {:error, {:tcp_send, reason}}
  end

  def recv_passive(tcp, size, timeout) do
    with {:error, reason} <- :gen_tcp.recv(tcp.socket, size, timeout),
      do: {:error, {:tcp_recv_passive, reason}}
  end

  def recv_active(tcp, timeout) do
    s = tcp.socket
    receive do
      {:tcp, ^s, data} -> {:ok, data}
      {:tcp_error, ^s, reason} -> {:error, {:tcp_receive_active, reason}}
      {:tcp_closed, ^s} -> {:error, {:tcp_receive_active, :closed}}
    after
      timeout -> {:error, :timeout}
    end
  end
  def getopts(tcp, opts) when is_list(opts) do
    with {:error, reason} <- :inet.getopts(tcp.socket, opts),
      do: {:error, {:tcp_getopts, reason}}
  end
  def setopts(tcp, opts) when is_list(opts) do
    with {:error, reason} <- :inet.setopts(tcp.socket, opts),
      do: {:error, {:tcp_setopts, reason}}
  end

  def transfer(tcp, pid) do
    with {:error, reason} <- :gen_tcp.controlling_process(tcp.socket, pid),
      do: {:error, {:tcp_transfer, reason}}
  end

  def close(tcp),
    do: :gen_tcp.close(tcp)

end
