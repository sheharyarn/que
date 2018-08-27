defmodule Que.Mixfile do
  use Mix.Project

  @app     :que
  @name    "Que"
  @version "0.5.0"
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
      elixirc_paths: elixirc_paths(Mix.env),

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
      {:memento,  "~> 0.0.1"              },
      {:ex_utils, "~> 0.1.6"              },
      {:ex_doc,   ">= 0.0.0", only: :dev  },
      {:inch_ex,  ">= 0.0.0", only: :docs }
    ]
  end


  defp description do
    "Simple Background Job Processing with Mnesia"
  end

  # Compilation Paths
  defp elixirc_paths(:dev),  do: elixirc_paths(:test)
  defp elixirc_paths(:test), do: ["lib", "test/support.ex"]
  defp elixirc_paths(_),     do: ["lib"]


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

