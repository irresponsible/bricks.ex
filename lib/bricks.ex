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
  defprotocolEx ToIoData do
    def to_iodata(self)
  end

  defdelegate to_iodata(thing), to: Bricks.ToIoData

end
