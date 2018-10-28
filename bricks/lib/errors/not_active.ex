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

defmodule Bricks.Error.NotActive do
  @moduledoc """
  The Socket was active when it was supposed to be passive
  """
  @enforce_keys []
  defstruct @enforce_keys

  alias Bricks.Error.NotActive

  @typedoc "The Socket was active when it was supposed to be passive"
  @type t :: %NotActive{}

  @spec new() :: t()
  @doc "Creates a new `NotActive`"
  def new(), do: %NotActive{}
end
