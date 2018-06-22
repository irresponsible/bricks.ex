defmodule Bricks.Connector.Tcp do
  @enforce_keys [:host, :port, :tcp_opts, :step_timeout]
  defstruct @enforce_keys
  alias Bricks.Connector
  alias Bricks.Connector.Tcp
  import ProtocolEx
 
  @default_step_timeout 5000
  @default_tcp_opts [:binary]

  def new(host, port, step_timeout \\ @default_step_timeout, tcp_opts \\ @default_tcp_opts),
    do: %Tcp{ host: host, port: port, tcp_opts: tcp_opts, step_timeout: step_timeout }

  defimplEx TcpConnector, %Tcp{}, for: Connector do
    alias Bricks.Socket.Tcp
    def connect(tcp) do
      case :gen_tcp.connect(tcp.host, tcp.port, tcp.tcp_opts, tcp.step_timeout) do
	{:ok, socket} -> {:ok, Tcp.new(socket)}
	{:error, reason} -> {:error, {:tcp_connect, reason}}
      end
    end
  end
end
