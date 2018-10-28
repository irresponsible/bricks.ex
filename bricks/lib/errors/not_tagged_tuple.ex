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

defmodule Bricks.Error.NotTaggedTuple do
  @moduledoc """
  We expected a tagged tuple
  """
  @enforce_keys [:valid_tags, :value]
  defstruct @enforce_keys

  alias Bricks.Error.NotTaggedTuple

  @typedoc "We expected a tagged tuple"
  @type t :: %NotTaggedTuple{
          valid_tags: [atom()],
          value: term()
        }

  @spec new([atom()], term()) :: t()
  @doc "Creates a new `NotTaggedTuple` with the given `valid_tags` and `value`"
  def new(valid_tags, value) do
    %NotTaggedTuple{valid_tags: valid_tags, value: value}
  end
end
