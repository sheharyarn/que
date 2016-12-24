defmodule Que.Mixfile do
  use Mix.Project

  @app     :que
  @name    "Que"
  @version "0.1.0-alpha.0"
  @github  "https://github.com/sheharyarn/#{@app}"

  def project do
    [
      # Project
      app:          @app,
      version:      @version,
      elixir:       "~> 1.3",
      description:  description(),
      package:      package(),
      deps:         deps(),

      # ExDoc
      name:         @name,
      source_url:   @github,
      homepage_url: @github,
      docs: [
        main:       @name,
        canonical:  "https://hexdocs.com/#{@app}",
        extras:     ["README.md"]
      ]
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:ex_doc, ">= 0.0.0", only: :dev}]
  end

  defp description do
    "Background Job Processor for Elixir"
  end

  defp package do
    [
      name: @app,
      maintainers: ["Sheharyar Naseer"],
      licenses: ["MIT"],
      files: ~w(mix.exs lib README.md),
      links: %{"Github" => @github}
    ]
  end
end

