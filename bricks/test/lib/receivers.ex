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

defmodule Bricks.Test.Receivers do
  alias Bricks.Socket
  import Bricks.Sugar

  def collect_bytes_passive(data, sock, target, timeout \\ 1000) do
    if byte_size(data) >= target do
      data
    else
      {:ok, extra, %Socket{}} = Socket.recv(sock, 0, timeout)
      collect_bytes_passive(data <> extra, sock, target, timeout)
    end
  end

  def collect_bytes_active(data, sock, target, timeout \\ 1000) do
    if byte_size(data) >= target do
      data
    else
      %Socket{handle: h} = sock

      receive do
        {:tcp, ^h, extra} ->
          collect_bytes_active(data <> extra, sock, target, timeout)
      after
        1000 -> throw({:timeout, data})
      end
    end
  end

  def collect_bytes_active_macros(data, sock, target, timeout \\ 1000) do
    if byte_size(data) >= target do
      data
    else
      binding sock do
        receive do
          match_closed() ->
            {:closed, data}

          match_error(reason) ->
            {:error, reason}

          match_data(extra) ->
            collect_bytes_active_macros(data <> extra, sock, target, timeout)
        after
          timeout -> {:timeout, data}
        end
      end
    end
  end

  def collect_bytes_bounded(data, sock, target, timeout \\ 1000) do
    if byte_size(data) >= target do
      data
    else
      {:ok, sock} = Socket.extend_active(sock)
      %Socket{handle: h} = sock

      receive do
        {:tcp, ^h, extra} ->
          collect_bytes_bounded(data <> extra, sock, target, timeout)
      after
        2000 -> throw({:timeout, data})
      end
    end
  end

  def collect_bytes_bounded_macros(data, sock, target, timeout \\ 1000) do
    if byte_size(data) >= target do
      data
    else
      {:ok, sock} = Socket.extend_active(sock)

      binding sock do
        receive do
          match_data(extra) -> collect_bytes_bounded_macros(data <> extra, sock, target, timeout)
          match_error(reason) -> {:error, reason}
          match_closed() -> {:closed, data}
          match_passive() -> collect_bytes_bounded_macros(data, sock, target, timeout)
        after
          timeout -> {:timeout, data}
        end
      end
    end
  end
end
