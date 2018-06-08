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
