# Copyright (c) 2018 James Laver
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule Bricks.Socket.TcpTest do
  use ExUnit.Case
  use ExUnitProperties
  alias Bricks.{Connector, Socket}
  import Bricks.Test.Services
  alias Bricks.Connector.{Tcp, Unix}
  alias Bricks.Test.Genserver.{Echo1, EchoOnce, Fixed1, FixedOnce}
  import Bricks.Sugar

  property "tcp echo passive" do
    {:ok, port, _pid} = echo_tcp()
    {:ok, tcp} = Tcp.create(%{host: {127, 0, 0, 1}, port: port, active: false})
    {:ok, sock} = Connector.connect(tcp)

    check all d <- StreamData.binary(min_length: 1) do
      :ok = Socket.send_data(sock, d)
      {:ok, ^d, %Socket{}} = Socket.recv(sock, 0, 1000)
    end

    :gen_tcp.close(sock.handle)
  end

  property "tcp echo active" do
    {:ok, port, _pid} = echo_tcp()
    {:ok, tcp} = Tcp.create(%{host: {127, 0, 0, 1}, port: port, active: true})
    {:ok, sock} = Connector.connect(tcp)

    check all d <- StreamData.binary(min_length: 1) do
      :ok = Socket.send_data(sock, d)
      %Socket{handle: h} = sock
      assert_receive {:tcp, ^h, ^d}, 1000
    end

    :gen_tcp.close(sock.handle)
  end

  property "tcp echo active macros" do
    {:ok, port, _pid} = echo_tcp()
    {:ok, tcp} = Tcp.create(%{host: {127, 0, 0, 1}, port: port, active: true})
    {:ok, sock} = Connector.connect(tcp)

    check all d <- StreamData.binary(min_length: 1) do
      :ok = Socket.send_data(sock, d)

      binding sock do
        assert_receive match_data(^d), 1000
      end
    end

    :gen_tcp.close(sock.handle)
  end

  property "tcp echo bounded active" do
    {:ok, port, _pid} = echo_tcp()
    {:ok, tcp} = Tcp.create(%{host: {127, 0, 0, 1}, port: port, bam_window: 1, active: false})
    {:ok, sock} = Connector.connect(tcp)

    check all d <- StreamData.binary(min_length: 1) do
      :ok = Socket.send_data(sock, d)
      {:ok, sock} = Socket.extend_active(sock)
      %Socket{handle: h} = sock
      assert_receive {:tcp_passive, ^h}, 1000
      assert_received {:tcp, ^h, ^d}, :late_data
    end

    :gen_tcp.close(sock.handle)
  end

  property "tcp echo bounded active macros " do
    {:ok, port, _pid} = echo_tcp()
    {:ok, tcp} = Tcp.create(%{host: {127, 0, 0, 1}, port: port, bam_window: 1, active: false})
    {:ok, sock} = Connector.connect(tcp)

    check all d <- StreamData.binary(min_length: 1) do
      :ok = Socket.send_data(sock, d)
      {:ok, sock} = Socket.extend_active(sock)

      binding sock do
        assert_receive match_passive(), 1000
        assert_received match_data(^d), :late_data
      end
    end

    :gen_tcp.close(sock.handle)
  end

  property "tcp echo bounded active genserver 1" do
    {:ok, port, pid} = echo_tcp()
    {:ok, tcp} = Tcp.create(%{host: {127, 0, 0, 1}, port: port, bam_window: 1, active: false})
    {:ok, echo} = Echo1.start_link([tcp, self()])

    check all d <- StreamData.binary(min_length: 1) do
      :ok = Echo1.send_data(echo, d)
      assert_receive {:data, ^d}, 1000
    end

    send(pid, :close)
    assert_receive :closed, 3000
  end

  property "tcp echo bounded active genserver once" do
    {:ok, port, pid} = echo_tcp()
    {:ok, tcp} = Tcp.create(%{host: {127, 0, 0, 1}, port: port, bam_window: :once, active: false})
    {:ok, echo} = EchoOnce.start_link([tcp, self()])

    check all d <- StreamData.binary(min_length: 1) do
      :ok = EchoOnce.send_data(echo, d)
      assert_receive {:data, ^d}, 1000
    end

    send(pid, :close)
    assert_receive :closed, 3000
  end

  property "unix echo passive" do
    {:ok, path, _pid} = echo_unix()
    {:ok, unix} = Unix.create(path)
    {:ok, sock} = Connector.connect(unix)
    {:ok, "", sock} = Socket.passify(sock)

    check all d <- StreamData.binary(min_length: 1) do
      :ok = Socket.send_data(sock, d)
      {:ok, ^d, %Socket{}} = Socket.recv(sock, 0, 1000)
    end

    :gen_tcp.close(sock.handle)
  end

  property "unix echo active" do
    {:ok, path, _pid} = echo_unix()
    {:ok, unix} = Unix.create(path)
    {:ok, sock} = Connector.connect(unix)
    {:ok, sock} = Socket.set_active(sock, true)

    check all d <- StreamData.binary(min_length: 1) do
      :ok = Socket.send_data(sock, d)
      %Socket{handle: h} = sock
      assert_receive {:tcp, ^h, ^d}, 1000
    end

    :gen_tcp.close(sock.handle)
  end

  property "unix echo bounded active" do
    {:ok, path, _pid} = echo_unix()
    {:ok, unix} = Unix.create(path, %{bam_window: 1})
    {:ok, sock} = Connector.connect(unix)
    {:ok, "", sock} = Socket.passify(sock)

    check all d <- StreamData.binary(min_length: 1) do
      :ok = Socket.send_data(sock, d)
      {:ok, sock} = Socket.extend_active(sock)
      %Socket{handle: h} = sock
      assert_receive {:tcp_passive, ^h}, 1000
      assert_received {:tcp, ^h, ^d}, :late_data
    end

    :gen_tcp.close(sock.handle)
  end

  @tag timeout: 5000
  property "unix echo bounded active genserver 1" do
    {:ok, path, pid} = echo_unix()
    {:ok, unix} = Unix.create(path, %{bam_window: 1})
    {:ok, echo} = Echo1.start_link([unix, self()])

    check all d <- StreamData.binary(min_length: 1) do
      :ok = Echo1.send_data(echo, d)
      assert_receive {:data, ^d}, 1000
    end

    send(pid, :close)
    assert_receive :closed, 3000
  end

  @tag timeout: 5000
  property "unix echo bounded active genserver once" do
    {:ok, path, pid} = echo_unix()
    {:ok, unix} = Unix.create(path, %{bam_window: :once})
    {:ok, echo} = EchoOnce.start_link([unix, self()])

    check all d <- StreamData.binary(min_length: 1) do
      :ok = EchoOnce.send_data(echo, d)
      assert_receive {:data, ^d}, 1000
    end

    send(pid, :close)
    assert_receive :closed, 3000
  end

  import Bricks.Test.Receivers

  property "tcp fixed passive" do
    check all data <- StreamData.list_of(StreamData.binary(min_length: 1), min_length: 1) do
      {:ok, port, _pid} = fixed_tcp(data)
      {:ok, tcp} = Tcp.create(%{host: {127, 0, 0, 1}, port: port, ipv6?: false})
      {:ok, sock} = Connector.connect(tcp)
      {:ok, "", sock} = Socket.passify(sock)
      all = Enum.join(data)
      ret = collect_bytes_passive("", sock, byte_size(all))
      assert all == ret
      :gen_tcp.close(sock.handle)
    end
  end

  property "tcp fixed active" do
    check all data <- StreamData.list_of(StreamData.binary(min_length: 1), min_length: 1) do
      {:ok, port, _pid} = fixed_tcp(data)
      {:ok, tcp} = Tcp.create(%{host: {127, 0, 0, 1}, port: port, ipv6?: false})
      {:ok, sock} = Connector.connect(tcp)
      {:ok, sock} = Socket.set_active(sock, true)
      all = Enum.join(data)
      ret = collect_bytes_active("", sock, byte_size(all))
      assert all == ret
      :gen_tcp.close(sock.handle)
    end
  end

  property "tcp fixed active macros" do
    check all data <- StreamData.list_of(StreamData.binary(min_length: 1), min_length: 1) do
      {:ok, port, _pid} = fixed_tcp(data)
      {:ok, tcp} = Tcp.create(%{host: {127, 0, 0, 1}, port: port, ipv6?: false})
      {:ok, sock} = Connector.connect(tcp)
      {:ok, sock} = Socket.set_active(sock, true)
      all = Enum.join(data)
      ret = collect_bytes_active_macros("", sock, byte_size(all))
      assert all == ret
      :gen_tcp.close(sock.handle)
    end
  end

  property "tcp fixed bounded active" do
    check all data <- StreamData.list_of(StreamData.binary(min_length: 1), min_length: 1) do
      {:ok, port, _pid} = fixed_tcp(data)
      {:ok, tcp} = Tcp.create(%{host: {127, 0, 0, 1}, port: port, bam_window: 1, ipv6?: false})
      {:ok, sock} = Connector.connect(tcp)
      {:ok, "", sock} = Socket.passify(sock)
      all = Enum.join(data)
      ret = collect_bytes_bounded("", sock, byte_size(all))
      assert all == ret
      :gen_tcp.close(sock.handle)
    end
  end

  property "tcp fixed bounded active macros" do
    check all data <- StreamData.list_of(StreamData.binary(min_length: 1), min_length: 1) do
      {:ok, port, _pid} = fixed_tcp(data)
      {:ok, tcp} = Tcp.create(%{host: {127, 0, 0, 1}, port: port, bam_window: 1, ipv6?: false})
      {:ok, sock} = Connector.connect(tcp)
      {:ok, "", sock} = Socket.passify(sock)
      all = Enum.join(data)
      ret = collect_bytes_bounded_macros("", sock, byte_size(all))
      assert all == ret
      :gen_tcp.close(sock.handle)
    end
  end

  @tag timeout: 5000
  property "tcp fixed bounded active genserver 1" do
    check all data <- StreamData.list_of(StreamData.binary(min_length: 1), min_length: 1) do
      all = Enum.join(data)
      {:ok, port, _pid} = fixed_tcp(data)
      {:ok, tcp} = Tcp.create(%{host: {127, 0, 0, 1}, port: port, bam_window: 1, ipv6?: false})
      {:ok, _fixed} = Fixed1.start_link([tcp, byte_size(all), self()])
      assert_receive {:data, ^all}, 3000
    end
  end

  @tag timeout: 5000
  property "tcp fixed bounded active genserver once" do
    check all data <- StreamData.list_of(StreamData.binary(min_length: 1), min_length: 1) do
      all = Enum.join(data)
      {:ok, port, _pid} = fixed_tcp(data)

      {:ok, tcp} =
        Tcp.create(%{host: {127, 0, 0, 1}, port: port, bam_window: :once, ipv6?: false})

      {:ok, _fixed} = FixedOnce.start_link([tcp, byte_size(all), self()])
      assert_receive {:data, ^all}, 3000
    end
  end

  property "unix fixed passive" do
    check all data <- StreamData.list_of(StreamData.binary(min_length: 1), min_length: 1) do
      {:ok, path, _pid} = fixed_unix(data)
      {:ok, tcp} = Unix.create(path)
      {:ok, sock} = Connector.connect(tcp)
      {:ok, "", sock} = Socket.passify(sock)
      all = Enum.join(data)
      ret = collect_bytes_passive("", sock, byte_size(all))
      assert all == ret
      :gen_tcp.close(sock.handle)
    end
  end

  property "unix fixed active" do
    check all data <- StreamData.list_of(StreamData.binary(min_length: 1), min_length: 1) do
      {:ok, path, _pid} = fixed_unix(data)
      {:ok, tcp} = Unix.create(path)
      {:ok, sock} = Connector.connect(tcp)
      {:ok, sock} = Socket.set_active(sock, true)
      all = Enum.join(data)
      ret = collect_bytes_active("", sock, byte_size(all))
      assert all == ret
      :gen_tcp.close(sock.handle)
    end
  end

  property "unix fixed bounded active" do
    check all data <- StreamData.list_of(StreamData.binary(min_length: 1), min_length: 1) do
      {:ok, path, _pid} = fixed_unix(data)
      {:ok, unix} = Unix.create(path, %{bam_window: 1})
      {:ok, sock} = Connector.connect(unix)
      {:ok, "", sock} = Socket.passify(sock)
      all = Enum.join(data)
      ret = collect_bytes_bounded("", sock, byte_size(all))
      assert all == ret
      :gen_tcp.close(sock.handle)
    end
  end

  property "unix fixed active macros" do
    check all data <- StreamData.list_of(StreamData.binary(min_length: 1), min_length: 1) do
      {:ok, path, _pid} = fixed_unix(data)
      {:ok, tcp} = Unix.create(path)
      {:ok, sock} = Connector.connect(tcp)
      {:ok, sock} = Socket.set_active(sock, true)
      all = Enum.join(data)
      ret = collect_bytes_active_macros("", sock, byte_size(all))
      assert all == ret
      :gen_tcp.close(sock.handle)
    end
  end

  property "unix fixed bounded active macros" do
    check all data <- StreamData.list_of(StreamData.binary(min_length: 1), min_length: 1) do
      {:ok, path, _pid} = fixed_unix(data)
      {:ok, unix} = Unix.create(path, %{bam_window: 1})
      {:ok, sock} = Connector.connect(unix)
      {:ok, "", sock} = Socket.passify(sock)
      all = Enum.join(data)
      ret = collect_bytes_bounded_macros("", sock, byte_size(all))
      assert all == ret
      :gen_tcp.close(sock.handle)
    end
  end

  @tag timeout: 5000
  property "unix fixed bounded active genserver 1" do
    check all data <- StreamData.list_of(StreamData.binary(min_length: 1), min_length: 1) do
      all = Enum.join(data)
      {:ok, path, _pid} = fixed_unix(data)
      {:ok, unix} = Unix.create(path, %{bam_window: 1})
      {:ok, _fixed} = Fixed1.start_link([unix, byte_size(all), self()])
      assert_receive {:data, ^all}, 3000
    end
  end

  @tag timeout: 5000
  property "unix fixed bounded active genserver once" do
    check all data <- StreamData.list_of(StreamData.binary(min_length: 1), min_length: 1) do
      all = Enum.join(data)
      {:ok, path, _pid} = fixed_unix(data)
      {:ok, unix} = Unix.create(path, %{bam_window: :once})
      {:ok, _fixed} = FixedOnce.start_link([unix, byte_size(all), self()])
      assert_receive {:data, ^all}, 3000
    end
  end
end
