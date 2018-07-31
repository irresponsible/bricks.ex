defmodule Bricks.Connector.Unix do
  @enforce_keys [:path, :tcp_opts, :step_timeout]
  defstruct @enforce_keys

  import ProtocolEx

  alias Bricks.Connector
  alias Bricks.Connector.Unix

  @default_tcp_opts [:binary, {:active, false}]
  @default_step_timeout 3000

  def new(path, step_timeout \\ @default_step_timeout, tcp_opts \\ @default_tcp_opts),
    do: %Unix{path: path, tcp_opts: tcp_opts, step_timeout: step_timeout}

  defimplEx UnixConnector, %Unix{}, for: Connector do
    alias Bricks.Socket.Tcp

    def connect(unix) do
      case :gen_tcp.connect({:local, unix.path}, 0, unix.tcp_opts) do
        {:ok, socket} -> Tcp.start_link(socket, unix.step_timeout)
        {:error, reason} -> {:error, {:unix_connect, reason}}
      end
    end
  end
end
