defmodule ARI.HTTP.BridgesTest do
  use ExUnit.Case, async: true

  require Logger

  alias ARI.HTTP.Bridges
  alias ARI.TestServer

  @username "username1"
  @password "password2"

  setup_all do
    host = "localhost"
    {:ok, {_server_ref, <<"http://localhost:", port::binary>>}} = TestServer.start()

    Bridges.start_link([host, String.to_integer(port), @username, @password])

    []
  end

  test "list" do
    resp = Bridges.list()
    assert resp.json.path == "bridges" && resp.json.id == []
  end

  test "get" do
    resp = Bridges.get("1234567")

    assert resp.json.path == "bridges" &&
             resp.json.id == ["1234567"]
  end

  test "create" do
    resp = Bridges.create("1234567", "test_bridge", ["mixed", "test"])

    assert resp.json.path == "bridges" &&
             resp.json.id == [] &&
             resp.json.query_params.type == "mixed,test" &&
             resp.json.query_params.bridgeId == "1234567" &&
             resp.json.query_params.name == "test_bridge"
  end

  test "delete" do
    resp = Bridges.delete("1234567")

    assert resp.json.path == "bridges" &&
             resp.json.id == ["1234567"]
  end

  test "update" do
    resp = Bridges.update("1234567", "test_bridge", ["mixed", "test"])

    assert resp.json.path == "bridges" &&
             resp.json.id == ["1234567"] &&
             resp.json.query_params.type == "mixed,test" &&
             resp.json.query_params.name == "test_bridge"
  end

  test "add_channels" do
    resp = Bridges.add_channels("1234567", ["1234.2323", "9876.21"], "participant")

    assert resp.json.path == "bridges" &&
             resp.json.id == ["1234567", "addChannel"] &&
             resp.json.query_params.channel == "1234.2323,9876.21" &&
             resp.json.query_params.role == "participant"
  end

  test "remove_channels" do
    resp = Bridges.remove_channels("1234567", ["1234.2323", "9876.21"])

    assert resp.json.path == "bridges" &&
             resp.json.id == ["1234567", "removeChannel"] &&
             resp.json.query_params.channel == "1234.2323,9876.21"
  end

  test "set_video_source" do
    resp = Bridges.set_video_source("1234567", "1234.2323")

    assert resp.json.path == "bridges" &&
             resp.json.id == ["1234567", "videoSource", "1234.2323"]
  end

  test "clear_video_source" do
    resp = Bridges.clear_video_source("1234567")

    assert resp.json.path == "bridges" &&
             resp.json.id == ["1234567", "videoSource"]
  end

  test "start_moh" do
    resp = Bridges.start_moh("1234567", "1234.2323")

    assert resp.json.path == "bridges" &&
             resp.json.id == ["1234567", "moh"] &&
             resp.json.query_params.mohClass == "1234.2323"
  end

  test "stop_moh" do
    resp = Bridges.stop_moh("1234567")

    assert resp.json.path == "bridges" &&
             resp.json.id == ["1234567", "moh"]
  end

  test "play" do
    resp = Bridges.play("1234567", "123123123", "sound:welcome", "en", 0, 100)

    assert resp.json.path == "bridges" &&
             resp.json.id == ["1234567", "play", "123123123"] &&
             resp.json.query_params.media == "sound:welcome" &&
             resp.json.query_params.lang == "en" &&
             resp.json.query_params.offsetms == "0" &&
             resp.json.query_params.skipms == "100"
  end

  test "record" do
    resp = Bridges.record("1234567", "test", "wav", 100, 2, "fail", "yes", "2")

    assert resp.json.path == "bridges" &&
             resp.json.id == ["1234567", "record"] &&
             resp.json.query_params.name == "test" &&
             resp.json.query_params.format == "wav" &&
             resp.json.query_params.maxDurationSeconds == "100" &&
             resp.json.query_params.maxSilenceSeconds == "2" &&
             resp.json.query_params.ifExists == "fail" &&
             resp.json.query_params.beep == "yes" &&
             resp.json.query_params.terminateOn == "2"

    # Test default values
    default_vals = Bridges.record("1234567", "test", "wav")
    assert default_vals.json.query_params.maxDurationSeconds == "0"
    default_vals1 = Bridges.record("1234567", "test", "wav", 0)
    assert default_vals1.json.query_params.maxSilenceSeconds == "0"
    default_vals2 = Bridges.record("1234567", "test", "wav", 0, 0)
    assert default_vals2.json.query_params.ifExists == "fail"
    default_vals3 = Bridges.record("1234567", "test", "wav", 0, 0, "fail")
    assert default_vals3.json.query_params.beep == "no"
    default_vals4 = Bridges.record("1234567", "test", "wav", 0, 0, "fail", "yes")
    assert default_vals4.json.query_params.terminateOn == "#"
  end
end
