defmodule ARI.HTTP.EndpointsTest do
  use ExUnit.Case, async: true

  require Logger

  alias ARI.HTTP.Endpoints
  alias ARI.TestServer

  @username "username1"
  @password "password2"

  setup_all do
    host = "localhost"
    {:ok, {_server_ref, <<"http://localhost:", port::binary>>}} = TestServer.start()

    Endpoints.start_link([host, String.to_integer(port), @username, @password])

    []
  end

  test "list" do
    resp = Endpoints.list()
    assert resp.json.path == "endpoints" && resp.json.id == []
  end

  test "list_by_tech" do
    resp = Endpoints.list_by_tech("pjsip")
    assert resp.json.path == "endpoints" && resp.json.id == ["pjsip"]
  end

  test "get" do
    resp = Endpoints.get("pjsip", "my-endpoint")

    assert resp.json.path == "endpoints" &&
             resp.json.id == ["pjsip", "my-endpoint"]
  end

  test "send_message" do
    resp =
      Endpoints.send_message("+15555551212", "+15555552222", "this is a test message", %{
        variables: %{}
      })

    assert resp.json.path == "endpoints" &&
             resp.json.id == ["sendMessage"] &&
             resp.json.query_params.to == "+15555551212" &&
             resp.json.query_params.from == "+15555552222" &&
             resp.json.query_params.body == "this is a test message" &&
             resp.json.body_params.variables == %{}
  end

  test "send_message_to_endpoint" do
    resp =
      Endpoints.send_message_to_endpoint(
        "pjsip",
        "my-endpoint",
        "+15555552222",
        "this is a test message",
        %{
          variables: %{}
        }
      )

    assert resp.json.path == "endpoints" &&
             resp.json.id == ["pjsip", "my-endpoint", "sendMessage"] &&
             resp.json.query_params.from == "+15555552222" &&
             resp.json.query_params.body == "this is a test message" &&
             resp.json.body_params.variables == %{}
  end
end
