defmodule ExAri.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_ari,
      version: "0.1.2",
      elixir: "~> 1.7",
      package: package(),
      description: description(),
      name: "ARI",
      source_url: "https://github.com/citybaseinc/ex_ari",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      deps: deps(),
      docs: [
        # The main page in the docs
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      env: default_env()
    ]
  end

  defp elixirc_paths(:test), do: ['lib', 'test/support']
  defp elixirc_paths(_), do: ['lib']

  defp default_env do
    [
      router: %{
        name: "router",
        module: ARI.Router,
        extensions: %{}
      },
      record_call: %{
        name: "record_call",
        module: ARI.RecordCall
      },
      transfer: %{
        name: "transfer",
        module: ARI.Transfer
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.12.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.21.2", only: [:dev, :test], runtime: false},
      {:jason, "~> 1.1"},
      {:mint, "~> 1.0"},
      {:plug, "~> 1.8", only: [:dev, :test]},
      {:plug_cowboy, "~> 2.1", only: [:dev, :test]},
      {:uuid, "~> 1.1"},
      {:websockex, "~> 0.4"}
    ]
  end

  defp description do
    "Library for interfacing with Asterisk using ARI"
  end

  defp package do
    [
      organization: "citybase",
      files: ~w(lib mix.exs README*),
      licenses: ["Apache-2.0"],
      links: %{"Github" => "https://github.com/citybaseinc/ex_ari"}
    ]
  end
end
