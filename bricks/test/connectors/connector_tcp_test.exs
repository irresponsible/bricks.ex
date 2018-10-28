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

defmodule Bricks.Connector.TcpTest do
  use ExUnit.Case
  use ExUnitProperties
  alias Bricks.{Connector, Gen, Socket}
  alias Bricks.Error.{BadCombo, BadOption}
  import Bricks.Test.Services
  alias Bricks.Connector.Tcp
  import Bricks.Guards

  describe "options validation" do
    property "host" do
      check all yes <- Gen.host(),
                no <- Gen.anything_but(&host?/1) do
        assert {:ok, tcp} = Tcp.create(%{host: yes, port: 1})
        assert tcp.connector.host == yes
        err = BadOption.new(:host, no, [:binary, :ipv4, :ipv6])
        assert {:error, err} == Tcp.create(%{host: no})
      end

      err = BadOption.new(:host, nil, [:binary, :ipv4, :ipv6])
      assert {:error, err} == Tcp.create(%{})
    end

    property "port" do
      check all yes <- Gen.port(),
                no <- Gen.anything_but(&is_port_num/1) do
        assert {:ok, tcp} = Tcp.create(%{host: "", port: yes})
        assert tcp.connector.port == yes
        err = BadOption.new(:port, no, [:pos_int])
        assert {:error, err} == Tcp.create(%{host: "", port: no})
      end

      err = BadOption.new(:port, nil, [:pos_int])
      assert {:error, err} == Tcp.create(%{host: ""})
    end

    property "timeouts" do
      for field <- [:connect_timeout, :receive_timeout] do
        check all yes <- Gen.timeout(),
                  no <- Gen.anything_but(&is_timeout/1) do
          assert {:ok, tcp} = Tcp.create(%{:host => "", :port => 1, field => yes})
          assert Map.fetch!(tcp.connector, field) == yes
          err = BadOption.new(field, no, [:infinity, :non_neg_int])
          assert {:error, err} == Tcp.create(%{:host => "", :port => 1, field => no})
        end

        assert {:ok, tcp} = Tcp.create(%{host: "", port: 1})
        assert Map.fetch!(tcp.connector, field) == 5000
      end

      check all yes <- Gen.timeout(),
                no <- Gen.anything_but(&is_timeout/1) do
        assert {:ok, tcp} = Tcp.create(%{:host => "", :port => 1, :send_timeout => yes})
        assert Keyword.fetch!(tcp.connector.tcp_opts, :send_timeout) == yes
        err = BadOption.new(:send_timeout, no, [:infinity, :non_neg_int])
        assert {:error, err} == Tcp.create(%{:host => "", :port => 1, :send_timeout => no})
      end

      assert {:ok, tcp} = Tcp.create(%{:host => "", :port => 1})
      assert Keyword.fetch!(tcp.connector.tcp_opts, :send_timeout) == 5000
    end

    property "bam window" do
      check all yes <- Gen.window(),
                no <- Gen.anything_but(&is_window/1) do
        assert {:ok, tcp} = Tcp.create(%{:host => "", :port => 1, :bam_window => yes})
        assert tcp.connector.bam_window == yes
        err = BadOption.new(:bam_window, no, [:once, :pos_int])
        assert {:error, err} == Tcp.create(%{:host => "", :port => 1, :bam_window => no})
      end

      assert {:ok, tcp} = Tcp.create(%{:host => "", :port => 1})
      assert tcp.connector.bam_window == 10
    end

    property "active" do
      check all yes <- Gen.active(),
                no <- Gen.anything_but(&is_active/1) do
        assert {:ok, tcp} = Tcp.create(%{:host => "", :port => 1, :active => yes})
        assert tcp.connector.active == yes
        err = BadOption.new(:active, no, [:bool, :integer, :once])
        assert {:error, err} == Tcp.create(%{:host => "", :port => 1, :active => no})
      end

      assert {:ok, tcp} = Tcp.create(%{:host => "", :port => 1})
      assert tcp.connector.active == false
    end

    property "ip versions" do
      check all no <- Gen.anything_but(&is_boolean/1) do
        err = BadOption.new(:ipv4?, no, [:bool])
        assert {:error, err} == Tcp.create(%{host: "", port: 1, ipv4?: no})
        err = BadOption.new(:ipv6?, no, [:bool])
        assert {:error, err} == Tcp.create(%{host: "", port: 1, ipv6?: no})
      end

      assert {:ok, tcp} = Tcp.create(%{host: "", port: 1, ipv4?: true, ipv6?: false})
      opts = tcp.connector.tcp_opts
      assert opts == [:inet, {:active, false}, {:mode, :binary}, {:send_timeout, 5000}]

      assert {:ok, tcp} = Tcp.create(%{host: "", port: 1})
      opts = tcp.connector.tcp_opts
      assert opts == [:inet, {:active, false}, {:mode, :binary}, {:send_timeout, 5000}]

      assert {:ok, tcp} = Tcp.create(%{host: "", port: 1, ipv4?: true, ipv6?: true})
      opts = tcp.connector.tcp_opts
      assert opts == [:inet6, {:active, false}, {:mode, :binary}, {:send_timeout, 5000}]
      assert {:ok, tcp} = Tcp.create(%{host: "", port: 1, ipv6?: true})
      opts = tcp.connector.tcp_opts
      assert opts == [:inet6, {:active, false}, {:mode, :binary}, {:send_timeout, 5000}]

      assert {:ok, tcp} = Tcp.create(%{host: "", port: 1, ipv4?: false, ipv6?: true})
      opts = tcp.connector.tcp_opts

      assert opts == [
               :inet6,
               {:ipv6_v6only, true},
               {:active, false},
               {:mode, :binary},
               {:send_timeout, 5000}
             ]

      err = BadCombo.new(%{ipv4?: false, ipv6?: false}, "May not both be false")
      assert {:error, err} == Tcp.create(%{host: "", port: 1, ipv4?: false, ipv6?: false})
    end

    property "binary" do
      check all no <- Gen.anything_but(&is_boolean/1) do
        err = BadOption.new(:binary?, no, [:bool])
        assert {:error, err} == Tcp.create(%{host: "", port: 1, binary?: no})
      end

      assert {:ok, tcp} = Tcp.create(%{host: "", port: 1})
      opts = tcp.connector.tcp_opts
      assert opts == [:inet, {:active, false}, {:mode, :binary}, {:send_timeout, 5000}]

      assert {:ok, tcp} = Tcp.create(%{host: "", port: 1, binary?: true})
      opts = tcp.connector.tcp_opts
      assert opts == [:inet, {:active, false}, {:mode, :binary}, {:send_timeout, 5000}]

      assert {:ok, tcp} = Tcp.create(%{host: "", port: 1, binary?: false})
      opts = tcp.connector.tcp_opts
      assert opts == [:inet, {:active, false}, {:mode, :list}, {:send_timeout, 5000}]
    end

    test "raw" do
      check all x <- term(),
                y <- term(),
                z <- term(),
                no <-
                  StreamData.filter(StreamData.list_of(term(), max_length: 5), fn x ->
                    Enum.count(x) != 3
                  end) do
        no = List.to_tuple(no)
        err = BadOption.new(:raw, no, [:see_docs])
        assert {:error, err} == Tcp.create(%{host: "", port: 1, raw: no})
        assert {:ok, unix} = Tcp.create(%{host: "", port: 1, raw: {x, y, z}})

        assert unix.connector.tcp_opts == [
                 :inet,
                 {:raw, x, y, z},
                 {:active, false},
                 {:mode, :binary},
                 {:send_timeout, 5000}
               ]
      end
    end

    property "booleans" do
      fields = [
        delay_send?: :delay_send,
        dont_route?: :dontroute,
        exit_on_close?: :exit_on_close,
        keepalive?: :keepalive,
        nodelay?: :nodelay,
        receive_tclass?: :recvtclass,
        receive_tos?: :recvtos,
        receive_ttl?: :recvttl,
        reuse_addr?: :reuseaddr,
        send_timeout_close?: :send_timeout_close,
        show_econnreset?: :show_econnreset
      ]

      check all yes <- Gen.bool(),
                no <- Gen.anything_but(&is_boolean/1) do
        for {old, new} <- fields do
          assert {:ok, tcp} = Tcp.create(%{:host => "", :port => 1, old => yes})
          assert Keyword.fetch!(tcp.connector.tcp_opts, new) == yes
          err = BadOption.new(old, no, [:bool])
          assert {:error, err} == Tcp.create(%{:host => "", :port => 1, old => no})
          assert {:ok, tcp} = Tcp.create(%{:host => "", :port => 1})
          assert :error = Keyword.fetch(tcp.connector.tcp_opts, new)
        end
      end
    end

    property "binaries" do
      fields = [
        bind_to_device: :bind_to_device,
        network_namespace: :netns
      ]

      check all yes <- Gen.alphanum_string(),
                no <- Gen.anything_but(&is_binary/1) do
        for {old, new} <- fields do
          assert {:ok, tcp} = Tcp.create(%{:host => "", :port => 1, old => yes})
          assert Keyword.fetch!(tcp.connector.tcp_opts, new) == yes
          err = BadOption.new(old, no, [:binary])
          assert {:error, err} == Tcp.create(%{:host => "", :port => 1, old => no})
          assert {:ok, tcp} = Tcp.create(%{:host => "", :port => 1})
          assert :error = Keyword.fetch(tcp.connector.tcp_opts, new)
        end
      end
    end

    property "ints" do
      simple = [:buffer, :priority, :tos, :tclass, :high_watermark, :low_watermark]

      renamed = [
        header_size: :header,
        raw_fd: :fd,
        receive_buffer: :recbuf,
        send_buffer: :sndbuf
      ]

      pos = [:packet_size, :high_msgq_watermark, :low_msgq_watermark]

      check all yes <- Gen.non_neg_int(),
                no <- Gen.anything_but(&is_active/1) do
        for field <- simple do
          assert {:ok, tcp} = Tcp.create(%{:host => "", :port => 1, field => yes})
          assert Keyword.fetch!(tcp.connector.tcp_opts, field) == yes
          err = BadOption.new(field, no, [:non_neg_int])
          assert {:error, err} == Tcp.create(%{:host => "", :port => 1, field => no})
          assert {:ok, tcp} = Tcp.create(%{:host => "", :port => 1})
          assert :error = Keyword.fetch(tcp.connector.tcp_opts, field)
        end

        for {old, new} <- renamed do
          assert {:ok, tcp} = Tcp.create(%{:host => "", :port => 1, old => yes})
          assert Keyword.fetch!(tcp.connector.tcp_opts, new) == yes
          err = BadOption.new(old, no, [:non_neg_int])
          assert {:error, err} == Tcp.create(%{:host => "", :port => 1, old => no})
          assert {:ok, tcp} = Tcp.create(%{:host => "", :port => 1})
          assert :error = Keyword.fetch(tcp.connector.tcp_opts, new)
        end

        for field <- pos do
          assert {:ok, tcp} = Tcp.create(%{:host => "", :port => 1, field => yes + 1})
          assert Keyword.fetch!(tcp.connector.tcp_opts, field) == yes + 1
          err = BadOption.new(field, no, [:pos_int])
          assert {:error, err} == Tcp.create(%{:host => "", :port => 1, field => no})
          assert {:ok, tcp} = Tcp.create(%{:host => "", :port => 1})
          assert :error = Keyword.fetch(tcp.connector.tcp_opts, field)
        end
      end
    end

    property "line delimiter" do
      check all yes <- Gen.char(),
                no <- Gen.anything_but(&char?/1) do
        assert {:ok, tcp} = Tcp.create(%{host: "", port: 1, line_delimiter: yes})
        assert yes == Keyword.fetch!(tcp.connector.tcp_opts, :line_delimiter)
        err = BadOption.new(:line_delimiter, no, [:char])
        assert {:error, err} == Tcp.create(%{host: "", port: 1, line_delimiter: no})
      end

      assert {:ok, tcp} = Tcp.create(%{host: "", port: 1})
      assert :error == Keyword.fetch(tcp.connector.tcp_opts, :line_delimiter)
    end

    property "linger" do
      check all yes <- Gen.linger(),
                no <- Gen.anything_but(&linger?/1) do
        assert {:ok, tcp} = Tcp.create(%{host: "", port: 1, linger: yes})
        assert yes == Keyword.fetch!(tcp.connector.tcp_opts, :linger)
        err = BadOption.new(:linger, no, [:see_docs])
        assert {:error, err} == Tcp.create(%{host: "", port: 1, linger: no})
      end

      assert {:ok, tcp} = Tcp.create(%{host: "", port: 1})
      assert :error == Keyword.fetch(tcp.connector.tcp_opts, :linger)
    end

    property "local_port" do
      check all yes <- Gen.port(),
                no <- Gen.anything_but(&port?/1) do
        assert {:ok, tcp} = Tcp.create(%{host: "", port: 1, local_port: yes})
        assert yes == Keyword.fetch!(tcp.connector.tcp_opts, :port)
        err = BadOption.new(:local_port, no, [:non_neg_int])
        assert {:error, err} == Tcp.create(%{host: "", port: 1, local_port: no})
      end

      assert {:ok, tcp} = Tcp.create(%{host: "", port: 1})
      assert :error == Keyword.fetch(tcp.connector.tcp_opts, :ip)
    end

    property "network interface" do
      check all yes <- Gen.host(),
                no <- Gen.anything_but(&host?/1) do
        assert {:ok, tcp} = Tcp.create(%{host: "", port: 1, network_interface: yes})

        case is_binary(yes) do
          true -> assert String.to_charlist(yes) == Keyword.fetch!(tcp.connector.tcp_opts, :ip)
          false -> assert yes == Keyword.fetch!(tcp.connector.tcp_opts, :ip)
        end

        err = BadOption.new(:network_interface, no, [:binary, :ip])
        assert {:error, err} == Tcp.create(%{host: "", port: 1, network_interface: no})
      end

      assert {:ok, tcp} = Tcp.create(%{host: "", port: 1})
      assert :error == Keyword.fetch(tcp.connector.tcp_opts, :ip)
    end

    property "packet type" do
      check all yes <- Gen.packet_type(),
                no <- Gen.anything_but(&packet_type?/1) do
        assert {:ok, tcp} = Tcp.create(%{host: "", port: 1, packet_type: yes})
        assert yes == Keyword.fetch!(tcp.connector.tcp_opts, :packet)
        err = BadOption.new(:packet_type, no, [:raw, 1, 2, 4])
        assert {:error, err} == Tcp.create(%{host: "", port: 1, packet_type: no})
      end

      assert {:ok, tcp} = Tcp.create(%{host: "", port: 1})
      assert :error == Keyword.fetch(tcp.connector.tcp_opts, :packet)
    end

    property "tcp module" do
      check all yes <- StreamData.atom(:alphanumeric),
                no <- Gen.anything_but(&is_atom/1) do
        assert {:ok, tcp} = Tcp.create(%{host: "", port: 1, tcp_module: yes})
        assert yes == Keyword.fetch!(tcp.connector.tcp_opts, :tcp_module)
        err = BadOption.new(:tcp_module, no, [:atom])
        assert {:error, err} == Tcp.create(%{host: "", port: 1, tcp_module: no})
      end

      assert {:ok, tcp} = Tcp.create(%{host: "", port: 1})
      assert :error == Keyword.fetch(tcp.connector.tcp_opts, :tcp_module)
    end

    property "tcp opts" do
      check all yes <- StreamData.list_of(term(), max_length: 3),
                no <- Gen.anything_but(&is_list/1) do
        assert {:ok, tcp} = Tcp.create(%{host: "", port: 1, tcp_opts: yes})
        new_opts = tcp.connector.tcp_opts
        l1 = Enum.count(new_opts)
        l2 = Enum.count(yes)
        last = Enum.drop(new_opts, l1 - l2)
        assert last == yes
        err = BadOption.new(:tcp_opts, no, [:proplist])
        assert {:error, err} == Tcp.create(%{host: "", port: 1, tcp_opts: no})
      end

      assert {:ok, tcp} = Tcp.create(%{host: "", port: 1})
      new_opts = tcp.connector.tcp_opts
      assert new_opts == [:inet, {:active, false}, {:mode, :binary}, {:send_timeout, 5000}]
    end
  end

  describe "connecting" do
    test "echo passive" do
      {:ok, port, _pid} = echo_tcp()
      {:ok, tcp} = Tcp.create(%{host: {127, 0, 0, 1}, port: port, active: false})
      {:ok, sock} = Connector.connect(tcp)
      :ok = Socket.send_data(sock, "hello world\n")
      {:ok, "hello world\n", sock} = Socket.recv(sock, 0, 1000)
      Socket.close(sock)
      # check closed
      {:error, :einval} = :inet.port(sock.handle)
    end

    test "echo active" do
      {:ok, port, _pid} = echo_tcp()
      {:ok, tcp} = Tcp.create(%{host: {127, 0, 0, 1}, port: port, active: true})
      {:ok, sock} = Connector.connect(tcp)
      :ok = Socket.send_data(sock, "hello world\n")
      %Socket{handle: h} = sock
      assert_receive {:tcp, ^h, "hello world\n"}, 1000
      Socket.close(sock)
      # check closed
      {:error, :einval} = :inet.port(sock.handle)
    end

    test "recv passive" do
      {:ok, port, _pid} = echo_tcp()
      {:ok, tcp} = Tcp.create(%{host: {127, 0, 0, 1}, port: port, active: false})
      {:ok, sock} = Connector.connect(tcp)
      :ok = Socket.send_data(sock, "hello world\n")
      {:ok, "hello world\n", _sock} = Socket.recv(sock, 0, 1000)
      {:ok, port, _pid} = echo_tcp()
      {:ok, tcp} = Tcp.create(%{host: {127, 0, 0, 1}, port: port, active: false, ipv6?: false})
      {:ok, sock} = Connector.connect(tcp)
      :ok = Socket.send_data(sock, "hello world\n")
      {:ok, "hello world\n", sock} = Socket.recv(sock, 0, 1000)
      Socket.close(sock)
      # check closed
      {:error, :einval} = :inet.port(sock.handle)
    end
  end
end
