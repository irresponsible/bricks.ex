defmodule Bricks.Error.Timeout do
  @enforce_keys [:timeout, :path]
  defstruct @enforce_keys

  def new(timeout, path \\ []),
    do: %Bricks.Error.Timeout{timeout: timeout, path: path}
end

defmodule Bricks.Error.Posix do
  @enforce_keys [:code, :path]
  defstruct @enforce_keys

  def new(code, path \\ []),
    do: %Bricks.Error.Posix{code: code, path: path}
end

defmodule Bricks.Error.Closed do
  @enforce_keys [:path]
  defstruct @enforce_keys

  def new(path \\ []),
    do: %Bricks.Error.Closed{path: path}
end
