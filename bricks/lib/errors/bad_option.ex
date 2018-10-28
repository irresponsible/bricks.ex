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

defmodule Bricks.Error.BadOption do
  @moduledoc """
  A bad option was provided
  """
  @enforce_keys [:key, :val, :valid_types]
  defstruct @enforce_keys

  alias Bricks.Error.BadOption

  @typedoc "Key of the option"
  @type key :: term()

  @typedoc "Value of the option"
  @type val :: term()

  @typedoc "A bad option was provided"
  @type t :: %BadOption{
          key: key(),
          val: val(),
          valid_types: [term()]
        }

  @spec new(key(), val(), [term()]) :: t()
  @doc "Creates a new `BadOption` with the given `key`, `val` and `valid_types`"
  def new(key, val, valid_types) do
    %BadOption{key: key, val: val, valid_types: valid_types}
  end
end
