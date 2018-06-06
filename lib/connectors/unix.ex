defmodule Bricks.Connector.Unix do
  @enforce_keys [:path, :tcp_opts]
  defstruct @enforce_keys
  alias Bricks.Connector
  alias Bricks.Connector.Unix
  import ProtocolEx
  @default_tcp_opts [:binary, {:active, false}]

  def new(path, tcp_opts \\ @default_tcp_opts),
    do: %Unix{path: path, tcp_opts: tcp_opts}

  defimplEx UnixConnector, %Unix{}, for: Connector do
    alias Bricks.Socket.Tcp
    def connect(unix) do
      case :gen_tcp.connect({:local, unix.path}, 0, unix.tcp_opts) do
	{:ok, socket} -> {:ok, Tcp.new(socket)}
	{:error, reason} -> {:error, {:unix_connect, reason}}
      end
    end
  end

end
