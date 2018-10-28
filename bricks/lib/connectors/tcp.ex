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

defmodule Bricks.Connector.Tcp do
  @moduledoc """
  A Connector for TCP sockets, using `:gen_tcp`

  Belongs to application `:bricks`

  ## Create Options

  ### All

  Ordering: Required first, then alphabetical

  Option                 | Type(s)           | Default        | Raw `gen_tcp` option
  :--------------------- | :---------------- | :------------- | :-----------------------
  `:host`                | `binary`          | `(REQUIRED)`   | `(POSITIONAL)`
  `:port`                | `pos_integer`     | `(REQUIRED)`   | `(POSITIONAL)`
  `:connect_timeout`     | `timeout`         | `5000`         | `(POSITIONAL)`
  `:bam_window`          | `Socket.window`   | `10`           | `(NONE)`
  `:active`              | `Socket.active`   | `true`         | `:active`
  `:bind_to_device`      | `binary`          | `(NONE)`       | `:bind_to_device`
  `:buffer`              | `non_neg_integer` | `(UNKNOWN)`    | `:buffer`
  `:delay_send?`         | `boolean`         | `false`        | `:delay_send`
  `:deliver`             | `:port`, `:term`  | `(UNKNOWN)`    | `:deliver`
  `:dont_route?`         | `boolean`         | `(false?)`     | `:dontroute`
  `:exit_on_close?`      | `boolean`         | `true`         | `:exit_on_close`
  `:header_size`         | `non_neg_integer` | `(NONE)`       | `:header`
  `:high_msgq_watermark` | `pos_integer`     | `(UNKNOWN)`    | `:high_msgq_watermark`
  `:high_watermark`      | `non_neg_integer` | `(UNKNOWN)`    | `:high_watermark`
  `:ipv4?`               | `boolean`         | `true`         | `:inet`, `:ipv6_v6only`
  `:ipv6?`               | `boolean`         | `false`        | `:inet6`, `:ipv6_v6only`
  `:keepalive?`          | `boolean`         | `false`        | `:keepalive`
  `:line_delimiter`      | `char`            | `?\\n`         | `:line_delimiter`
  `:linger?`             | `linger`          | `(NONE)`       | `:linger`
  `:local_port`          | `Socket.port_num` | `0` (random)   | `:port`
  `:low_msgq_watermark`  | `pos_integer`     | `(UNKNOWN)`    | `:low_msgq_watermark`
  `:low_watermark`       | `non_neg_integer` | `(UNKNOWN)`    | `:low_watermark`
  `:network_interface`   | `Socket.host`     | `(NONE`        | `:ip`, `:ifaddr`
  `:network_namespace`   | `binary`          | `(NONE)`       | `:netns`
  `:nodelay?`            | `boolean`         | `false`        | `:nodelay`
  `:packet_type`         | `packet_type`     | `:raw`         | `:packet`
  `:packet_size`         | `pos_integer`     | `0` (no limit) | `:packet_size`
  `:priority`            | `non_neg_integer` | `(NONE)`       | `:priority`
  `:raw_fd`              | `non_neg_integer` | `(NONE)`       | `:fd`
  `:receive_buffer`      | `non_neg_integer` | `(NONE)`       | `:recbuf`
  `:receive_tclass?`     | `boolean`         | `false?`       | `:recvtclass`
  `:receive_tos?`        | `boolean`         | `false?`       | `:recvtos`
  `:receive_ttl?`        | `boolean`         | `false?`       | `:recvttl`
  `:receive_timeout`     | `timeout`         | `5000`         | `(POSITIONAL)`
  `:send_timeout`        | `timeout`         | `5000`         | `:send_timeout`
  `:reuse_addr?`         | `boolean`         | `false`        | `:reuseaddr`
  `:send_timeout_close?` | `boolean`         | `true`         | `:send_timeout_close`
  `:show_econnreset?`    | `boolean`         | `false`        | `:show_econnreset`
  `:send_buffer`         | `non_neg_integer` | `(NONE)`       | `:sndbuf`
  `:tos`                 | `non_neg_integer` | `(NONE)`       | `:tos`
  `:tclass`              | `non_neg_integer` | `(NONE)`       | `:tclass`
  `:tcp_module`          | `atom`            | `(SEE DOCS)`   | `:tcp_module`

  ### Destination Selection

  Option  | Type          | Default      | Raw `gen_tcp` option
  :------ | :------------ | :----------- | :-------------------
  `:host` | `binary`      | `(REQUIRED)` | `(POSITIONAL)`
  `:port` | `pos_integer` | `(REQUIRED)` | `(POSITIONAL)`

  ### IP Version Selection

  Option   | Type      | Default | Raw `gen_tcp` option
  :------- | :-------- | :------ | :-----------------------
  `:ipv4?` | `boolean` | `true`  | `:inet`, `:ipv6_v6only`
  `:ipv6?` | `boolean` | `false` | `:inet6`, `:ipv6_v6only`

  These options toggle which IP versions may be used. At least one
  must be `true` or you will get an error.

  ### Timeouts

  Option             | Type      | Default | Raw `gen_tcp` option
  :----------------- | :-------- | :------ | :-------------------
  `:connect_timeout` | `timeout` | `5000`  | `(POSITIONAL)`
  `:receive_timeout` | `timeout` | `5000`  | `(POSITIONAL)`
  `:send_timeout`    | `timeout` | `5000`  | `:send_timeout`

  These toggle how long you are prepared to wait for an operation to
  complete before a timeout error is returned. They are standard
  erlang `timeout` values: non-negative integers or `:infinity`.

  ### Activity Control

  Option        | Type            | Default | Raw `gen_tcp` option
  :------------ | :-------------- | :------ | :-------------------
  `:active`     | `Socket.active` | `true`  | `:active`
  `:bam_window` | `Socket.window` | `10`    | `(NONE)`

  See discussion on socket activity modes in the `Bricks.Socket`
  module documentation for more information.

  ### Erlang Options

  Option                 | Type              | Default      | Raw `gen_tcp` option
  :--------------------- | :---------------- | :----------- | :---------------------
  `:buffer`              | `non_neg_integer` | `(UNKNOWN)`  | `:buffer`
  `:delay_send?`         | `boolean`         | `false`      | `:delay_send`
  `:exit_on_close?`      | `boolean`         | `true`       | `:exit_on_close`
  `:header_size`         | `non_neg_integer` | `(NONE)`     | `:header`
  `:high_msgq_watermark` | `pos_integer`     | `(UNKNOWN)`  | `:high_msgq_watermark`
  `:high_watermark`      | `non_neg_integer` | `(UNKNOWN)`  | `:high_watermark`
  `:line_delimiter`      | `char`            | `?\\n`       | `:line_delimiter`
  `:low_msgq_watermark`  | `pos_integer`     | `(UNKNOWN)`  | `:low_msgq_watermark`
  `:low_watermark`       | `non_neg_integer` | `(UNKNOWN)`  | `:low_watermark`
  `:packet_type`         | `packet_type`     | `:raw`       | `:packet`
  `:send_timeout_close?` | `boolean`         | `true`       | `:send_timeout_close`
  `:show_econnreset?`    | `boolean`         | `false`      | `:show_econnreset`
  `:tcp_module`          | `atom`            | `(SEE DOCS)` | `:tcp_module`
  `:tcp_opts`            | `proplist`        | `[]`         | `(ANY)`

  #### `:buffer`

  The size of the user-level buffer used by the driver. Not to be
  confused with options `:send_buffer` and `:receive_buffer`, which
  correspond to the Kernel socket buffers. For TCP it is recommended
  to have val(buffer) >= val(recbuf) to avoid performance issues
  because of unnecessary copying. However, as the size set for recbuf
  usually become larger, you are encouraged to use getopts/2 to
  analyze the behavior of your operating system.

  Note that this is also the maximum amount of data that can be
  received from a single `recv` call. If you are using higher than
  normal MTU consider setting buffer higher.

  #### `:delay_send?`

  Normally, when an Erlang process sends to a socket, the driver tries
  to send the data immediately. If that fails, the driver uses any
  means available to queue up the message to be sent whenever the
  operating system says it can handle it. Setting `delay_send: true`
  makes all messages queue up. The messages sent to the network are
  then larger but fewer. The option affects the scheduling of send
  requests versus Erlang processes instead of changing any real
  property of the socket. The option is implementation-specific.

  #### `:exit_on_close?`

  The only reason to set it to false is if you want to continue
  sending data to the socket after a close is detected, for example,
  if the peer uses `:gen_tcp.shutdown/2` to shut down the write side.

  #### `:header_size`

  This option is only meaningful if option binary was specified when
  the socket was created. If option header is specified, the first
  Size number bytes of data received from the socket are elements of a
  list, and the remaining data is a binary specified as the tail of
  the same list. For example, if set to `2`, the data received matches
  `[byte1,byte2|binary]`

  #### `:high_msgq_watermark`

  The socket message queue is set to a busy state when the amount of
  data on the message queue reaches this limit. Notice that this limit
  only concerns data that has not yet reached the ERTS internal socket
  implementation. Defaults to `8 kB`.

  Senders of data to the socket are suspended if either the socket
  message queue is busy or the socket itself is busy.

  For more information, see options `:low_msgq_watermark`,
  `:high_watermark`, and `:low_watermark`.

  Notice that distribution sockets disable the use of
  `:high_msgq_watermark` and `:low_msgq_watermark`. Instead use the
  distribution buffer busy limit, which is a similar feature.

  #### `:high_watermark`

  The socket is set to a busy state when the amount of data queued
  internally by the ERTS socket implementation reaches this
  limit. Defaults to `8 kB`.

  Senders of data to the socket are suspended if either the socket
  message queue is busy or the socket itself is busy.

  For more information, see options low_watermark,
  high_msgq_watermark, and low_msqg_watermark.

  #### `:line_delimiter`

  Sets the line delimiting character for line-oriented protocols
  (`:line`). Defaults to `?\n`.

  #### `:low_msgq_watermark`

  If the socket message queue is in a busy state, the socket message
  queue is set in a not busy state when the amount of data queued in
  the message queue falls below this limit. Notice that this limit
  only concerns data that has not yet reached the ERTS internal socket
  implementation. Defaults to `4 kB`.

  Senders that are suspended because of either a busy message queue or
  a busy socket are resumed when the socket message queue and the
  socket are not busy.

  For more information, see options `:high_msgq_watermark`,
  `:high_watermark`, and `:low_watermark`.

  Notice that distribution sockets disable the use of
  `:high_msgq_watermark` and `:low_msgq_watermark`. Instead they use
  the distribution buffer busy limit, which is a similar feature.

  #### `:low_watermark`

  If the socket is in a busy state, the socket is set in a not busy
  state when the amount of data queued internally by the ERTS socket
  implementation falls below this limit. Defaults to `4 kB`.

  Senders that are suspended because of a busy message queue or a busy
  socket are resumed when the socket message queue and the socket are
  not busy.

  For more information, see options `:high_watermark`,
  `:high_msgq_watermark`, and `:low_msgq_watermark`.

  #### `:packet_type`

  Defines the type of packets to use for a socket. Possible values:

  `:raw` | `0`
  : No packaging is done.

  `1` | `2` | `4`
  : Packets consist of a header specifying the number of bytes in the
    packet, followed by that number of bytes. The header length can be
    one, two, or four bytes, and containing an unsigned integer in
    big-endian byte order. Each send operation generates the header,
    and the header is stripped off on each receive operation. The
    4-byte header is limited to 2Gb.

  `:asn1` | `:cdr` | `:sunrm` | `:fcgi` | `:tpkt` | `:line`
  : These packet types only have effect on receiving. When sending a
    packet, it is the responsibility of the application to supply a
    correct header. On receiving, however, one message is sent to the
    controlling process for each complete packet received, and,
    similarly, each call to `:gen_tcp.recv/2,3` returns one complete
    packet. The header is not stripped off.

    The meanings of the packet types are as follows:

    - `:asn1` - ASN.1 BER
    - `:sunrm` - Sun's RPC encoding
    - `:cdr` - CORBA (GIOP 1.1)
    - `:fcgi` - Fast CGI
    - `:tpkt` - TPKT format [RFC1006]
    - `:line` - Line mode, a packet is a line-terminated with newline,
      lines longer than the receive buffer are truncated

  ##### `:http` | `:http_bin`

  The Hypertext Transfer Protocol. The packets are returned with the
  format according to HttpPacket described in
  `:erlang.decode_packet/3` in ERTS. A socket in passive mode returns
  `{:ok, packet}` from `:gen_tcp.recv` while an active socket sends
  messages like `{http, socket_handle, packet}`.

  ##### `:httph` | `:httph_bin`

  These two types are often not needed, as the socket automatically
  switches from `:http`/`:http_bin` to `:httph`/`:httph_bin`
  internally after the first line is read. However, there can be
  occasions when they are useful, such as parsing trailers from
  chunked encoding.

  #### `:send_timeout_close?`

  Used together with `:send_timeout` to specify whether the socket is to
  be automatically closed when the send operation returns
  `{:error,:timeout}`. The recommended setting is `true`, which
  automatically closes the socket.

  #### `:show_econnreset?`

  When this option is set to `false`, which is default, an RST
  received from the TCP peer is treated as a normal close (as though
  an FIN was sent). A caller to `:gen_tcp.recv/2` gets `{:error,
  :closed}`. In `active` mode, the controlling process receives a
  `{:tcp_closed, socket_handle}` message, indicating that the peer has
  closed the connection.

  Setting this option to `true` allows you to distinguish between a
  connection that was closed normally, and one that was aborted
  (intentionally or unintentionally) by the TCP peer. A call to
  `:gen_tcp.recv/2` returns `{:error, :econnreset}`. In `active` mode,
  the controlling process receives a `{:tcp_error, socket_handle,
  :econnreset}` message before the usual `{:tcp_closed,
  socket_handle}`, as is the case for any other socket error. Calls to
  `:gen_tcp.send/2` also returns `{:error, :econnreset}` when it is
  detected that a TCP peer has sent an RST.

  A connected socket returned from `:gen_tcp.accept/1` inherits the
  `:show_econnreset?` setting from the listening socket.

  #### `:tcp_module`

  Overrides which callback module is used. Defaults to `:inet_tcp` for
  IPv4 and `:inet6_tcp` for IPv6.

  #### `:tcp_opts`

  Raw `gen_tcp`/`inet` options proplist. *Appended* to options.



  ### OS options

  Option               | Type              | Default        | Raw `gen_tcp` option
  :------------------- | :---------------- | :------------- | :-------------------
  `:bind_to_device`    | `binary`          | `(NONE)`       | `:bind_to_device`
  `:deliver`           | `:port`, `:term`  | `(UNKNOWN)`    | `:deliver`
  `:dont_route?`       | `boolean`         | `(false?)`     | `:dontroute`
  `:keepalive?`        | `boolean`         | `false`        | `:keepalive`
  `:linger`            | `linger`          | `(NONE)`       | `:linger`
  `:local_port`        | `Socket.port_num` | `0` (random)   | `:port`
  `:network_interface` | `Socket.host`     | `(NONE`        | `:ip`, `:ifaddr`
  `:network_namespace` | `binary`          | `(NONE)`       | `:netns`
  `:nodelay?`          | `boolean`         | `false`        | `:nodelay`
  `:packet_size`       | `pos_integer`     | `0` (no limit) | `:packet_size`
  `:priority`          | `non_neg_integer` | `(NONE)`       | `:priority`
  `:raw_fd`            | `non_neg_integer` | `(NONE)`       | `:fd`
  `:receive_buffer`    | `non_neg_integer` | `(NONE)`       | `:recbuf`
  `:receive_tclass?`   | `boolean`         | `false?`       | `:recvtclass`
  `:receive_tos?`      | `boolean`         | `false?`       | `:recvtos`
  `:receive_ttl?`      | `boolean`         | `false?`       | `:recvttl`
  `:reuse_addr?`       | `boolean`         | `false`        | `:reuseaddr`
  `:send_buffer`       | `non_neg_integer` | `(NONE)`       | `:sndbuf`
  `:tos`               | `non_neg_integer` | `(NONE)`       | `:tos`
  `:tclass`            | `non_neg_integer` | `(NONE)`       | `:tclass`

  #### `:bind_to_device`

  Binds a socket to a specific network interface. This option must be
  used in a function call that creates a socket, that is,
  `:gen_tcp.connect/3,4`, `:gen_tcp.listen/2`, `:gen_udp.open/1,2`, or
  `:gen_sctp.open/0,1,2`.

  Unlike `getifaddrs/0`, Ifname is encoded a binary. In the unlikely
  case that a system is using non-7-bit-ASCII characters in network
  device names, special care has to be taken when encoding this
  argument.

  This option uses the Linux-specific socket option `SO_BINDTODEVICE`,
  such as in Linux kernel 2.0.30 or later, and therefore only exists
  when the runtime system is compiled for such an operating system.

  Before Linux 3.8, this socket option could be set, but could not
  retrieved with getopts/2. Since Linux 3.8, it is readable.

  The virtual machine also needs elevated privileges, either running
  as superuser or (for Linux) having capability `CAP_NET_RAW`.

  The primary use case for this option is to bind sockets into Linux VRF instances.

  #### `:deliver`

  When `active: true`, data is delivered on the form `port` :
  `{socket_handle, {:data, [h1,..hsz | data]}}` or `term` : `{:tcp,
  socket_handle, [h1..hsz | data]}`

  #### `:dont_route?`

  Enables/disables routing bypass for outgoing messages.

  #### `:keepalive?`

  Enables/disables periodic transmission on a connected socket when no
  other data is exchanged. If the other end does not respond, the
  connection is considered broken and an error message is sent to the
  controlling process. Defaults to disabled.

  #### `:linger`

  Determines the time-out, in seconds, for flushing unsent data in the
  `:gen_tcp.close/1` socket call. If the first component of the value
  tuple is false, the second is ignored. This means that
  `:gen_tcp.close/1` returns immediately, not waiting for data to be
  flushed. Otherwise, the second component is the flushing time-out,
  in seconds.

  #### `:local_port`

  Local port number to use for the outgoing socket.

  #### `:network_interface`

  If the host has many network interfaces, this option specifies which one to use.

  #### `:network_namespace`

  Sets a network namespace for the socket. Parameter s a filename
  defining the namespace, for example, "/var/run/netns/example",
  typically created by command `ip netns add example`. This option
  must be used in a function call that creates a socket, that is,
  `:gen_tcp.connect/3,4`, `:gen_tcp.listen/2`, `:gen_udp.open/1,2`, or
  `:gen_sctp.open/0,1,2`.

  This option uses the Linux-specific syscall `setns()`, such as in
  Linux kernel 3.0 or later, and therefore only exists when the
  runtime system is compiled for such an operating system.

  The virtual machine also needs elevated privileges, either running
  as superuser or (for Linux) having capability `CAP_SYS_ADMIN`
  according to the documentation for `setns(2)`. However, during
  testing also `CAP_SYS_PTRACE` and `CAP_DAC_READ_SEARCH` have proven
  to be necessary.

  Example:

  ```shell
  setcap cap_sys_admin,cap_sys_ptrace,cap_dac_read_search+epi beam.smp
  ```

  Notice that the filesystem containing the virtual machine executable
  (`beam.smp` in the example) must be local, mounted without flag
  `nosetuid`, support extended attributes, and the kernel must support
  file capabilities. All this runs out of the box on at least Ubuntu
  12.04 LTS, except that SCTP sockets appear to not support network
  namespaces.

  Namespace is a filename and is encoded and decoded as discussed in
  module file, with the following exceptions:

   - Emulator flag +fnu is ignored.

   - `:inet.getopts/2` for this option returns a binary for the
     filename if the stored filename cannot be decoded. This is only
     to occur if you set the option using a binary that cannot be
     decoded with the emulator's filename encoding:
     `:file.native_name_encoding/0`.

  #### `:nodelay?`

  If `true`, option `TCP_NODELAY` is turned on for the socket, which
  means that also small amounts of data are sent immediately.

  #### `:packet_size`

  Sets the maximum allowed length of the packet body. If the packet
  header indicates that the length of the packet is longer than the
  maximum allowed length, the packet is considered invalid. The same
  occurs if the packet header is too large for the socket receive
  buffer.

  For line-oriented protocols (`line`, `http*`), option `packet_size`
  also guarantees that lines up to the indicated length are accepted
  and not considered invalid because of internal buffer limitations.

  #### `:priority`

  Sets the `SO_PRIORITY` socket level option on platforms where this is
  implemented. The behavior and allowed range varies between different
  systems. The option is ignored on platforms where it is not
  implemented. Use with caution.

  #### `:raw_fd`

  If a socket has somehow been connected without using gen_tcp, use
  this option to pass the file descriptor for it. If
  `:network_interface` and/or `:port` options are combined with this
  option, the fd is bound to the specified interface and port before
  connecting. If these options are not specified, it is assumed that
  the fd is already bound appropriately.

  #### `:receive_buffer`

  The minimum size of the receive buffer to use for the socket. You
  are encouraged to use `:inet.getopts/2` to retrieve the size set by
  your operating system.

  #### `:receive_tclass?`

  If set to true activates returning the received `TCLASS` value on
  platforms that implements the protocol `IPPROTO_IPV6` option
  `IPV6_RECVTCLASS` or `IPV6_2292RECVTCLASS` for the socket. The value
  is returned as a `{:tclass,tclass}` tuple regardless of if the
  platform returns an `IPV6_TCLASS` or an `IPV6_RECVTCLASS` `CMSG`
  value.

  For packet oriented sockets that supports receiving ancillary data
  with the payload data (gen_udp and gen_sctp), the `TCLASS` value is
  returned in an extended return tuple contained in an ancillary data
  list. For stream oriented sockets (gen_tcp) the only way to get the
  `TCLASS` value is if the platform supports the pktoptions option.

  #### `:receive_tos?`

  If set to true activates returning the received `TOS` value on
  platforms that implements the protocol `IPPROTO_IP` option
  `IP_RECVTOS` for the socket. The value is returned as a `{:tos,tos}`
  tuple regardless of if the platform returns an `IP_TOS` or an
  `IP_RECVTOS` `CMSG` value.

  For packet oriented sockets that supports receiving ancillary data
  with the payload data (`:gen_udp` and `:gen_sctp`), the `TOS` value
  is returned in an extended return tuple contained in an ancillary
  data list. For stream oriented sockets (`:gen_tcp`) the only way to
  get the TOS value is if the platform supports the `pktoptions` option.

  #### `:receive_ttl?`

  If set to true activates returning the received `TTL` value on
  platforms that implements the protocol `IPPROTO_IP` option
  `IP_RECVTTL` for the socket. The value is returned as a `{:ttl,ttl}`
  tuple regardless of if the platform returns an `IP_TTL` or an
  `IP_RECVTTL` `CMSG` value.

  For packet oriented sockets that supports receiving ancillary data
  with the payload data (`:gen_udp` and `:gen_sctp`), the `TTL` value
  is returned in an extended return tuple contained in an ancillary
  data list. For stream oriented sockets (`;gen_tcp`) the only way to
  get the `TTL` value is if the platform supports the `pktoptions`
  option.

  #### `:reuse_addr?`

  Allows or disallows local reuse of port numbers. By default, reuse
  is disallowed.

  #### `:send_buffer`

  The minimum size of the send buffer to use for the socket. You are
  encouraged to use `getopts/2`, to retrieve the size set by your
  operating system.

  #### `:tos`

  Sets `IP_TOS IP` level options on platforms where this is
  implemented. The behavior and allowed range varies between different
  systems. The option is ignored on platforms where it is not
  implemented. Use with caution.

  #### `:tclass`

  Sets `IPV6_TCLASS IP` level options on platforms where this is
  implemented. The behavior and allowed range varies between different
  systems. The option is ignored on platforms where it is not
  implemented. Use with caution.

  """
  @enforce_keys [
    :host,
    :port,
    :tcp_opts,
    :receive_timeout,
    :connect_timeout,
    :bam_window,
    :active
  ]
  defstruct @enforce_keys
  alias Bricks.{Connector, Options, Socket, Util}
  alias Bricks.Connector.Tcp
  alias Bricks.Error.{BadCombo, BadOption, Connect}
  import Bricks.Guards

  @default_connect_timeout 5000
  @default_receive_timeout 5000
  @default_send_timeout 5000
  @default_tcp_opts []
  @default_bam_window 10
  @default_active false

  ## Types
  @typedoc "Valid linger value. See docs for info"
  @type linger :: {boolean(), non_neg_integer()}

  @typedoc "Packet type for inbuilt message parsing facilities"
  @type packet_type ::
          :raw
          | 0
          | 1
          | 2
          | 4
          | :asn1
          | :cdr
          | :sunrm
          | :fcgi
          | :tpkt
          | :line
          | :http
          | :http_bin
          | :httph
          | :httph_bin

  @typedoc "TCP Connector State"
  @type t :: %Tcp{
          host: Socket.host(),
          port: Socket.port_num(),
          tcp_opts: [term()],
          receive_timeout: timeout(),
          connect_timeout: timeout(),
          bam_window: Socket.window(),
          active: Socket.active()
        }

  @typedoc "Options for `create/1`"
  @type create_opts :: %{
          # Required
          :host => binary(),
          :port => pos_integer(),
          # Optional Socket members
          optional(:connect_timeout) => timeout(),
          optional(:receive_timeout) => timeout(),
          optional(:bam_window) => Socket.window(),
          optional(:active) => Socket.active(),
          # Optional non-Socket member `:gen_tcp`/`:inet` socket options
          optional(:bind_to_device) => binary(),
          optional(:buffer) => non_neg_integer(),
          optional(:delay_send?) => boolean(),
          optional(:deliver) => :port | :term,
          optional(:dont_route?) => boolean(),
          optional(:exit_on_close?) => boolean(),
          optional(:header_size) => non_neg_integer(),
          optional(:high_msgq_watermark) => pos_integer(),
          optional(:high_watermark) => non_neg_integer(),
          optional(:ipv4?) => boolean(),
          optional(:ipv6?) => boolean(),
          optional(:keepalive?) => boolean(),
          optional(:line_delimiter) => char(),
          optional(:linger) => {boolean(), pos_integer()},
          optional(:local_port) => Socket.port_num(),
          optional(:low_msgq_watermark) => pos_integer(),
          optional(:low_watermark) => non_neg_integer(),
          optional(:network_interface) => binary() | :inet.socket_address(),
          optional(:network_namespace) => binary(),
          optional(:nodelay?) => boolean(),
          optional(:packet_type) => :raw | 1 | 2 | 4,
          optional(:packet_size) => pos_integer(),
          optional(:priority) => non_neg_integer(),
          optional(:raw_fd) => non_neg_integer(),
          optional(:receive_buffer) => non_neg_integer(),
          optional(:receive_tclass?) => boolean(),
          optional(:receive_tos?) => boolean(),
          optional(:receive_ttl?) => boolean(),
          optional(:reuse_addr?) => boolean(),
          optional(:send_timeout) => timeout(),
          optional(:send_timeout_close?) => boolean(),
          optional(:show_econnreset?) => boolean(),
          optional(:send_buffer) => non_neg_integer(),
          optional(:tcp_module) => atom(),
          optional(:tcp_opts) => [term()],
          optional(:tos) => non_neg_integer(),
          optional(:tclass) => non_neg_integer()
        }

  @typedoc "The errors that `create/1` may return"
  @type option_error :: BadOption.t() | BadCombo.t()

  @spec create(create_opts()) :: {:ok, Connector.t()} | {:error, option_error()}

  @doc """
  Creates a `Bricks.Connector` which uses this module as a callback
  and the provided options to open and configure the socket.

  See module documentation for more information about the options
  """
  def create(opts) do
    with {:ok, tcp_opts} <- tcp_options(opts) do
      create_connector(opts, tcp_opts)
    end
  end

  ## behaviour impl: Connector

  @spec connect(t()) :: {:ok, Socket.t()} | {:error, term()}
  @doc false
  def connect(%Tcp{host: host, port: port, tcp_opts: opts, connect_timeout: timeout} = tcp) do
    case :gen_tcp.connect(host, port, opts, timeout) do
      {:error, reason} -> {:error, Connect.new(reason)}
      {:ok, socket} -> socket(socket, tcp)
    end
  end

  ## Internal helpers

  @tcp_table_options [
    bind_to_device: {:bind_to_device, &is_binary/1, [:binary]},
    buffer: {:buffer, &non_neg_int?/1, [:non_neg_int]},
    deliver: {:deliver, &deliver?/1, [:port, :term]},
    delay_send?: {:delay_send, &is_boolean/1, [:bool]},
    dont_route?: {:dontroute, &is_boolean/1, [:bool]},
    exit_on_close?: {:exit_on_close, &is_boolean/1, [:bool]},
    header_size: {:header, &non_neg_int?/1, [:non_neg_int]},
    high_msgq_watermark: {:high_msgq_watermark, &pos_int?/1, [:pos_int]},
    high_watermark: {:high_watermark, &non_neg_int?/1, [:non_neg_int]},
    keepalive?: {:keepalive, &is_boolean/1, [:bool]},
    line_delimiter: {:line_delimiter, &char?/1, [:char]},
    linger: {:linger, &linger?/1, [:see_docs]},
    local_port: {:port, &port?/1, [:non_neg_int]},
    low_msgq_watermark: {:low_msgq_watermark, &pos_int?/1, [:pos_int]},
    low_watermark: {:low_watermark, &non_neg_int?/1, [:non_neg_int]},
    network_namespace: {:netns, &is_binary/1, [:binary]},
    nodelay?: {:nodelay, &is_boolean/1, [:bool]},
    packet_type: {:packet, &packet_type?/1, [:raw, 1, 2, 4]},
    packet_size: {:packet_size, &pos_int?/1, [:pos_int]},
    priority: {:priority, &non_neg_int?/1, [:non_neg_int]},
    raw_fd: {:fd, &non_neg_int?/1, [:non_neg_int]},
    receive_buffer: {:recbuf, &non_neg_int?/1, [:non_neg_int]},
    receive_tclass?: {:recvtclass, &is_boolean/1, [:bool]},
    receive_tos?: {:recvtos, &is_boolean/1, [:bool]},
    receive_ttl?: {:recvttl, &is_boolean/1, [:bool]},
    reuse_addr?: {:reuseaddr, &is_boolean/1, [:bool]},
    send_timeout: {:send_timeout, &timeout?/1, [:infinity, :non_neg_int]},
    send_timeout_close?: {:send_timeout_close, &is_boolean/1, [:bool]},
    show_econnreset?: {:show_econnreset, &is_boolean/1, [:bool]},
    send_buffer: {:sndbuf, &non_neg_int?/1, [:non_neg_int]},
    tcp_module: {:tcp_module, &is_atom/1, [:atom]},
    tos: {:tos, &non_neg_int?/1, [:non_neg_int]},
    tclass: {:tclass, &non_neg_int?/1, [:non_neg_int]}
  ]
  @tcp_custom_options [
    :ipv4?,
    :ipv6?,
    :connect_timeout,
    :send_timeout,
    :receive_timeout,
    :tcp_opts,
    :active,
    :binary?,
    :host,
    :port,
    :bam_window,
    :raw,
    :network_interface
  ]
  # network_interface:   {:ip,                  &host?/1,        },
  @tcp_option_keys @tcp_custom_options ++ Keyword.keys(@tcp_table_options)

  defp create_connector(opts, tcp_opts) do
    with {:ok, conn_timeout} <-
           Options.default_timeout(opts, :connect_timeout, @default_connect_timeout),
         {:ok, receive_timeout} <-
           Options.default_timeout(opts, :receive_timeout, @default_receive_timeout),
         {:ok, bam_window} <-
           Options.default(opts, :bam_window, @default_bam_window, &window?/1, [:once, :pos_int]),
         {:ok, active} <-
           Options.default(opts, :active, @default_active, &active?/1, [:bool, :integer, :once]),
         {:ok, host} <- Options.required(opts, :host, &host?/1, [:binary, :ipv4, :ipv6]),
         {:ok, port} <- Options.required(opts, :port, &port?/1, [:pos_int]) do
      tcp = %Tcp{
        host: host,
        port: port,
        tcp_opts: tcp_opts,
        receive_timeout: receive_timeout,
        connect_timeout: conn_timeout,
        bam_window: bam_window,
        active: active
      }

      {:ok, Connector.new(__MODULE__, tcp)}
    end
  end

  defp tcp_options(opts) do
    with {:ok, active} <-
           Options.default(opts, :active, @default_active, &active?/1, [:bool, :integer, :once]),
         {:ok, mode} <- mode(opts),
         {:ok, send_timeout} <-
           Options.default_timeout(opts, :send_timeout, @default_send_timeout),
         {:ok, tcp_opts} <-
           Options.default(opts, :tcp_opts, @default_tcp_opts, &is_list/1, [:proplist]),
         :ok <- Options.check_extra_keys(opts, @tcp_option_keys),
         {:ok, table} <- Options.table_options(opts, @tcp_table_options),
         {:ok, ni} <- network_interface_options(opts),
         {:ok, ip} <- ip_opts(opts),
         {:ok, raw} <- raw_opts(opts) do
      synthetic = [active: active, mode: mode, send_timeout: send_timeout]
      {:ok, ip ++ ni ++ table ++ raw ++ synthetic ++ tcp_opts}
    end
  end

  defp network_interface_options(opts) do
    case Map.fetch(opts, :network_interface) do
      {:ok, ni} ->
        case host?(ni) do
          true -> {:ok, [{:ip, Util.host_address(ni)}]}
          _ -> {:error, BadOption.new(:network_interface, ni, [:binary, :ip])}
        end

      _ ->
        {:ok, []}
    end
  end

  @doc false
  def mode(opts) do
    Map.get(opts, :binary?, true)
    |> case do
      true ->
        {:ok, :binary}

      false ->
        {:ok, :list}

      binary? ->
        {:error, BadOption.new(:binary?, binary?, [:bool])}
    end
  end

  defp socket(socket, %Tcp{} = tcp) do
    opts = Map.take(tcp, [:host, :port, :active, :receive_timeout, :bam_window])

    try do
      with {:error, reason} <- Socket.Tcp.create(socket, opts) do
        :ok = :gen_tcp.close(socket)
        {:error, reason}
      end
    rescue
      e ->
        :gen_tcp.close(socket)
        {:error, e}
    end
  end

  defp ip_opts(opts) do
    ipv4? = Map.get(opts, :ipv4?, true)
    ipv6? = Map.get(opts, :ipv6?, false)

    case {ipv4?, ipv6?} do
      {true, true} ->
        {:ok, [:inet6]}

      {true, false} ->
        {:ok, [:inet]}

      {false, true} ->
        {:ok, [:inet6, {:ipv6_v6only, true}]}

      {x, _} when not is_boolean(x) ->
        {:error, BadOption.new(:ipv4?, ipv4?, [:bool])}

      {_, x} when not is_boolean(x) ->
        {:error, BadOption.new(:ipv6?, ipv6?, [:bool])}

      {false, false} ->
        {:error, BadCombo.new(%{ipv4?: ipv4?, ipv6?: ipv6?}, "May not both be false")}
    end
  end

  @doc false
  def raw_opts(opts) do
    case Map.fetch(opts, :raw) do
      {:ok, {protocol, optionnum, valuebin}} -> {:ok, [{:raw, protocol, optionnum, valuebin}]}
      {:ok, other} -> {:error, BadOption.new(:raw, other, [:see_docs])}
      :error -> {:ok, []}
    end
  end
end
