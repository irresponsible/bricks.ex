defmodule Bricks do
  import ProtocolEx
  defprotocolEx Client do
    def connect(client)
    def done(client, socket)
    def error(client, socket)
  end
  defprotocolEx Connector do
    def connect(self)
  end
  defprotocolEx Socket do
    def socket(socket)
    def send_data(socket, data)
    def recv_passive(socket), do: recv_passive(socket, 0, nil)
    def recv_passive(socket, size), do: recv_passive(socket, size, nil)
    def recv_passive(socket, size, timeout)
    def recv_active(socket), do: recv_active(socket, nil)
    def recv_active(socket, timeout)
    def getopts(self, opts)
    def setopts(self, opts)
    def transfer(socket, pid)
    def close(socket)
  end

  defprotocolEx ToIoData do
    def to_iodata(self)
  end
end
defmodule Bricks.Sockets do
  alias Bricks.Socket

  def actify(socket, times \\ true)
  def actify(socket, times)
  when times === true or (is_integer(times) and times > 0 ),
    do: Socket.setopts(socket, [{:active, times}])
  def actify(_, _), do: {:error, {:invalid, :times}}

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
end

