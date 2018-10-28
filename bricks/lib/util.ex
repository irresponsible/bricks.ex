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

defmodule Bricks.Util do
  @moduledoc false

  alias Bricks.Socket
  alias Bricks.Guards
  require Guards
  import Guards, except: [is_active: 1]

  # Returns a binary describing a host. Accepts either binary(identity) or ip
  def hostname(h) when is_binary(h), do: h

  def hostname({a, b, c, d})
      when is_byte(a) and is_byte(b) and is_byte(c) and is_byte(d),
      do: "#{a}.#{b}.#{c}.#{d}"

  def hostname({a, b, c, d, e, f, g, h})
      when is_char(a) and is_char(b) and is_char(c) and is_char(d) and is_char(e) and is_char(f) and
             is_char(g) and is_char(h) do
    "#{v6_char(a)}:#{v6_char(b)}:#{v6_char(c)}:#{v6_char(d)}" <>
      ":#{v6_char(e)}:#{v6_char(f)}:#{v6_char(g)}:#{v6_char(h)}"
  end

  # Returns something we can connect to. If it looks like an IP, this
  # means turning it into an IP tuple

  def host_address({a, b, c, d} = me)
      when is_byte(a) and is_byte(b) and is_byte(c) and is_byte(d),
      do: me

  def host_address({a, b, c, d, e, f, g, h} = me)
      when is_char(a) and is_char(b) and is_char(c) and is_char(d) and is_char(e) and is_char(f) and
             is_char(g) and is_char(h),
      do: me

  def host_address(address) when is_binary(address) do
    address = String.to_charlist(address)

    case :inet.parse_strict_address(address) do
      {:ok, address} -> address
      _ -> address
    end
  end

  defp v6_char(c), do: String.pad_leading(Integer.to_string(c, 16), 2, "0")

  @doc false
  # True if the Socket is active
  def active?(%Socket{active: active}), do: active != false

  @doc false
  # True if the Socket is passive
  def passive?(%Socket{active: active}), do: active == false
end
