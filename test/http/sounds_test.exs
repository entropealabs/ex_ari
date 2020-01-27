defmodule ARI.HTTP.SoundsTest do
  use ExUnit.Case, async: true

  require Logger

  alias ARI.HTTP.Sounds
  alias ARI.TestServer

  @username "username1"
  @password "password2"

  setup_all do
    host = "localhost"
    {:ok, {_server_ref, <<"http://localhost:", port::binary>>}} = TestServer.start()

    Sounds.start_link([host, String.to_integer(port), @username, @password])

    []
  end

  test "list" do
    resp = Sounds.list()

    assert resp.json.path == "sounds" && resp.json.id == []
  end

  test "get" do
    resp = Sounds.get("test")

    assert resp.json.path == "sounds" && resp.json.id == ["test"]
  end
end
