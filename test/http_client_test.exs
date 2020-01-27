defmodule ARI.HTTPClientTest do
  use ExUnit.Case, async: true

  require Logger

  alias ARI.{HTTPClient, TestServer}

  @username "username1"
  @password "password2"

  defmodule TestClient do
    @moduledoc false
    use HTTPClient, "/test"

    def get(id, args) do
      GenServer.call(__MODULE__, {:get, id, args})
    end

    def post(id, args) do
      GenServer.call(__MODULE__, {:post, id, args})
    end

    def put(id, args) do
      GenServer.call(__MODULE__, {:put, id, args})
    end

    def delete(id, args) do
      GenServer.call(__MODULE__, {:delete, id, args})
    end

    def handle_call({:get, id, args}, from, state) do
      {:noreply, request("GET", "/#{id}?#{encode_params(args)}", from, state)}
    end

    def handle_call({:post, id, args}, from, state) do
      {:noreply, request("POST", "/#{id}", from, state, args)}
    end

    def handle_call({:put, id, args}, from, state) do
      {:noreply, request("POST", "/#{id}", from, state, args)}
    end

    def handle_call({:delete, id, args}, from, state) do
      {:noreply, request("DELETE", "/#{id}?#{encode_params(args)}", from, state)}
    end
  end

  setup_all do
    host = "localhost"
    {:ok, {_server_ref, <<"http://localhost:", port::binary>>}} = TestServer.start()

    TestClient.start_link([host, String.to_integer(port), @username, @password])

    []
  end

  test "correct path is sent to server" do
    id = "123456"
    resp = TestClient.get(id, %{key: "value"})

    assert resp.json.path == "test" && resp.json.id == [id]
  end

  test "query params are correctly encoded" do
    id = "123456"
    resp = TestClient.get(id, %{key: "value test"})

    assert resp.json.query_params.key == "value test"
  end

  test "basic auth is encoded properly" do
    resp = TestClient.get("test_auth", %{})
    assert resp.json.username == @username && resp.json.password == @password
  end

  test "post body correctly encoded" do
    resp = TestClient.post("test", %{key: "value", another_key: "not a value"})
    assert resp.json.body_params.another_key == "not a value"
  end

  test "500 is captured correctly in response" do
    resp = TestClient.get("500", %{})
    assert resp.status == 500
  end
end
