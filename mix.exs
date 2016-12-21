defmodule Andriy.Mixfile do
  use Mix.Project

  def project do
    [ app: :acl_ivan_bot,
      version: "0.0.1",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps ]
  end

  def application do
    [ applications: [:alice, :quantum],
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
       {:credo, "~> 0.5", only: [:dev, :test]},
       {:quantum, ">= 1.8.1"},
       {:timex, "~> 3.0"},
       {:websocket_client, "~> 1.1.0"},
     ]
  end
end
