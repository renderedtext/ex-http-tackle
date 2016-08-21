defmodule HttpTackle.Mixfile do
  use Mix.Project

  def project do
    [app: :http_tackle,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [
      :plug,
      :cowboy,
      :logger,
      :tackle,
      :httpotion
    ]]
  end

  defp deps do
    [
     {:tackle, git: "git@github.com:renderedtext/ex-tackle", red: "origin/master"},
     {:cowboy, "~> 1.0"},
     {:plug, "~> 1.0"},
     {:httpotion, "~> 3.0.0"}
    ]
  end
end
