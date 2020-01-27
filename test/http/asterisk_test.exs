defmodule ARI.HTTP.AsteriskTest do
  use ExUnit.Case, async: true

  require Logger

  alias ARI.HTTP.Asterisk
  alias ARI.TestServer

  @username "username1"
  @password "password2"

  setup_all do
    host = "localhost"
    {:ok, {_server_ref, <<"http://localhost:", port::binary>>}} = TestServer.start()

    Asterisk.start_link([host, String.to_integer(port), @username, @password])

    []
  end

  test "info" do
    resp = Asterisk.info()
    assert resp.json.path == "asterisk" && resp.json.id == ["info"]
  end

  test "get_config" do
    resp = Asterisk.get_config("pjsip", "endpoint", "12345")

    assert resp.json.path == "asterisk" &&
             resp.json.id == ["config", "dynamic", "pjsip", "endpoint", "12345"]
  end

  test "put_config" do
    resp = Asterisk.put_config("pjsip", "endpoint", "12345", %{key: "value"})

    assert resp.json.path == "asterisk" &&
             resp.json.id == ["config", "dynamic", "pjsip", "endpoint", "12345"] &&
             resp.json.body_params.key == "value"
  end

  test "delete_config" do
    resp = Asterisk.delete_config("pjsip", "endpoint", "12345")

    assert resp.json.path == "asterisk" &&
             resp.json.id == ["config", "dynamic", "pjsip", "endpoint", "12345"]
  end

  test "get_logging" do
    resp = Asterisk.get_logging()

    assert resp.json.path == "asterisk" &&
             resp.json.id == ["logging"]
  end

  test "add_logging" do
    resp = Asterisk.add_logging("1234556.1212")

    assert resp.json.path == "asterisk" &&
             resp.json.id == ["logging", "1234556.1212"]
  end

  test "rotate_logging" do
    resp = Asterisk.rotate_logging("1234556.1212")

    assert resp.json.path == "asterisk" &&
             resp.json.id == ["logging", "1234556.1212", "rotate"]
  end

  test "delete_logging" do
    resp = Asterisk.delete_logging("1234556.1212")

    assert resp.json.path == "asterisk" &&
             resp.json.id == ["logging", "1234556.1212"]
  end

  test "get_modules" do
    resp = Asterisk.get_modules()

    assert resp.json.path == "asterisk" &&
             resp.json.id == ["modules"]
  end

  test "get_module" do
    resp = Asterisk.get_module("pjsip")

    assert resp.json.path == "asterisk" &&
             resp.json.id == ["modules", "pjsip"]
  end

  test "load_module" do
    resp = Asterisk.load_module("pjsip")

    assert resp.json.path == "asterisk" &&
             resp.json.id == ["modules", "pjsip"]
  end

  test "reload_module" do
    resp = Asterisk.reload_module("pjsip")

    assert resp.json.path == "asterisk" &&
             resp.json.id == ["modules", "pjsip"]
  end

  test "unload_module" do
    resp = Asterisk.unload_module("pjsip")

    assert resp.json.path == "asterisk" &&
             resp.json.id == ["modules", "pjsip"]
  end

  test "get_variable" do
    resp = Asterisk.get_variable("test")

    assert resp.json.path == "asterisk" &&
             resp.json.id == ["variable"] && resp.json.query_params.variable == "test"
  end

  test "set_variable" do
    resp = Asterisk.set_variable("key", "test")

    assert resp.json.path == "asterisk" &&
             resp.json.id == ["variable"] && resp.json.query_params.variable == "key" &&
             resp.json.query_params.value == "test"
  end
end
