defmodule ARI.HTTP.ApplicationsTest do
  use ExUnit.Case, async: true

  require Logger

  alias ARI.HTTP.Applications
  alias ARI.TestServer

  @username "username1"
  @password "password2"

  setup_all do
    host = "localhost"
    {:ok, {_server_ref, <<"http://localhost:", port::binary>>}} = TestServer.start()

    Applications.start_link([host, String.to_integer(port), @username, @password])

    []
  end

  test "list" do
    resp = Applications.list()
    assert resp.json.path == "applications" && resp.json.id == []
  end

  test "get" do
    resp = Applications.get("pjsip")

    assert resp.json.path == "applications" &&
             resp.json.id == ["pjsip"]
  end

  test "subscribe" do
    resp = Applications.subscribe("pjsip")

    assert resp.json.path == "applications" &&
             resp.json.id == ["pjsip", "subscription"]
  end

  test "unsubscribe" do
    resp = Applications.unsubscribe("pjsip")

    assert resp.json.path == "applications" &&
             resp.json.id == ["pjsip", "subscription"]
  end
end
