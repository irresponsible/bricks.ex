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

defmodule Bricks.Connector.UnixTest do
  use ExUnit.Case
  use ExUnitProperties
  alias Bricks.{Connector, Gen, Socket}
  import Bricks.Test.Services
  import Bricks.Guards
  alias Bricks.Connector.Unix
  alias Bricks.Error.BadOption

  describe "options validation" do
    property "timeouts" do
      for field <- [:connect_timeout, :receive_timeout] do
        check all yes <- Gen.timeout(),
                  no <- Gen.anything_but(&is_timeout/1) do
          assert {:ok, unix} = Unix.create("", %{field => yes})
          assert Map.fetch!(unix.connector, field) == yes
          err = BadOption.new(field, no, [:infinity, :non_neg_int])
          assert {:error, err} == Unix.create("", %{field => no})
        end

        assert {:ok, unix} = Unix.create("", %{})
        assert Map.fetch!(unix.connector, field) == 3000
      end

      check all yes <- Gen.timeout(),
                no <- Gen.anything_but(&is_timeout/1) do
        assert {:ok, unix} = Unix.create("", %{:send_timeout => yes})
        assert Keyword.fetch!(unix.connector.tcp_opts, :send_timeout) == yes
        err = BadOption.new(:send_timeout, no, [:infinity, :non_neg_int])
        assert {:error, err} == Unix.create("", %{:send_timeout => no})
      end

      assert {:ok, unix} = Unix.create("", %{})
      assert Keyword.fetch!(unix.connector.tcp_opts, :send_timeout) == 3000
    end

    property "bam window" do
      check all yes <- Gen.window(),
                no <- Gen.anything_but(&is_window/1) do
        assert {:ok, unix} = Unix.create("", %{:bam_window => yes})
        assert unix.connector.bam_window == yes
        err = BadOption.new(:bam_window, no, [:once, :pos_int])
        assert {:error, err} == Unix.create("", %{:bam_window => no})
      end

      assert {:ok, unix} = Unix.create("", %{})
      assert unix.connector.bam_window == 10
    end

    property "active" do
      check all yes <- Gen.active(),
                no <- Gen.anything_but(&is_active/1) do
        assert {:ok, unix} = Unix.create("", %{:active => yes})
        assert unix.connector.active == yes
        err = BadOption.new(:active, no, [:bool, :integer, :once])
        assert {:error, err} == Unix.create("", %{:active => no})
      end

      assert {:ok, unix} = Unix.create("", %{})
      assert unix.connector.active == false
    end

    property "binary" do
      check all no <- Gen.anything_but(&is_boolean/1) do
        err = BadOption.new(:binary?, no, [:bool])
        assert {:error, err} == Unix.create("", %{binary?: no})
      end

      assert {:ok, unix} = Unix.create("", %{})
      opts = unix.connector.tcp_opts
      assert opts == [active: false, mode: :binary, send_timeout: 3000]

      assert {:ok, unix} = Unix.create("", %{binary?: true})
      opts = unix.connector.tcp_opts
      assert opts == [active: false, mode: :binary, send_timeout: 3000]

      assert {:ok, unix} = Unix.create("", %{binary?: false})
      opts = unix.connector.tcp_opts
      assert opts == [active: false, mode: :list, send_timeout: 3000]
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
        assert {:error, err} == Unix.create("", %{raw: no})
        assert {:ok, unix} = Unix.create("", %{raw: {x, y, z}})

        assert unix.connector.tcp_opts == [
                 {:raw, x, y, z},
                 {:active, false},
                 {:mode, :binary},
                 {:send_timeout, 3000}
               ]
      end
    end

    property "booleans" do
      fields = [
        delay_send?: :delay_send,
        exit_on_close?: :exit_on_close,
        send_timeout_close?: :send_timeout_close
      ]

      check all yes <- Gen.bool(),
                no <- Gen.anything_but(&is_boolean/1) do
        for {old, new} <- fields do
          assert {:ok, unix} = Unix.create("", %{old => yes})
          assert Keyword.fetch!(unix.connector.tcp_opts, new) == yes
          err = BadOption.new(old, no, [:bool])
          assert {:error, err} == Unix.create("", %{old => no})
          assert {:ok, unix} = Unix.create("", %{})
          assert :error = Keyword.fetch(unix.connector.tcp_opts, new)
        end
      end
    end

    property "binaries" do
      fields = [
        bind_to_device: :bind_to_device
      ]

      check all yes <- Gen.alphanum_string(),
                no <- Gen.anything_but(&is_binary/1) do
        for {old, new} <- fields do
          assert {:ok, unix} = Unix.create("", %{old => yes})
          assert Keyword.fetch!(unix.connector.tcp_opts, new) == yes
          err = BadOption.new(old, no, [:binary])
          assert {:error, err} == Unix.create("", %{old => no})
          assert {:ok, unix} = Unix.create("", %{})
          assert :error = Keyword.fetch(unix.connector.tcp_opts, new)
        end
      end
    end

    property "ints" do
      simple = [:buffer, :priority, :high_watermark, :low_watermark]

      renamed = [
        header_size: :header,
        raw_fd: :fd,
        send_buffer: :sndbuf
      ]

      pos = [:packet_size, :high_msgq_watermark, :low_msgq_watermark]

      check all yes <- Gen.non_neg_int(),
                no <- Gen.anything_but(&is_active/1) do
        for field <- simple do
          assert {:ok, unix} = Unix.create("", %{field => yes})
          assert Keyword.fetch!(unix.connector.tcp_opts, field) == yes
          err = BadOption.new(field, no, [:non_neg_int])
          assert {:error, err} == Unix.create("", %{field => no})
          assert {:ok, unix} = Unix.create("", %{})
          assert :error = Keyword.fetch(unix.connector.tcp_opts, field)
        end

        for {old, new} <- renamed do
          assert {:ok, unix} = Unix.create("", %{old => yes})
          assert Keyword.fetch!(unix.connector.tcp_opts, new) == yes
          err = BadOption.new(old, no, [:non_neg_int])
          assert {:error, err} == Unix.create("", %{old => no})
          assert {:ok, unix} = Unix.create("", %{})
          assert :error = Keyword.fetch(unix.connector.tcp_opts, new)
        end

        for field <- pos do
          assert {:ok, unix} = Unix.create("", %{field => yes + 1})
          assert Keyword.fetch!(unix.connector.tcp_opts, field) == yes + 1
          err = BadOption.new(field, no, [:pos_int])
          assert {:error, err} == Unix.create("", %{field => no})
          assert {:ok, unix} = Unix.create("", %{})
          assert :error = Keyword.fetch(unix.connector.tcp_opts, field)
        end
      end
    end

    property "line delimiter" do
      check all yes <- Gen.char(),
                no <- Gen.anything_but(&char?/1) do
        assert {:ok, unix} = Unix.create("", %{line_delimiter: yes})
        assert yes == Keyword.fetch!(unix.connector.tcp_opts, :line_delimiter)
        err = BadOption.new(:line_delimiter, no, [:char])
        assert {:error, err} == Unix.create("", %{line_delimiter: no})
      end

      assert {:ok, unix} = Unix.create("", %{})
      assert :error == Keyword.fetch(unix.connector.tcp_opts, :line_delimiter)
    end

    property "packet type" do
      check all yes <- Gen.packet_type(),
                no <- Gen.anything_but(&packet_type?/1) do
        assert {:ok, unix} = Unix.create("", %{packet_type: yes})
        assert yes == Keyword.fetch!(unix.connector.tcp_opts, :packet)
        err = BadOption.new(:packet_type, no, [:raw, 1, 2, 4])
        assert {:error, err} == Unix.create("", %{packet_type: no})
      end

      assert {:ok, unix} = Unix.create("", %{})
      assert :error == Keyword.fetch(unix.connector.tcp_opts, :packet)
    end

    property "tcp module" do
      check all yes <- StreamData.atom(:alphanumeric),
                no <- Gen.anything_but(&is_atom/1) do
        assert {:ok, unix} = Unix.create("", %{tcp_module: yes})
        assert yes == Keyword.fetch!(unix.connector.tcp_opts, :tcp_module)
        err = BadOption.new(:tcp_module, no, [:atom])
        assert {:error, err} == Unix.create("", %{tcp_module: no})
      end

      assert {:ok, unix} = Unix.create("", %{})
      assert :error == Keyword.fetch(unix.connector.tcp_opts, :tcp_module)
    end

    property "tcp opts" do
      check all yes <- StreamData.list_of(term(), max_length: 3),
                no <- Gen.anything_but(&is_list/1) do
        assert {:ok, unix} = Unix.create("", %{tcp_opts: yes})
        new_opts = unix.connector.tcp_opts
        l1 = Enum.count(new_opts)
        l2 = Enum.count(yes)
        last = Enum.drop(new_opts, l1 - l2)
        assert last == yes
        err = BadOption.new(:tcp_opts, no, [:proplist])
        assert {:error, err} == Unix.create("", %{tcp_opts: no})
      end

      assert {:ok, unix} = Unix.create("", %{})
      new_opts = unix.connector.tcp_opts
      assert new_opts == [active: false, mode: :binary, send_timeout: 3000]
    end
  end

  describe "connecting" do
    test "echo" do
      {:ok, path, _pid} = echo_unix()
      {:ok, unix} = Unix.create(path)
      {:ok, sock} = Connector.connect(unix)
      {:ok, "", sock} = Socket.passify(sock)
      :ok = Socket.send_data(sock, "hello world\n")
      {:ok, "hello world\n", %Socket{}} = Socket.recv(sock, 0, 1000)
    end
  end
end
