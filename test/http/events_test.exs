defmodule ARI.HTTP.EventsTest do
  use ExUnit.Case, async: true

  require Logger

  alias ARI.HTTP.Events
  alias ARI.TestServer

  @username "username1"
  @password "password2"

  setup_all do
    host = "localhost"
    {:ok, {_server_ref, <<"http://localhost:", port::binary>>}} = TestServer.start()

    Events.start_link([host, String.to_integer(port), @username, @password])

    []
  end

  test "create" do
    resp = Events.create("test-event", "test-app", ["channel:test-channel"], %{variables: %{}})

    assert resp.json.path == "events" && resp.json.id == ["user", "test-event"] &&
             resp.json.query_params.application == "test-app" &&
             resp.json.query_params.source == "channel:test-channel" &&
             resp.json.body_params.variables == %{}
  end
end
