use Mix.Config

config :ex_ari,
  clients: %{
    ari_test: %{
      name: "test",
      module: ARI.WebSocketTest.TestClient
    }
  }
