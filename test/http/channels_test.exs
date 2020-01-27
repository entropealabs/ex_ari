defmodule ARI.HTTP.ChannelsTest do
  use ExUnit.Case, async: true

  require Logger

  alias ARI.HTTP.Channels
  alias ARI.TestServer

  @username "username1"
  @password "password2"

  setup_all do
    host = "localhost"
    {:ok, {_server_ref, <<"http://localhost:", port::binary>>}} = TestServer.start()

    Channels.start_link([host, String.to_integer(port), @username, @password])

    []
  end

  test "list" do
    resp = Channels.list()
    assert resp.json.path == "channels" && resp.json.id == []
  end

  test "get" do
    resp = Channels.get("1234567")

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567"]
  end

  test "originate/2" do
    resp =
      Channels.originate("1234567", %{
        endpoint: "PJSIP/+15555551010@test_endpoint",
        app: "test_app"
      })

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567"] &&
             resp.json.body_params.endpoint == "PJSIP/+15555551010@test_endpoint" &&
             resp.json.body_params.app == "test_app"
  end

  test "originate/1" do
    resp =
      Channels.originate(%{
        endpoint: "PJSIP/+15555551010@test_endpoint",
        app: "test_app"
      })

    assert resp.json.path == "channels" &&
             resp.json.body_params.endpoint == "PJSIP/+15555551010@test_endpoint" &&
             resp.json.body_params.app == "test_app"
  end

  test "create" do
    resp =
      Channels.create(%{
        endpoint: "PJSIP/+15555551010@test_endpoint",
        app: "test_app"
      })

    assert resp.json.path == "channels" &&
             resp.json.id == ["create"] &&
             resp.json.query_params.endpoint == "PJSIP/+15555551010@test_endpoint" &&
             resp.json.query_params.app == "test_app"
  end

  test "hangup" do
    resp = Channels.hangup("1234567")

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567"]
  end

  test "continue_in_dialplan" do
    resp = Channels.continue_in_dialplan("1234567", "test", "test", 1, "test")

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567", "continue"] &&
             resp.json.query_params.context == "test" &&
             resp.json.query_params.extension == "test" &&
             resp.json.query_params.priority == "1" &&
             resp.json.query_params.label == "test"
  end

  test "redirect" do
    resp = Channels.redirect("1234567", "PJSIP/+15555551010@test_endpoint")

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567", "redirect"] &&
             resp.json.query_params.endpoint == "PJSIP/+15555551010@test_endpoint"
  end

  test "answer" do
    resp = Channels.answer("1234567")

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567", "answer"]
  end

  test "ring" do
    resp = Channels.ring("1234567")

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567", "ring"]
  end

  test "ring_stop" do
    resp = Channels.ring_stop("1234567")

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567", "ring"]
  end

  test "send_dtmf" do
    resp = Channels.send_dtmf("1234567", "1", 0, 0, 250, 0)

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567", "dtmf"] &&
             resp.json.query_params.dtmf == "1" &&
             resp.json.query_params.before == "0" &&
             resp.json.query_params.between == "0" &&
             resp.json.query_params.duration == "250" &&
             resp.json.query_params.after == "0"
  end

  test "mute" do
    resp = Channels.mute("1234567")

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567", "mute"]
  end

  test "unmute" do
    resp = Channels.unmute("1234567")

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567", "mute"]
  end

  test "hold" do
    resp = Channels.hold("1234567")

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567", "hold"]
  end

  test "unhold" do
    resp = Channels.unhold("1234567")

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567", "hold"]
  end

  test "start_silence" do
    resp = Channels.start_silence("1234567")

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567", "silence"]
  end

  test "move" do
    resp = Channels.move("1234567", "test")

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567", "move"]
  end

  test "stop_silence" do
    resp = Channels.stop_silence("1234567")

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567", "silence"]
  end

  test "start_moh" do
    resp = Channels.start_moh("1234567", "1234.2323")

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567", "moh"] &&
             resp.json.query_params.mohClass == "1234.2323"
  end

  test "stop_moh" do
    resp = Channels.stop_moh("1234567")

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567", "moh"]
  end

  test "play" do
    resp = Channels.play("1234567", "123123123", "sound:welcome", "en", 0, 100)

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567", "play", "123123123"] &&
             resp.json.query_params.media == "sound:welcome" &&
             resp.json.query_params.lang == "en" &&
             resp.json.query_params.offsetms == "0" &&
             resp.json.query_params.skipms == "100"
  end

  test "record" do
    resp = Channels.record("1234567", "test", "wav", 100, 2, "fail", "yes", "#")

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567", "record"] &&
             resp.json.query_params.name == "test" &&
             resp.json.query_params.format == "wav" &&
             resp.json.query_params.maxDurationSeconds == "100" &&
             resp.json.query_params.maxSilenceSeconds == "2" &&
             resp.json.query_params.ifExists == "fail" &&
             resp.json.query_params.beep == "yes" &&
             resp.json.query_params.terminateOn == "#"

    # Test default values
    default_vals = Channels.record("1234567", "test", "wav")
    assert default_vals.json.query_params.maxDurationSeconds == "0"
    default_vals1 = Channels.record("1234567", "test", "wav", 0)
    assert default_vals1.json.query_params.maxSilenceSeconds == "0"
    default_vals2 = Channels.record("1234567", "test", "wav", 0, 0)
    assert default_vals2.json.query_params.ifExists == "fail"
    default_vals3 = Channels.record("1234567", "test", "wav", 0, 0, "fail")
    assert default_vals3.json.query_params.beep == "no"
    default_vals4 = Channels.record("1234567", "test", "wav", 0, 0, "fail", "yes")
    assert default_vals4.json.query_params.terminateOn == "#"
  end

  test "set_var" do
    resp = Channels.set_var("1234567", "key", "value")

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567", "variable"] &&
             resp.json.query_params.variable == "key" &&
             resp.json.query_params.value == "value"
  end

  test "get_var" do
    resp = Channels.get_var("1234567", "key")

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567", "variable"] &&
             resp.json.query_params.variable == "key"
  end

  test "snoop" do
    resp = Channels.snoop("1234567", "9876554321", "test_app", "both", "both", "1234")

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567", "snoop", "9876554321"] &&
             resp.json.query_params.spy == "both" &&
             resp.json.query_params.whisper == "both" &&
             resp.json.query_params.app == "test_app" &&
             resp.json.query_params.appArgs == "1234"
  end

  test "dial" do
    resp = Channels.dial("1234567", "Test Caller", 5000)

    assert resp.json.path == "channels" &&
             resp.json.id == ["1234567", "dial"] &&
             resp.json.query_params.caller == "Test Caller" &&
             resp.json.query_params.timeout == "5000"
  end
end
