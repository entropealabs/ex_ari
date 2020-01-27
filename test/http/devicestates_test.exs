defmodule ARI.HTTP.DevicestatesTest do
  use ExUnit.Case, async: true

  require Logger

  alias ARI.HTTP.Devicestates
  alias ARI.TestServer

  @username "username1"
  @password "password2"

  setup_all do
    host = "localhost"
    {:ok, {_server_ref, <<"http://localhost:", port::binary>>}} = TestServer.start()

    Devicestates.start_link([host, String.to_integer(port), @username, @password])

    []
  end

  test "list" do
    resp = Devicestates.list()
    assert resp.json.path == "deviceStates" && resp.json.id == []
  end

  test "get" do
    resp = Devicestates.get("my-device")

    assert resp.json.path == "deviceStates" &&
             resp.json.id == ["my-device"]
  end

  test "update" do
    resp = Devicestates.update("my-device", "BUSY")

    assert resp.json.path == "deviceStates" &&
             resp.json.id == ["my-device"] &&
             resp.json.query_params.deviceState == "BUSY"
  end

  test "delete" do
    resp = Devicestates.delete("my-device")

    assert resp.json.path == "deviceStates" &&
             resp.json.id == ["my-device"]
  end
end
