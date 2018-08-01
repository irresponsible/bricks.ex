defmodule Bricks.Error.Timeout do
  @moduledoc """
  An error that occurs when a request doesn't respond in time.
  """

  @type t :: %Bricks.Error.Timeout{timeout: number, path: [binary]}

  @enforce_keys [:timeout, :path]
  defstruct @enforce_keys

  @spec new(number, [binary]) :: t

  def new(timeout, path \\ []),
    do: %Bricks.Error.Timeout{timeout: timeout, path: path}
end

defmodule Bricks.Error.Posix do
  @moduledoc """
  A wrapper around a standard POSIX error.
  """

  @type t :: %Bricks.Error.Posix{code: atom, path: {binary}}

  @enforce_keys [:code, :path]
  defstruct @enforce_keys

  @spec new(atom) :: t
  @spec new(atom, [binary]) :: t

  def new(code, path \\ []),
    do: %Bricks.Error.Posix{code: code, path: path}
end

defmodule Bricks.Error.Closed do
  @type t :: {}

  @enforce_keys [:path]
  defstruct @enforce_keys

  def new(path \\ []),
    do: %Bricks.Error.Closed{path: path}
end
