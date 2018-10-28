if Code.ensure_loaded?(StreamData) do
  defmodule Bricks.Gen do
    @moduledoc """
    StreamData generators for testing
    """

    @doc "Generates any term that doesn't pass the provided filter function"
    def anything_but(test) do
      StreamData.filter(StreamData.term(), fn x -> not test.(x) end)
    end

    @doc "booleans"
    def bool(), do: StreamData.member_of([true, false])

    @doc "bytes"
    def byte(), do: StreamData.integer(0..255)

    @doc "characters (0 to 0x10FF)"
    def char(), do: StreamData.integer(0..0x10FF)
    @doc "non-negative integers (0 to 0x10FF)"
    def non_neg_int(), do: StreamData.integer(0..0x10FF)
    @doc "positive integers (1 to 0x10FF)"
    def pos_int(), do: StreamData.integer(1..0x10FF)
    @doc "alphanumeric strings that are at least 1 long"
    def alphanum_string(), do: StreamData.string(:alphanumeric, min_length: 1)

    @doc "IPv4 Address"
    def ipv4() do
      StreamData.list_of(byte(), length: 4)
      |> StreamData.map(&List.to_tuple/1)
    end

    @doc "IPv6 Address"
    def ipv6() do
      StreamData.list_of(char(), length: 8)
      |> StreamData.map(&List.to_tuple/1)
    end

    @doc "IPv4 or IPv6 Address"
    def ip(), do: StreamData.one_of([ipv4(), ipv6()])

    @doc "An IP address or a hostname"
    def host(), do: StreamData.one_of([ipv4(), ipv6(), alphanum_string()])

    @doc "A network interface to connect to (IP address or binary path)"
    def network_interface(), do: host()

    @doc "A port number (0 to 65535)"
    def port(), do: StreamData.integer(0..65535)

    @doc "A timeout"
    def timeout() do
      StreamData.one_of([
        StreamData.integer(1..65535),
        StreamData.constant(:infinity)
      ])
    end

    @doc "An activity mode"
    def active() do
      StreamData.one_of([
        StreamData.integer(-32767..32766),
        StreamData.member_of([true, false, :once])
      ])
    end

    @doc "A BAM window"
    def window() do
      StreamData.one_of([
        StreamData.integer(0..65535),
        StreamData.constant(:once)
      ])
    end

    @doc "An option valid for `:deliver`"
    def deliver(), do: StreamData.member_of([:port, :term])

    def linger() do
      StreamData.fixed_list([bool(), pos_int()])
      |> StreamData.map(&List.to_tuple/1)
    end

    @doc "An erlang packet type"
    def packet_type(), do: StreamData.member_of([:raw, 1, 2, 4])
  end
end
