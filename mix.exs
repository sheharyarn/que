defmodule Que.Mixfile do
  use Mix.Project

  @app     :que
  @name    "Que"
  @version "0.2.0"
  @github  "https://github.com/sheharyarn/#{@app}"


  def project do
    [
      # Project
      app:          @app,
      version:      @version,
      elixir:       "~> 1.4",
      description:  description(),
      package:      package(),
      deps:         deps(),

      # ExDoc
      name:         @name,
      source_url:   @github,
      homepage_url: @github,
      docs: [
        main:       @name,
        canonical:  "https://hexdocs.pm/#{@app}",
        extras:     ["README.md"]
      ]
    ]
  end


  def application do
    [
      mod: {Que, []},
      applications: [:logger, :amnesia]
    ]
  end


  defp deps do
    [
      {:amnesia,  "~> 0.2"                },
      {:ex_utils, ">= 0.0.0"              },
      {:ex_doc,   ">= 0.0.0", only: :dev  },
      {:inch_ex,  ">= 0.0.0", only: :docs }
    ]
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

