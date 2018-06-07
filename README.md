# bricks

A uniform low-level API over unix domain sockets, tcp and tcp/tls connections

## Status: Pre-alpha

NOT ON HEX YET

Missing:
- Tls connector and socket (pending tidy of old code)
- Any sort of connection pooling client

Annoyances:

- gen_tcp sockets start active for tcp and passive for unix.
  No, I haven't filed an erlang bug about it because I was too pissed off with jira to finish the process.
  Workaround: Use Sockets.actify, Sockets.passify to set it explicitly the way you want it.

## Usage

```elixir

alias Bricks.Connector.Unix
alias Bricks.Client.Simple
alias Bricks.{Client, Socket, Sockets}

# Here we will connect to a unix socket for a fictional echo service
# and verify it echoes correctly
def main() do
  unix = Unix.new("/var/run/echo.sock")
  client = Simple.new(unix)
  {:ok, conn} = Client.connect(client)
  
  # Let's start in active mode where we will be sent packets as messages
  :ok = Sockets.actify(h)
  :ok = Socket.send_data(h, "hello world\n")
  # recv_active is a wrapper around receive
  {:ok, "hello world\n"} = Socket.recv_active(h)

  # And here's how you use passive mode
  {:ok,""} = Sockets.passify(h) # if the server sent more in the meantime, won't be ""
  :ok = Socket.send_data(h, "hello world\n")
  {:ok, "hello world \n"} = Socket.recv_passive(h, 12)
end

```


## Overview

There are several important structures:

- Connectors are responsible for establishing a connection
- Sockets are the uniform interface over a connection
- Clients are responsible for managing the lifecycle of sockets

### Connectors

#### Unix Connector

```elixir
Bricks.Connector.Unix.new("/var/run/example.sock")
Bricks.Connector.Unix.new("/var/run/example.sock", [:binary]) # custom gen_tcp opts
```

The unix connector uses `gen_tcp` to establish a connection. It therefore returns a `Tcp` socket.

#### TCP Connector

```elixir
Bricks.Connector.Tcp.new("example.org", 80)
Bricks.Connector.Tcp.new("example.org", 80, [:binary]) # custom gen_tcp opts
```

<!-- #### TLS Connector -->

<!-- ```elixir -->
<!-- ``` -->

### Clients

Clients are designed for talking to a single host

#### Simple Client

The simple client uses a connector to establish a new connection every time.
Connections will be closed when they are no longer required, there is no reuse of connections.

```elixir
Bricks.Client.Simple.new(connector)
```

### Sockets

#### TCP

The TCP socket is powered by `:gen_tcp`

<!-- #### TLS -->


