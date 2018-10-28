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

defmodule Bricks.Error.UnknownOptions do
  @moduledoc """
  Some unrecognised options were provided
  """
  @enforce_keys [:keys]
  defstruct @enforce_keys

  alias Bricks.Error.UnknownOptions

  @typedoc "Some unrecognised options were provided"
  @type t :: %UnknownOptions{
          keys: [term()]
        }

  @spec new([term()]) :: t()
  @doc "Creates a new `UnknownOptions` from the given `keys`"
  def new(keys), do: %UnknownOptions{keys: keys}
end
