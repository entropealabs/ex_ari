defmodule ARI.HTTP.RecordingsTest do
  use ExUnit.Case, async: true

  require Logger

  alias ARI.HTTP.Recordings
  alias ARI.TestServer

  @username "username1"
  @password "password2"

  setup_all do
    host = "localhost"
    {:ok, {_server_ref, <<"http://localhost:", port::binary>>}} = TestServer.start()

    Recordings.start_link([host, String.to_integer(port), @username, @password])

    []
  end

  test "list_stored" do
    resp = Recordings.list_stored()
    assert resp.json.path == "recordings" && resp.json.id == ["stored"]
  end

  test "get_stored" do
    resp = Recordings.get_stored("my-recording")
    assert resp.json.path == "recordings" && resp.json.id == ["stored", "my-recording"]
  end

  test "get_stored_file" do
    resp = Recordings.get_stored_file("my-recording")
    assert resp.json.path == "recordings" && resp.json.id == ["stored", "my-recording", "file"]
  end

  test "copy_stored" do
    resp = Recordings.copy_stored("my-recording", "new-name")

    assert resp.json.path == "recordings" && resp.json.id == ["stored", "my-recording", "copy"] &&
             resp.json.query_params.destinationRecordingName == "new-name"
  end

  test "delete_stored" do
    resp = Recordings.delete_stored("my-recording")
    assert resp.json.path == "recordings" && resp.json.id == ["stored", "my-recording"]
  end

  test "get_live" do
    resp = Recordings.get_live("my-recording")
    assert resp.json.path == "recordings" && resp.json.id == ["live", "my-recording"]
  end

  test "cancel_live" do
    resp = Recordings.cancel_live("my-recording")
    assert resp.json.path == "recordings" && resp.json.id == ["live", "my-recording"]
  end

  test "stop_live" do
    resp = Recordings.stop_live("my-recording")
    assert resp.json.path == "recordings" && resp.json.id == ["live", "my-recording", "stop"]
  end

  test "pause_live" do
    resp = Recordings.pause_live("my-recording")
    assert resp.json.path == "recordings" && resp.json.id == ["live", "my-recording", "pause"]
  end

  test "unpause_live" do
    resp = Recordings.unpause_live("my-recording")
    assert resp.json.path == "recordings" && resp.json.id == ["live", "my-recording", "pause"]
  end

  test "mute_live" do
    resp = Recordings.mute_live("my-recording")
    assert resp.json.path == "recordings" && resp.json.id == ["live", "my-recording", "mute"]
  end

  test "unmute_live" do
    resp = Recordings.unmute_live("my-recording")
    assert resp.json.path == "recordings" && resp.json.id == ["live", "my-recording", "mute"]
  end
end
