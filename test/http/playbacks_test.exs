defmodule ARI.HTTP.PlaybacksTest do
  use ExUnit.Case, async: true

  require Logger

  alias ARI.HTTP.Playbacks
  alias ARI.TestServer

  @username "username1"
  @password "password2"

  setup_all do
    host = "localhost"
    {:ok, {_server_ref, <<"http://localhost:", port::binary>>}} = TestServer.start()

    Playbacks.start_link([host, String.to_integer(port), @username, @password])

    []
  end

  test "get" do
    resp = Playbacks.get("my-playback")
    assert resp.json.path == "playbacks" && resp.json.id == ["my-playback"]
  end

  test "stop" do
    resp = Playbacks.stop("my-playback")
    assert resp.json.path == "playbacks" && resp.json.id == ["my-playback"]
  end

  test "control" do
    resp = Playbacks.control("my-playback", "pause")

    assert resp.json.path == "playbacks" &&
             resp.json.id == ["my-playback", "control"] &&
             resp.json.query_params.operation == "pause"
  end
end
