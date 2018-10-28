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

defmodule Bricks.Options do
  @moduledoc false
  alias Bricks.Error.{BadOption, UnknownOptions}

  import Bricks.Guards

  def optional(opts, defs) do
    defs
    |> Enum.map(fn {k, v} -> optional(opts, k, v) end)
    |> Enum.concat()
  end

  def optional(opts, key, prop_key) do
    case Map.fetch(opts, key) do
      {:ok, val} -> [{prop_key, val}]
      _ -> []
    end
  end

  def required(opts, key, test, valid) do
    case Map.fetch(opts, key) do
      {:ok, val} ->
        if test.(val) do
          {:ok, val}
        else
          {:error, BadOption.new(key, val, valid)}
        end

      _ ->
        {:error, BadOption.new(key, nil, valid)}
    end
  end

  def default(opts, key, default, test, permitted) do
    val = Map.get(opts, key, default)

    if test.(val) do
      {:ok, val}
    else
      {:error, BadOption.new(key, val, permitted)}
    end
  end

  def default_timeout(opts, key, default) do
    default(opts, key, default, &timeout?/1, [:infinity, :non_neg_int])
  end

  def check_extra_keys(opts, keys) do
    (Map.keys(opts) -- keys)
    |> case do
      [] -> :ok
      keys -> {:error, UnknownOptions.new(keys)}
    end
  end

  def table_option(opts, key, prop_key, test, valid, acc \\ []) do
    case Map.fetch(opts, key) do
      {:ok, val} ->
        case test.(val) do
          true -> {:cont, [{prop_key, val} | acc]}
          _ -> {:halt, {:error, BadOption.new(key, val, valid)}}
        end

      _ ->
        {:cont, acc}
    end
  end

  def table_options(opts, table, extra \\ []) do
    Enum.reduce_while(table, extra, fn {k, {k2, test, valid}}, acc ->
      table_option(opts, k, k2, test, valid, acc)
    end)
    |> case do
      {:error, reason} -> {:error, reason}
      other -> {:ok, other}
    end
  end
end
