defmodule Bricks.Connector.Tcp do
  @enforce_keys [:host, :port, :tcp_opts, :step_timeout]
  defstruct @enforce_keys

  import ProtocolEx

  alias Bricks.Connector
  alias Bricks.Connector.Tcp

  @type ipv4 :: {0..255, 0..255, 0..255, 0..255}
  @type ipv6 :: {0..65535,
                 0..65535,
                 0..65535,
                 0..65535,
                 0..65535,
                 0..65535,
                 0..65535,
                 0..65535}

  @type hostname :: binary | ipv4 | ipv6

  @type t :: %Tcp{
    host: hostname,
    port: integer,
    tcp_opts: [any],
    step_timeout: integer
  }

  @default_tcp_opts [:binary]
  @default_step_timeout 5000

  @spec new(hostname, integer, integer, [any]) :: t

  @doc """
  Create a new TCP connector struct.

  Expects a hostname (or ipv4 address) and a port number, allowing an optional
  step timeout and a list of options to be passed to `:gen_tcp.connect`.
  """
  def new(host, port, step_timeout \\ @default_step_timeout, tcp_opts \\ @default_tcp_opts),
    do: %Tcp{ host: format_hostname(host),
              port: port,
              tcp_opts: tcp_opts,
              step_timeout: step_timeout }

  defp format_hostname(hostname) when is_binary(hostname) do
    hostname
    |> String.to_charlist
    |> :inet.parse_address
    |> case do
         {:ok, address} -> address
         _              -> hostname
       end
  end

  defp format_hostname(hostname),
    do: hostname

  defimplEx TcpConnector, %Tcp{}, for: Connector do
    alias Bricks.Socket.Tcp

    def connect(tcp) do
      case :gen_tcp.connect(tcp.host, tcp.port, tcp.tcp_opts, tcp.step_timeout) do
        {:ok, socket} -> Tcp.start_link(socket, tcp.step_timeout)
        {:error, reason} -> {:error, {:tcp_connect, reason}}
      end
    end

  end
end
