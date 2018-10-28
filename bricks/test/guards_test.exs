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

defmodule Bricks.GuardsTest do
  use ExUnit.Case
  use ExUnitProperties

  import Bricks.Guards

  property "is_byte / byte?" do
    check all yes <- StreamData.integer(0..255),
              no <-
                StreamData.filter(StreamData.term(), fn x ->
                  not (is_integer(x) and x >= 0 and x <= 255)
                end) do
      assert true == is_byte(yes)
      assert false == is_byte(no)
      assert true == byte?(yes)
      assert false == byte?(no)
    end
  end

  property "is_char / char?" do
    check all yes <- StreamData.integer(0..0x10FFFF),
              no <-
                StreamData.filter(StreamData.term(), fn x ->
                  not (is_integer(x) and x >= 0 and x <= 0x10FFFF)
                end) do
      assert true == is_char(yes)
      assert false == is_char(no)
      assert true == char?(yes)
      assert false == char?(no)
    end
  end

  property "is_timeout" do
    check all yes <- StreamData.integer(0..65535),
              no <-
                StreamData.filter(StreamData.term(), fn x ->
                  not (is_integer(x) and x >= 0) and x != :infinity
                end) do
      assert true == is_timeout(yes)
      assert false == is_timeout(no)
    end

    assert true == is_timeout(:infinity)
  end

  property "is_opt_timeout" do
    check all yes <- StreamData.integer(0..65535),
              no <-
                StreamData.filter(StreamData.term(), fn x ->
                  not (is_integer(x) and x >= 0) and x != :infinity and not is_nil(x)
                end) do
      assert true == is_opt_timeout(yes)
      assert false == is_opt_timeout(no)
    end

    assert true == is_opt_timeout(:infinity)
    assert true == is_opt_timeout(nil)
  end

  property "is_active / active?" do
    check all yes <-
                StreamData.one_of([
                  StreamData.boolean(),
                  StreamData.constant(:once),
                  StreamData.integer(-32767..32766)
                ]),
              no <-
                StreamData.filter(term(), fn x ->
                  not (is_boolean(x) or (is_integer(x) and x >= -32767 and x <= 32766) or
                         x == :once)
                end) do
      assert true == is_active(yes)
      assert false == is_active(no)
      assert true == active?(yes)
      assert false == active?(no)
    end
  end

  property "is_opt_active / opt_active?" do
    check all yes <-
                StreamData.one_of([
                  StreamData.boolean(),
                  StreamData.constant(:once),
                  StreamData.integer(-32767..32766),
                  StreamData.constant(nil)
                ]),
              no <-
                StreamData.filter(term(), fn x ->
                  not (is_boolean(x) or (is_integer(x) and x >= -32767 and x <= 32766) or
                         x == :once or is_nil(x))
                end) do
      assert true == is_opt_active(yes)
      assert false == is_opt_active(no)
      assert true == opt_active?(yes)
      assert false == opt_active?(no)
    end
  end

  property "is_window / window?" do
    check all yes <-
                StreamData.one_of([StreamData.constant(:once), StreamData.integer(1..32766)]),
              no <-
                StreamData.filter(term(), fn x ->
                  not ((is_integer(x) and x > 0 and x <= 32766) or x == :once)
                end) do
      assert true == is_window(yes)
      assert false == is_window(no)
      assert true == window?(yes)
      assert false == window?(no)
    end
  end

  property "is_port_num / port? / is_non_neg_int / non_neg_int?" do
    check all yes <- StreamData.integer(0..65535),
              no <-
                StreamData.filter(term(), fn x ->
                  not (is_integer(x) and x >= 0 and x <= 65535)
                end) do
      assert true == is_port_num(yes)
      assert false == is_port_num(no)
      assert true == port?(yes)
      assert false == port?(no)
      assert true == is_non_neg_int(yes)
      assert false == is_non_neg_int(no)
      assert true == non_neg_int?(yes)
      assert false == non_neg_int?(no)
    end
  end

  property "is_pos_int / pos_int?" do
    check all yes <- StreamData.integer(1..65535),
              no <-
                StreamData.filter(term(), fn x -> not (is_integer(x) and x > 0 and x <= 65535) end) do
      assert true == is_pos_int(yes)
      assert false == is_pos_int(no)
      assert true == pos_int?(yes)
      assert false == pos_int?(no)
    end
  end

  property "is_int_gte / int_gte?" do
    check all min <- StreamData.integer(-65536..65536),
              yes <- StreamData.integer(min..281_474_976_710_656),
              no <- StreamData.filter(term(), fn x -> not (is_integer(x) and x >= min) end) do
      assert true == is_int_gte(yes, min)
      assert false == is_int_gte(no, min)
      assert true == int_gte?(yes, min)
      assert false == int_gte?(no, min)
    end
  end

  property "is_int_in_range / int_in_range?" do
    check all min <- StreamData.integer(-65536..65536),
              max <- StreamData.integer(min..281_474_976_710_656),
              yes <- StreamData.integer(min..max),
              no <- StreamData.filter(term(), fn x -> not (is_integer(x) and x >= min) end) do
      assert true == is_int_in_range(yes, min, max)
      assert false == is_int_in_range(no, min, max)
      assert true == int_in_range?(yes, min, max)
      assert false == int_in_range?(no, min, max)
    end
  end

  property "is_opt_atom / opt_atom?" do
    check all yes <- StreamData.atom(:alphanumeric),
              no <-
                StreamData.filter(StreamData.term(), fn x -> not (is_atom(x) or is_nil(x)) end) do
      assert true == is_opt_atom(yes)
      assert false == is_opt_atom(no)
      assert true == opt_atom?(yes)
      assert false == opt_atom?(no)
    end

    assert true == is_opt_atom(nil)
    assert true == opt_atom?(nil)
  end

  property "is_opt_bool / opt_bool?" do
    check all yes <- StreamData.member_of([true, false, nil]),
              no <-
                StreamData.filter(StreamData.term(), fn x -> not (is_boolean(x) or is_nil(x)) end) do
      assert true == is_opt_bool(yes)
      assert false == is_opt_bool(no)
      assert true == opt_bool?(yes)
      assert false == opt_bool?(no)
    end
  end

  property "is_opt_int / opt_int?" do
    check all yes <- StreamData.integer(-65536..65536),
              no <-
                StreamData.filter(StreamData.term(), fn x -> not (is_integer(x) or is_nil(x)) end) do
      assert true == is_opt_int(yes)
      assert false == is_opt_int(no)
      assert true == opt_int?(yes)
      assert false == opt_int?(no)
    end

    assert true == is_opt_int(nil)
    assert true == opt_int?(nil)
  end

  describe "host?" do
    check all ipv4 <- StreamData.list_of(StreamData.integer(0..255), length: 4),
              ipv6 <- StreamData.list_of(StreamData.integer(0..65535), length: 8),
              bin <- StreamData.binary(),
              no <- StreamData.filter(term(), fn x -> not (is_tuple(x) or is_binary(x)) end) do
      assert true == host?(List.to_tuple(ipv4))
      assert true == host?(List.to_tuple(ipv6))
      assert true == host?(bin)
      assert false == host?(no)
    end
  end
end
