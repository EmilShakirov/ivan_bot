defmodule Andriy.Mixfile do
  use Mix.Project

  def project do
    [app: :ivan_bot,
      version: "0.0.1",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps]
  end

  def application do
    [applications: [:alice, :timex],
      mod: {
        Alice, %{
          handlers: [
            Alice.Handlers.Standup
          ]
        }
      }
    ]
  end

  defp deps do
     [
       {:alice, github: "vaihtovirta/alice", branch: "upgrade-slack-dependency"},
       {:jira, "~> 0.0.8"},
       {:timex, "~> 3.0"},
       {:websocket_client, "~> 1.1.0"},
       {:credo, "~> 0.5", only: [:dev, :test]},
       {:earmark, "~> 0.1", only: :dev},
       {:ex_doc, "~> 0.11", only: :dev},
       {:mock, "~> 0.2.0", only: :test},
     ]
  end
end
