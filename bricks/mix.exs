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

defmodule Bricks.MixProject do
  use Mix.Project

  def project do
    [
      app: :bricks,
      description: "The elixir sockets library of your dreams",
      version: "0.1.0",
      elixir: "~> 1.7",
      package: [
        licenses: ["Apache 2"],
        links: %{
          "Repository" => "https://github.com/irresponsible/bricks.ex",
          "Hexdocs" => "https://hexdocs.pm/bricks"
        }
      ],
      docs: [
        name: "bricks",
        main: "readme",
        source_url: "https://github.com/irresponsible/bricks.ex",
        extras: [
          "README.md",
          "CONDUCT.md"
        ],
        # groups_for_extras: [
        # ]
        groups_for_modules: [
          Connectors: [
            "Bricks.Connector",
            "Bricks.Connector.Tcp",
            "Bricks.Connector.Unix"
          ],
          Sockets: [
            "Bricks.Socket",
            "Bricks.Socket.Tcp"
          ],
          "Macro Sugar": [
            "Bricks.Sugar"
          ],
          Errors: [
            "Bricks.Error.BadCombo",
            "Bricks.Error.BadOption",
            "Bricks.Error.Closed",
            "Bricks.Error.Connect",
            "Bricks.Error.NotActive",
            "Bricks.Error.NotPassive",
            "Bricks.Error.NotTaggedTuple",
            "Bricks.Error.Posix",
            "Bricks.Error.Timeout",
            "Bricks.Error.UnknownOptions"
          ]
        ]
      ],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: extra_applications(Mix.env())
    ]
  end

  def extra_applications(:test), do: [:logger, :stream_data]
  def extra_applications(:dev), do: [:logger, :stream_data]
  def extra_applications(_), do: [:logger]

  defp elixirc_paths(:test), do: ["lib", "test/lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:dialyxir, "~> 1.0.0-rc.3", only: :dev, runtime: false},
      {:dbg, "~> 1.0", only: [:dev, :test]},
      {:ex_doc, git: "https://github.com/elixir-lang/ex_doc", branch: "master", only: [:dev]},
      {:stream_data, "~> 0.4", optional: true}
    ]
  end
end
