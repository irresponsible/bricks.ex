defmodule Bricks.MixProject do
  use Mix.Project

  def project do
    [
      app: :bricks,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers() ++ [:protocol_ex]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: extra_applications(Mix.env())
    ]
  end

  defp extra_applications(:dev), do: extra_applications(:test)
  defp extra_applications(:test), do: [:stream_data | extra_applications(:default)]
  defp extra_applications(_), do: [:logger]

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/lib"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:protocol_ex, git: "https://github.com/OvermindDL1/protocol_ex", branch: "master"},
      {:protocol_ex, "~> 0.4.0"},
      {:dbg, "~> 1.0", only: :dev},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:stream_data, "~> 0.4", optional: true}
    ]
  end
end
