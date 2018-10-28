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

defmodule Bricks.UtilTest do
  use ExUnit.Case
  use ExUnitProperties

  alias Bricks.{Socket, Util}

  doctest Util

  describe "hostname" do
    check all ipv4 <- StreamData.list_of(StreamData.integer(0..255), length: 4),
              ipv6 <- StreamData.list_of(StreamData.integer(0..65535), length: 8),
              bin <- StreamData.string(:alphanumeric) do
      assert Enum.join(ipv4, ".") == Util.hostname(List.to_tuple(ipv4))

      ipv62 = Enum.map(ipv6, &String.pad_leading(Integer.to_string(&1, 16), 2, "0"))
      assert Enum.join(ipv62, ":") == Util.hostname(List.to_tuple(ipv6))

      assert bin == Util.hostname(bin)
    end
  end

  test "host_address" do
    check all ipv4 <- StreamData.list_of(StreamData.integer(0..255), length: 4),
              ipv6 <- StreamData.list_of(StreamData.integer(0..65535), length: 8),
              bin <- StreamData.string(:alphanumeric) do
      assert List.to_tuple(ipv4) == Util.host_address(Enum.join(ipv4, "."))

      ipv62 = Enum.map(ipv6, &String.pad_leading(Integer.to_string(&1, 16), 2, "0"))
      assert List.to_tuple(ipv6) == Util.host_address(Enum.join(ipv62, ":"))

      assert String.to_charlist(bin) == Util.host_address(bin)
    end
  end

  test "active? and passive?" do
    for x <- [1, true] do
      assert true == Util.active?(%{__struct__: Socket, active: x})
      assert false == Util.passive?(%{__struct__: Socket, active: x})
    end

    assert false == Util.active?(%{__struct__: Socket, active: false})
    assert true == Util.passive?(%{__struct__: Socket, active: false})
  end
end
