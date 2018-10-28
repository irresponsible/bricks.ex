[Hexdocs](https://hexdocs.pm/bricks)
<!-- [Combidocs](https://hexdocs.pm/bricks_suite) -->

# bricks

The elixir sockets library of your dreams!

## Motivation

The OTP `:gen_tcp` and `:ssl` libraries have quite a few pain points:

- A different (albeit identical) API per socket type
- Different active mode message tags per socket type
- Risk of mailbox overflow-induced BEAM crash in active mode
- `ssl` ignores your intended socket state options on handshake
- `gen_tcp` sockets default to a different activity mode for a unix socket
- Confusing documentation
- Lack of useful examples

This library attempts to address these problems.

Goals:

- Intuitive high-level API for common tasks
- Simple low-level API for advanced purposes
- Fully embrace active and passive socket modes, avoiding active overflow
- Do not force a process model on the user
- Examples of common use cases

## Status: Beta

Bricks represents months of research and development. It is a
production quality library and well tested.

There is a possibility there will be small API tweaks in the run-up to 1.0

## Installation

Add to your deps:

```
{:bricks, "~> 0.1"}
```

## Overview

### Sockets

A Socket represents a *connected* Socket - that is it is
manufactured *after* a connection has been established.
  
As in Erlang/OTP, a Socket is owned by a single process, the owner. No
other process may interact with the Socket, but the owner can hand off
ownership to another process. If the owner process dies, the socket
will be closed.
  
A Socket is at any given time (as per OTP) in one of these modes:

- `passive` mode -  data can only be received when you call `recv`.

- `active` mode - the socket transforms packets into messages as
  they arrive and transmits them to the owner.

- `bounded active` mode - like `active` mode, but caps the number of
  packets that will be buffered in the owner mailbox before
  requiring a reset by the owner. See section later.

#### Picking a mode

If you are running a *service* process (such as a `GenServer`), you
generally do not want to use `passive` mode as it holds up the event
loop. Prefer `bounded active` mode (or `active` if you *must*).

Otherwise, all modes are available to you:

- `passive` mode: *a safe default* when you don't have aggressive
  performance requirements, but calling `recv` holds up responding to
  messages, so it's not generally suitable for a GenServer.

- `active` mode: the process mailbox becomes an effectively
  unlimited sized buffer. If you fail to keep up, you might buffer
  until the BEAM has eaten all of the memory and gets killed. But
  while it doesn't, it's low latency and high throughput.
  *WARNING: You almost certainly want bounded active. Active mode
  puts you at risk of BEAM crash. I hope you know what you're doing.*

- `bounded active` mode: like active mode, but caps the number of
  packets that will be buffered in the owner mailbox. Achieves
  better performance than `passive` mode but without the risks
  associated with `active` mode.

#### Bounded Active Mode

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

##### Enabling and using BAM

`set_active/2` can take the following values:
  - `true`  - enable `active` mode
  - `false` - enable `passive` mode
  - `:once` - enable BAM for one packet
  - `integer()` - adjust the internal active window counter by this
                  many, send a message to notify the owner when the
                  socket is made passive.

Note that while the first three all set the value, providing an
integer can behave in two ways, depending on the current mode:

- You are not in BAM, the active counter is *set* to this
  value. If it is zero or lower, the socket is made passive.

- You are in BAM, the active counter is *adjusted by* this value
  (by addition). If you pass a negative number and cause the
  counter to go 0 or lower, the socket is made passive.

When providing an integer, when the socket is made passive by the
active counter hitting 0, a notification is sent. This is *only*
triggered by providing an integer, not by `:once`.

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

#### Connectors

The simplest way to get a socket is to use a `Connector`. Connectors
are responsible for establishing a connection. There are `Tcp`, `Tls`
and `Unix` connectors at present.

You may use `Bricks.Connector.connect/1` to connect a connector:

```elixir
{:ok, conn} = Bricks.Connector.Tcp.new(%{host: "example.org", port: 80})
{:ok, socket} = Bricks.Connector.connect(conn)
```

Connectors perform validation and construction of underlying options
at construction time so you don't pay the penalty for each new
connection unless you change something.n

##### TCP Connector

```elixir
# Note: Optional arguments are shown with their default values
{:ok, tcp} = Bricks.Connector.Tcp.new(%{
  host: "example.org",   # required
  port: 80,              # required
  # common optional arguments
  bam_window: 10,        # bam_window on the created socket
  receive_timeout: 5000, # receive_timeout on the created socket in ms
  connect_timeout: 5000, # in ms
  send_timeout: 5000,    # in ms
  active: false,         # default activity mode
  ipv6?: true,           # ipv6 support
  # for full options, see moduledocs for `Bricks.Connector.Tcp`
})
```

The `Tcp` connector uses `gen_tcp` to establish a connection.

##### Unix Connector

```elixir
# Note: Optional arguments are shown with their default values
{:ok, unix} = Bricks.Connector.Unix.new("/var/run/example.sock", %{
  path: "/var/run/example.sock", # required
  # common optional arguments
  bam_window: 10,                # bam_window on the created socket
  connect_timeout: 3000,         # in ms
  receive_timeout: 3000,         # receive_timeout on the created socket in ms
  send_timeout:    3000,         # in ms
  active: false,                 # default activity mode
  # for full options, see moduledocs for `Bricks.Connector.Unix`
})
```

The `Unix` connector uses `:gen_tcp` to establish a connection.

## Usage Examples

### Passive Mode
  
#### Echo Service Client (Basic)

```elixir
alias Bricks.Connector.Unix
alias Bricks.{Connector, Socket}

def passive_echo() do

  # First we need to connect
  unix = Unix.new("/var/run/echo.sock")   # Configure
  {:ok, socket} = Connector.connect(unix) # Connect
  {:ok, "", socket} = Socket.passify(h)   # Set passive

  # Now we talk to the fictional echo service
  :ok = Socket.send_data(socket, "hello world\n")           # Send
  {:ok, "hello world\n", socket} = Socket.recv(socket, 0)   # Receive
  :ok = Socket.send_data(socket, "goodbye world\n")         # Send
  {:ok, "goodbye world\n", socket} = Socket.recv(socket, 0) # Receive

  :ok = Socket.close(socket) # Tidy up
end
```

### Active Mode

#### Echo Service Client (Basic)

```elixir
alias Bricks.Connector.Unix
alias Bricks.{Connector, Socket}
import Bricks.Sugar

def active_echo() do
  # First we need to connect
  unix = Unix.new("/var/run/echo.sock")           # Configure
  {:ok, socket} = Connector.connect(unix)         # Connect
  {:ok, socket} = Socket.set_active(socket, true) # Set active
  # Now we talk to the fictional echo service
  :ok = Socket.send_data(socket, "hello world\n") # Send
  binding socket do
    receive do
      match_data("hello world\n") -> :ok    # Receive
      match_closed()              -> {:error, :closed}
      match_error(reason)         -> {:error, reason}
    after 1000 -> throw :timeout
    end
  end
  :ok = Socket.close(socket) # Tidy up
end
```

#### Echo Service Client (Basic - No Sugar)

```elixir
alias Bricks.Connector.Unix
alias Bricks.{Connector, Socket}

def active_echo() do
  # First we need to connect
  unix = Unix.new("/var/run/echo.sock")           # Configure
  {:ok, socket} = Connector.connect(unix)         # Connect
  {:ok, socket} = Socket.set_active(socket, true) # Set active
  %Socket{                                        # Match out receive pins
    handle:     handle, # Internal socket handle
    data_tag:   data,   # Tag for data messages
    error_tag:  error,  # Tag for error messages
    closed_tag: closed, # Tag for closed messages
  }=socket

  # Now we talk to the fictional echo service
  :ok = Socket.send_data(socket, "hello world\n") # Send
  receive do
    {^data,   ^handle, "hello world\n"} -> :ok    # Receive
    {^closed, ^handle}         -> throw {:error, :closed}
    {^error,  ^handle, reason} -> throw {:error, reason}
  after 1000 -> throw :timeout
  end
  :ok = Socket.close(socket) # Tidy up
end
```

#### Slurp All (GenServer)

```elixir
defmodule GenServerExample do
  alias Bricks.{Connector, Socket}
  require Logger
  use GenServer
  import Bricks.Sugar

  def init([connector]) do
    {:ok, socket} = Connector.connect(connector)
    {:ok, socket} = Socket.set_active(socket, true)
    {:ok, socket}
  end

  defhandle_info data(SOCKET=socket, data) do
    Logger.info("Got data: " <> data)
    {:noreply, socket}
  end
 
  defhandle_info error(SOCKET=socket, data) do
    {:stop, reason, socket}
  end

  defhandle_info closed(SOCKET=socket) do
    {:stop, :closed, socket}
  end
end
```

#### Slurp All (GenServer - No Sugar)

```elixir
defmodule GenServerExample do
  use GenServer
  require Logger
  alias Bricks.{Connector, Socket}

  def init([connector]) do
    {:ok, socket} = Connector.connect(connector)
    {:ok, socket} = Socket.set_active(socket, true)
    {:ok, socket}
  end

  def handle_info({tag, handle, data}, socket=%Socket{handle: handle2, data_tag: tag2})
  when handle == handle2 and tag == tag2 do
    Logger.info("Got data: " <> data)
    {:noreply, socket}
  end

  def handle_info({tag, handle, reason}, socket=%Socket{handle: handle2, error_tag: tag2})
  when handle == handle2 and tag == tag2 do
    {:stop, reason, socket}
  end

  def handle_info({tag, handle}, socket=%Socket{handle: handle2, closed_tag: tag2})
  when handle == handle2 and tag == tag2 do
    {:stop, :closed, socket}
  end
end
```

### Bounded Active Mode

#### Echo Service Client (Basic)

```elixir
alias Bricks.Connector.Unix
alias Bricks.{Connector, Socket}

def bounded_active_echo() do

  # First we need to connect
  unix = Unix.new("/var/run/echo.sock")            # Configure
  {:ok, socket} = Connector.connect(unix)          # Connect
  {:ok, socket} = Socket.set_active(socket, false) # Set passive

  # Now we talk to the fictional echo service
  {:ok, socket} = Socket.set_active(socket, :once) # Set active for one packet
  :ok = Socket.send_data(socket, "hello world\n")  # Send
  binding socket do
    receive do
      match_data("hello world\n") -> :ok # Receive
      match_closed()      -> {:error, :closed}
      match_error(reason) -> {:error, reason}
    after 1000 -> throw :timeout
    end
  end
  :ok = Socket.close(socket) # Tidy up
end
```

#### Echo Service Client (Basic - No Sugar)

```elixir
alias Bricks.Connector.Unix
alias Bricks.{Connector, Socket}

def bounded_active_echo() do

  # First we need to connect
  unix = Unix.new("/var/run/echo.sock")            # Configure
  {:ok, socket} = Connector.connect(unix)          # Connect
  {:ok, socket} = Socket.set_active(socket, false) # Set passive
  %Socket{                                         # Match out receive pins
    handle: handle,     # Internal socket handle
    data_tag: data,     # Tag for data messages
    error_tag: error,   # Tag for error messages
    closed_tag: closed, # Tag for closed messages
  }=socket

  # Now we talk to the fictional echo service
  {:ok, socket} = Socket.set_active(socket, :once) # Set active for one packet
  :ok = Socket.send_data(socket, "hello world\n")  # Send
  receive do
    {^data,   ^handle, "hello world\n"} -> :ok       # Receive
    {^closed, ^handle}         -> throw {:error, :closed}
    {^error,  ^handle, reason} -> throw {:error, reason}
  after 1000 -> throw :timeout
  end
  {:ok, socket} = Socket.set_active(socket, :once)  # Set active for one packet
  :ok = Socket.send_data(socket, "goodbye world\n") # Send
  receive do
    {^data,   ^handle, "goodbye world\n"} -> :ok      # Receive
    {^closed, ^handle}         -> throw {:error, :closed}
    {^error,  ^handle, reason} -> throw {:error, reason}
  after 1000 -> throw :timeout
  end

  :ok = Socket.close(socket) # Tidy up
end
```

#### Slurp All (GenServer)

```elixir
defmodule GenServerExample do
  use GenServer
  require Logger
  alias Bricks.{Connector, Socket}

  def init([connector]) do
    {:ok, socket} = Connector.connect(connector)
    {:ok, socket} = Socket.extend_active(socket)
    {:ok, socket}
  end

  defhandle_info data(SOCKET=socket, data) do
    Logger.info("Got data: " <> data)
    {:noreply, socket}
  end

  defhandle_info error(SOCKET=socket, reason) do
    {:stop, reason, socket}
  end

  defhandle_info closed(SOCKET=socket) do
    {:stop, :closed, socket}
  end

  defhandle_info passive(SOCKET=socket) do
    {:ok, socket} = Socket.extend_active(socket)
    {:noreply, socket}
  end

end
```

#### Slurp All (GenServer - No Sugar)

```elixir
defmodule GenServerExample do
  use GenServer
  require Logger
  alias Bricks.{Connector, Socket}

  def init([connector]) do
    {:ok, socket} = Connector.connect(connector)
    {:ok, socket} = Socket.extend_active(socket)
    {:ok, socket}
  end

  def handle_info({tag, handle, data}, socket=%Socket{handle: handle2, data_tag: tag2})
  when handle == handle2 and tag == tag2 do
    Logger.info("Got data: " <> data)
    {:noreply, socket}
  end

  def handle_info({tag, handle, reason}, socket=%Socket{handle: handle2, error_tag: tag2})
  when handle == handle2 and tag == tag2 do
    {:stop, reason, socket}
  end

  def handle_info({tag, handle}, socket=%Socket{handle: handle2, closed_tag: tag2})
  when handle == handle2 and tag == tag2 do
    {:stop, :closed, socket}
  end

  def handle_info({tag, handle}, socket=%Socket{handle: handle2, passive_tag: tag2})
  when handle == handle2 and tag == tag2 do
    {:ok, socket} = Socket.extend_active(socket)
    {:noreply, socket}
  end

end
```

## Contributing

Contributions are welcome, even just doc fixes or suggestions.

This project has adopted a [Code of Conduct](CONDUCT.md) based on the
Contributor Covenant. Please be nice when interacting with the community.

## Copyright and License

Copyright (c) 2018 James Laver

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

