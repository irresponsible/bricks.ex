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

defmodule Bricks.OptionsTest do
  use ExUnit.Case
  use ExUnitProperties
  alias Bricks.{Gen, Options}
  alias Bricks.Error.{BadOption, UnknownOptions}
  import Bricks.Guards

  property "optional" do
    check all k <- term(), k2 <- term(), v <- term() do
      assert [] == Options.optional(%{}, [{k, v}])
      assert [] == Options.optional(%{}, k, v)
      assert [{k, v}] == Options.optional(%{k => v}, [{k, k}])
      assert [{k2, v}] == Options.optional(%{k => v}, k, k2)
    end
  end

  property "required" do
    check all k <- term(),
              yes <- Gen.pos_int(),
              no <- Gen.anything_but(&pos_int?/1) do
      assert {:ok, yes} == Options.required(%{k => yes}, k, &pos_int?/1, [:foo])

      assert {:error, BadOption.new(k, no, [:foo])} ==
               Options.required(%{k => no}, k, &pos_int?/1, [:foo])

      assert {:error, BadOption.new(k, nil, [:foo])} ==
               Options.required(%{}, k, &pos_int?/1, [:foo])
    end
  end

  property "default" do
    check all k <- term(),
              yes <- Gen.pos_int(),
              no <- Gen.anything_but(&pos_int?/1) do
      assert {:ok, yes} == Options.default(%{k => yes}, k, yes, &pos_int?/1, [:foo])
      assert {:ok, yes} == Options.default(%{}, k, yes, &pos_int?/1, [:foo])

      assert {:error, BadOption.new(k, no, [:foo])} ==
               Options.default(%{k => no}, k, yes, &pos_int?/1, [:foo])
    end
  end

  property "default_timeout" do
    check all k <- term(),
              yes <- Gen.timeout(),
              no <- Gen.anything_but(&timeout?/1) do
      assert {:ok, yes} == Options.default_timeout(%{k => yes}, k, yes)
      assert {:ok, yes} == Options.default_timeout(%{}, k, yes)

      assert {:error, BadOption.new(k, no, [:infinity, :non_neg_int])} ==
               Options.default_timeout(%{k => no}, k, yes)
    end
  end

  property "check_extra_keys" do
    # Capped for runtime, I think we can rely on such basic primitives to work regardless of size (ha!)
    check all starting <- StreamData.map_of(Gen.pos_int(), term(), max_length: 5),
              extra <-
                StreamData.map_of(Gen.alphanum_string(), term(), min_length: 1, max_length: 5) do
      assert :ok = Options.check_extra_keys(starting, Map.keys(starting))
      combined = Map.merge(starting, extra)

      assert {:error, %UnknownOptions{keys: keys}} =
               Options.check_extra_keys(combined, Map.keys(starting))

      assert Enum.sort(keys) == Enum.sort(Map.keys(extra))
    end
  end

  property "table_option" do
    check all k <- StreamData.term(),
              k2 <- StreamData.term(),
              yes <- Gen.pos_int(),
              no <- Gen.alphanum_string(),
              extra <- StreamData.list_of(term(), max_length: 3) do
      assert {:cont, [{k2, yes} | extra]} ==
               Options.table_option(%{k => yes}, k, k2, &pos_int?/1, [:foo], extra)

      assert {:cont, extra} == Options.table_option(%{}, k, k2, &pos_int?/1, [:foo], extra)
      err = BadOption.new(k, no, [:foo])

      assert {:halt, {:error, err}} ==
               Options.table_option(%{k => no}, k, k2, &pos_int?/1, [:foo], extra)
    end
  end

  property "table_options" do
    check all k <- StreamData.term(),
              k2 <- StreamData.term(),
              yes <- Gen.pos_int(),
              no <- Gen.alphanum_string(),
              extra <- StreamData.list_of(term(), max_length: 3) do
      assert {:ok, [{k2, yes} | extra]} ==
               Options.table_options(%{k => yes}, [{k, {k2, &pos_int?/1, [:foo]}}], extra)

      assert {:ok, extra} == Options.table_options(%{}, [{k, {k2, &pos_int?/1, [:foo]}}], extra)
      err = BadOption.new(k, no, [:foo])

      assert {:error, err} ==
               Options.table_options(%{k => no}, [{k, {k2, &pos_int?/1, [:foo]}}], extra)
    end
  end
end
