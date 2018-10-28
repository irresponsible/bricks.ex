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

defmodule Bricks.Error.Posix do
  @moduledoc """
  Wrapper for a POSIX error code
  """
  @enforce_keys [:code]
  defstruct @enforce_keys

  alias Bricks.Error.{Posix, Timeout}

  @typedoc "Wrapper for a POSIX error code"
  @type t :: %Posix{
          code: :inet.posix()
        }

  @spec new(:inet.posix()) :: Timeout.t() | t()
  @doc """
  Creates a new `Posix` from the given error code, unless the error
  code was `:etimedout`, when we return a `Bricks.Error.Timeout`.
  """
  def new(:etimedout), do: Timeout.new()
  def new(code), do: %__MODULE__{code: code}
end
