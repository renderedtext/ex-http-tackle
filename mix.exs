defmodule HttpTackle.Mixfile do
  use Mix.Project

  def project do
    [app: :http_tackle,
     version: "0.0.1",
     elixir: "~> 1.5",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [
      :plug,
      :cowboy,
      :logger,
      :tackle,
      :httpoison
    ]]
  end

  defp deps do
    [
     {:tackle, github: "renderedtext/ex-tackle"},
     {:cowboy, "~> 1.0"},
     {:plug, "~> 1.5"},
     {:httpoison, "~> 1.1"}
    ]
  end
end
