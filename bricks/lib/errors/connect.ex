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

defmodule Bricks.Error.Connect do
  @moduledoc """
  An error occurred while connecting
  """
  @enforce_keys [:cause]
  defstruct @enforce_keys

  alias Bricks.Error.Connect

  @typedoc "An error occurred while connecting"
  @type t :: %Connect{
          cause: term()
        }

  @spec new(term()) :: t()
  @doc "Creates a new `Connect` with the given `cause`"
  def new(cause), do: %__MODULE__{cause: cause}
end
