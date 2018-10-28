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

defmodule Bricks.Guards do
  @moduledoc false

  defguard is_byte(x) when is_integer(x) and x >= 0 and x <= 255
  defguard is_char(x) when is_integer(x) and x >= 0 and x <= 0x10FFFF

  defguard is_opt_atom(x) when is_atom(x) or is_nil(x)
  defguard is_opt_bool(x) when is_boolean(x) or is_nil(x)
  defguard is_opt_int(x) when is_integer(x) or is_nil(x)

  defguard is_int_gte(x, min) when is_integer(x) and x >= min
  defguard is_int_in_range(x, min, max) when is_integer(x) and x >= min and x <= max

  defguard is_active(x) when is_boolean(x) or x == :once or is_int_in_range(x, -32767, 32766)
  defguard is_window(x) when x == :once or is_int_gte(x, 1)
  defguard is_timeout(x) when is_int_gte(x, 0) or x == :infinity

  defguard is_opt_active(x) when is_nil(x) or is_active(x)
  defguard is_opt_timeout(x) when is_nil(x) or is_timeout(x)

  defguard is_non_neg_int(x) when is_integer(x) and x >= 0
  defguard is_pos_int(x) when is_integer(x) and x > 0

  defguard is_port_num(x) when is_non_neg_int(x)

  defguard is_deliver(x) when x in [:port, :term]

  def byte?(x), do: is_byte(x)
  def char?(x), do: is_char(x)

  def opt_atom?(x), do: is_opt_atom(x)
  def opt_bool?(x), do: is_opt_bool(x)
  def opt_int?(x), do: is_opt_int(x)

  def int_gte?(x, min), do: is_int_gte(x, min)
  def int_in_range?(x, min, max), do: is_int_in_range(x, min, max)

  def active?(x), do: is_active(x)
  def window?(x), do: is_window(x)
  def timeout?(x), do: is_timeout(x)

  def opt_active?(x), do: is_opt_active(x)
  def opt_timeout?(x), do: is_opt_timeout(x)

  def non_neg_int?(x), do: is_non_neg_int(x)
  def pos_int?(x), do: is_pos_int(x)

  def port?(x), do: is_port_num(x)
  def deliver?(x), do: is_deliver(x)

  def linger?({x, y}), do: is_boolean(x) and is_pos_int(y)
  def linger?(_), do: false

  @packet_types [
    :raw,
    1,
    2,
    4,
    :asn1,
    :cdr,
    :sunrm,
    :fcgi,
    :tpkt,
    :line,
    :http,
    :http_bin,
    :httph,
    :httph_bin
  ]

  def packet_type?(x), do: x in @packet_types

  @doc false
  # True if the provided value is a binary or an ip
  def host?(h) when is_binary(h), do: true

  def host?({a, b, c, d})
      when is_byte(a) and is_byte(b) and is_byte(c) and is_byte(d),
      do: true

  def host?({a, b, c, d, e, f, g, h})
      when is_char(a) and is_char(b) and is_char(c) and is_char(d) and is_char(e) and is_char(f) and
             is_char(g) and is_char(h),
      do: true

  def host?(_), do: false
end
