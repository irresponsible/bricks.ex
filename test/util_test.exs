defmodule Bricks.UtilTest do
  use ExUnit.Case
  alias Bricks.Util

  doctest Bricks.Util

  @invalid_host "$@%#$%#%$#"
  test "resolve_host" do
   {:error, {:invalid_host, @invalid_host, _}} = Util.resolve_host(@invalid_host)
  end
end
