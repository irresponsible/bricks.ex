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

defmodule Bricks.Socket do
  @moduledoc """
  A Socket represents a *connected* Socket - that is it is
  manufactured *after* a connection has been established.

  As in Erlang/OTP, a Socket is owned by a single process, the
  owner. No other process may interact with the Socket, but the owner
  can hand off ownership to another process. If the owner dies, the
  socket will be closed.

  A Socket is at any given time (as per OTP) in one of these modes:

  - `passive` mode -  data can only be received when you call `recv`.

  - `active` mode - the socket transforms packets into messages as
    they arrive and transmits them to the owner.

  - `bounded active` mode - like `active` mode, but caps the number of
    packets that will be buffered in the owner mailbox before
    requiring a reset by the owner.

  You should not expect a Socket to be in a particular mode, rather
  you should explicitly set it when you receive the Socket with
  `set_active/2`. The default activity depends upon the type of Socket
  and probably the OTP release you're running under.

  ## Picking a mode

  - `passive` mode: *a safe default* when you don't have aggressive
    performance requirements. The kernel will buffer some amount of
    data and the rest will be rejected via (TCP) backpressure.

  - `active` mode: the process mailbox becomes an effectively
    unlimited sized buffer. If you fail to keep up, you might buffer
    until the BEAM has eaten all of the memory and gets killed. But
    while it doesn't, it's low latency and high throughput.
    *WARNING: I hope you know what you're doing, use bounded active*

  - `bounded active` mode: like active mode, but caps the number of
    packets that will be buffered in the owner mailbox. Achieves
    better performance than `passive` mode but without the risks
    associated with `active` mode.

  ## Bounded Active Mode

  In addition to taking a boolean value, `set_active` can take an
  integer, entering what I call `bounded active` mode (BAM).  BAM
  provides most of the performance benefits of `active` mode with the
  security of not having your BEAM get OOMkilled from overbuffering.
  If passive mode doesn't meet your needs, use BAM - avoid OOM!

  In BAM, the socket behaves as in `active` mode, sending messages
  that are received to the owner. However, it also maintains an
  internal `active window` counter of the number of packets that may
  be received in active mode, after which the socket is placed into
  passive mode and a notification message is sent to the owner who can
  put the socket back into BAM with `set_active/2`.

  The `bam_window` field in the `Socket` struct holds the intended active
  window. It is used by `extend_active/1` to easily reset BAM.

  ### BAM and setting active

  `set_active/2` can take the following values:
    - `true`  - enable `active` mode
    - `false` - enable `passive` mode
    - `:once` - enable BAM for one packet
    - `integer()` - adjust the internal active window counter by this
                    many, send a message to notify the owner when the
                    socket is made passive

  Note that while the first three all set the value, providing an
  integer can behave in two ways, depending on the current mode:

    - You are not in BAM, the active counter is *set* to this
      value. If it is lower than zero, the socket is made passive.

    - You are in BAM, the active counter is *adjusted by* this value
      (by addition). If you pass a negative number and cause the
      counter to go 0 or lower, the socket is made passive.

  We recommend only using `set_active/2` with a positive integer and
  when the socket is in passive mode (such as when you have been
  informed the socket has just been made passive). This simplifies the
  problem and you can pretend that it *does* set the internal counter.

  If you ignore the last paragraph, you'll have to keep track of the
  current active window to know what the new one will be after calling
  `set_active/2`. The (undocumented) `decr_active/1` function may be
  useful to call when you receive a packet.

  This behaviour is inherited from OTP. We would not choose to implement
  it this way ourselves.
  """

  @enforce_keys [
    :module,
    :host,
    :port,
    :handle,
    :active,
    :data_tag,
    :error_tag,
    :closed_tag,
    :passive_tag,
    :receive_timeout,
    :bam_window
  ]
  defstruct @enforce_keys

  alias Bricks.{Socket, Util}
  alias Bricks.Error.{BadOption, Closed, NotActive, Posix, UnknownOptions}
  import Bricks.Guards

  ## Defaults

  @default_bam_window 10

  ## Types

  @typedoc "The activity mode of the socket. See module documentation."
  @type active :: boolean() | :once | -32768..32767

  @typedoc "The type of data received from the socket. Depends upon socket binary mode"
  @type data :: binary() | charlist()

  @typedoc "An IPv4 address"
  @type ipv4 :: {byte(), byte(), byte(), byte()}

  @typedoc "An IPv6 address"
  @type ipv6 :: {char(), char(), char(), char(), char(), char(), char(), char()}

  @typedoc "An IPv4 or IPv6 address"
  @type ip :: ipv4() | ipv6()

  @typedoc "A host to connect to (or a filepath to a unix socket)"
  @type host :: binary() | ipv4() | ipv6()

  @typedoc "A port number"
  @type port_num :: pos_integer()

  @typedoc "The activity mode used for extending Bounded Active Mode"
  @type window :: :once | pos_integer()

  @typedoc "A connected socket"
  @type t :: %Socket{
          module: atom(),
          host: host(),
          port: port_num() | :local,
          handle: term(),
          active: active(),
          data_tag: atom(),
          error_tag: atom(),
          closed_tag: atom(),
          passive_tag: atom(),
          receive_timeout: timeout(),
          bam_window: window() | nil
        }

  @typedoc "Options provided to `new/1`"
  @type new_opts :: %{
          :module => atom(),
          :host => host(),
          :port => port_num(),
          :handle => term(),
          :active => active(),
          :data_tag => term(),
          :error_tag => term(),
          :closed_tag => term(),
          :passive_tag => term(),
          optional(:bam_window) => window(),
          optional(:receive_timeout) => timeout() | nil
        }

  @typedoc "The errors that `new/1` may return"
  @type new_error :: BadOption.t() | UnknownOptions.t()

  @spec new(new_opts()) :: {:ok, t()} | {:error, new_error()}
  @doc """
  Creates a new Socket from a map of options

  Required keys:
    - `module`:       callback module for the given socket tye
    - `handle`:       underlying reference to the socket
    - `active`:       current activity mode
    - `data_tag`:     tag used to identify a data message from the socket
    - `error_tag`:    tag used to identify an error message from the socket
    - `closed_tag`:   tag used to identify a closed message from the socket
    - `passive_tag`:  tag used to identify a passive message from the socket

  Optional keys:
    - `receive_timeout`: default timeout used for calls to `recv`
    - `bam_window`:      default active window to use for resetting bounded active mode
  """
  def new(
        %{
          module: module,
          host: host,
          port: port,
          handle: handle,
          active: active,
          data_tag: data_tag,
          error_tag: error_tag,
          closed_tag: closed_tag,
          passive_tag: passive_tag
        } = opts
      ) do
    receive_timeout = Map.get(opts, :receive_timeout, 5000)
    bam_window = Map.get(opts, :bam_window, @default_bam_window)

    extra =
      Map.keys(
        Map.drop(opts, [
          :module,
          :port,
          :handle,
          :active,
          :data_tag,
          :error_tag,
          :closed_tag,
          :passive_tag,
          :receive_timeout,
          :bam_window,
          :host
        ])
      )

    cond do
      [] != extra ->
        {:error, UnknownOptions.new(extra)}

      not host?(host) ->
        {:error, BadOption.new(:host, host, [:ipv4, :ipv6, :binary])}

      not is_atom(module) ->
        {:error, BadOption.new(:module, module, [:atom])}

      not is_atom(data_tag) ->
        {:error, BadOption.new(:data_tag, data_tag, [:atom])}

      not is_atom(error_tag) ->
        {:error, BadOption.new(:error_tag, error_tag, [:atom])}

      not is_atom(closed_tag) ->
        {:error, BadOption.new(:closed_tag, closed_tag, [:atom])}

      not is_atom(passive_tag) ->
        {:error, BadOption.new(:passive_tag, passive_tag, [:atom])}

      not is_active(active) ->
        {:error, BadOption.new(:active, active, [:bool, :non_neg_int, :once])}

      not is_timeout(receive_timeout) ->
        {:error, BadOption.new(:receive_timeout, receive_timeout, [:infinity, :non_neg_int])}

      not is_window(bam_window) ->
        {:error, BadOption.new(:bam_window, bam_window, [:once, :pos_integer])}

      true ->
        {:ok,
         %Socket{
           module: module,
           host: host,
           port: port,
           handle: handle,
           active: active,
           data_tag: data_tag,
           error_tag: error_tag,
           closed_tag: closed_tag,
           passive_tag: passive_tag,
           receive_timeout: receive_timeout,
           bam_window: bam_window
         }}
    end
  end

  # Functions for manipulating the struct directly

  @doc false
  @spec decr_active(t()) :: t()
  def decr_active(%Socket{active: active} = socket) do
    case active do
      1 -> tweak_active(socket, false)
      :once -> tweak_active(socket, false)
      n when is_integer(n) and n > 1 -> %{socket | active: active - 1}
      _ -> throw(NotActive.new())
    end
  end

  @doc false
  @spec tweak_active(t(), active()) :: t()
  def tweak_active(%Socket{} = socket, active), do: %{socket | active: active}

  # Receiving data

  @typedoc "The types of error `recv/1`, `recv/2` and `recv/3` may return"
  @type recv_error :: Closed.t() | Posix.t()

  @typedoc "The return of `recv/1`, `recv/2` and `recv/3`"
  @type recv_result :: {:ok, data(), t()} | {:error, recv_error()}

  @spec recv(t(), non_neg_integer()) :: recv_result()
  @doc """
  Receives all available data from the socket.
  Times out if the Socket's `receive_timeout` is breached.
  """
  def recv(%Socket{receive_timeout: timeout} = socket) do
    recv(socket, 0, timeout)
  end

  @doc """
  Receives data from the socket

  If the socket is not in raw mode (default) or `size` is zero:
    Receives all available data from the socket
  If the socket is in raw mode and `size` is not zero:
    Receives exactly `size` bytes of data from the socket

  Times out if the Socket's `receive_timeout` is breached.
  """
  def recv(%Socket{receive_timeout: timeout} = socket, size) do
    recv(socket, size, timeout)
  end

  @doc "Receive from the Socket"
  @callback recv(t(), non_neg_integer(), timeout()) :: recv_result()

  @spec recv(t(), non_neg_integer(), timeout()) :: recv_result()
  @doc """
  Receives data from the socket

  - If the socket is not in raw mode (default) or `size` is zero:
    Receives all available data from the socket
  - If the socket is in raw mode and `size` is not zero:
    Receives exactly `size` bytes of data from the socket

  Times out if `timeout` is breached.
  """
  def recv(%Socket{module: module, active: false} = socket, size, timeout) do
    apply(module, :recv, [socket, size, timeout])
  end

  # Sending data

  @typedoc "The errors `send_data/2` may return"
  @type send_error :: Closed.t() | Posix.t()

  @typedoc "The return type of `send_data/2`"
  @type send_result :: :ok | {:error, send_error()}

  @doc "Send the data down the socket"
  @callback send_data(t(), iodata()) :: send_result()

  @spec send_data(t(), iodata()) :: send_result()
  @doc """
  Sends the given iolist `data` down the socket.

  There is no timeout for this operation unless one was specified
  during construction or set after construction.
  """
  def send_data(%Socket{module: module} = socket, data) do
    apply(module, :send_data, [socket, data])
  end

  # Setting the socket activity

  @typedoc "The return type of `set_active/2`"
  @type set_active_return :: {:ok, t()} | {:error, Posix.t()}

  @doc "Set the activity mode of the socket"
  @callback set_active(t(), active()) :: set_active_return()

  @spec set_active(t(), active()) :: set_active_return()
  @doc """
  Changes the socket's activity mode. Valid activities:
    - `true`  - enable `active` mode
    - `false` - enable `passive` mode
    - `:once` - enable BAM for one packet
    - `integer()` - adjust the internal active window counter by this many

  Note that while the first three all set the value, providing an
  integer can behave in two ways, depending on the current mode:

    - You are not in BAM, the active counter is *set* to this
      value. If it is lower than zero, the socket is made passive.

    - You are in BAM, the active counter is *adjusted by* this value
      (by addition). If you pass a negative number and cause the
      counter to go below 0, the socket is made passive.

  We recommend only using `set_active/2` with a positive integer and
  when the socket is in passive mode (such as when you have been
  informed the socket has just been made passive). This simplifies the
  problem and you can pretend that it *does* set the internal counter.

  If you ignore the last paragraph, you'll have to keep track of the
  current active window to know what the new one will be after calling
  `set_active/2`. The (undocumented) `decr_active/1` function may be
  useful to call when you receive a packet. You could also use
  `fetch_active/1`, but this will be slower.

  This behaviour is inherited from OTP. We would not choose to implement
  it this way ourselves.
  """
  def set_active(%Socket{module: module} = socket, active) do
    apply(module, :set_active, [socket, active])
  end

  # Fetching the socket activity

  @typedoc "The errors `fetch_active/1` may return"
  @type fetch_active_error :: Closed.t() | Posix.t()

  @typedoc "The return type of `fetch_active/1`"
  @type fetch_active_return :: {:ok, active()} | {:error, fetch_active_error()}

  @doc "Fetches the active mode of the socket"
  @callback fetch_active(t()) :: fetch_active_return()

  @spec fetch_active(t()) :: fetch_active_return()
  @doc """
  Fetches the current activity of the socket
  """
  def fetch_active(%Socket{module: module} = socket) do
    apply(module, :fetch_active, [socket])
  end

  # Closing the socket

  @doc "Closes the socket"
  @callback close(t()) :: :ok

  @spec close(t()) :: :ok
  @doc """
  Closes the socket. Always returns `:ok`
  """
  def close(%Socket{module: module} = socket) do
    apply(module, :close, [socket])
  end

  # Handing off the socket to another process

  @typedoc "The errors `handoff/2` may return"
  @type handoff_error :: BadOption.t() | Closed.t() | Posix.t()

  @typedoc "The return type of `handoff/2`"
  @type handoff_return :: {:ok, t()} | {:error, handoff_error()}

  @doc "Makes another process the new owner of the Socket"
  @callback handoff(t(), pid()) :: handoff_return()

  @spec handoff(t(), pid()) :: handoff_return()
  @doc """
  Hands a Socket off to a new process, which becomes the owner
  """
  def handoff(%Socket{module: module} = socket, pid) when is_pid(pid) do
    apply(module, :handoff, [socket, pid])
  end

  @spec passify(t()) :: {:ok, binary(), Socket.t()} | {:closed, binary()} | {:error, term()}
  @doc """
  Turns the socket passive, clearing any active data out of the
  mailbox. and returning it as one binary
  Note: Assumes binary mode!
  """
  def passify(%Socket{} = socket) do
    with {:ok, socket} <- set_active(socket, false),
         do: passify_h(socket, "")
  end

  defp passify_h(
         %Socket{handle: handle, data_tag: d, error_tag: e, closed_tag: c, passive_tag: p} =
           socket,
         acc
       ) do
    if Util.active?(socket) do
      receive do
        {^p, ^handle} ->
          {:ok, acc, %{socket | active: false}}

        {^e, ^handle, reason} ->
          {:error, reason}

        {^c, ^handle} ->
          {:closed, acc}

        {^d, ^handle, msg} ->
          case msg do
            {:data, data} -> passify_h(socket, acc <> data)
            :closed -> {:closed, acc}
            {:error, reason} -> {:error, reason}
          end
      after
        0 -> {:ok, acc, %{socket | active: false}}
      end
    else
      {:ok, acc, %{socket | active: false}}
    end
  end

  @doc """
  Extends the bounded active mode (BAM) of a socket by its bam_window
  """
  @spec extend_active(t()) :: set_active_return()
  def extend_active(%Socket{bam_window: window} = socket) do
    extend_active(socket, window)
  end

  @doc """
  Extends the active of a socket by the given window
  """
  @spec extend_active(t(), window()) :: set_active_return()
  def extend_active(%Socket{} = socket, window) do
    Socket.set_active(socket, window)
  end
end
