defmodule BricksTest.EchoServices do
  @test_sock "/tmp/bricks-test.sock"

  def echo_tcp(extra_opts \\ []) do
    {:ok, listen} = :gen_tcp.listen(0, [:binary | extra_opts])
    {:ok, port} = :inet.port(listen)
    spawn_link(fn -> echo(listen) end)
    {:ok, port}
  end

  def echo_unix() do
    case :file.delete(@test_sock) do # It's okay for it not to exist but nothing else
      :ok -> :ok
      {:error, :enoent} -> :ok
    end
    {:ok, listen} = :gen_tcp.listen(0, [:binary, {:ifaddr,{:local,@test_sock}}])
    spawn_link(fn -> echo(listen) end)
    {:ok, @test_sock}
  end

  # def echo_tls() do
  # end

  def echo(listen) do
    {:ok, socket} = :gen_tcp.accept(listen, 1000)
    receive do
      {:tcp, ^socket, data} -> :gen_tcp.send(socket, data)
    end
    :gen_tcp.close(socket)
  end
end
