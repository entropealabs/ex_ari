defmodule ARI.TestServer do
  @moduledoc false
  use Plug.Router

  alias Plug.Adapters.Cowboy

  require Logger

  plug(:match)
  plug(:dispatch)

  match _ do
    send_resp(conn, 200, "Hello from plug")
  end

  def start do
    ref = make_ref()
    port = get_port()
    url = "http://localhost:#{port}"

    case Cowboy.http(__MODULE__, [], dispatch: dispatch(), port: port, ref: ref) do
      {:ok, _} -> {:ok, {ref, url}}
      {:error, :eaddrinuse} -> start()
    end
  end

  def start(pid) do
    ref = make_ref()
    port = get_port()
    url = "http://localhost:#{port}/ws"

    case Cowboy.http(__MODULE__, [], dispatch: dispatch(pid), port: port, ref: ref) do
      {:ok, _} -> {:ok, {ref, url}}
      {:error, :eaddrinuse} -> start(pid)
    end
  end

  defp dispatch do
    [
      {:_,
       [
         {:_, Plug.Cowboy.Handler, {__MODULE__.TestHTTP, []}}
       ]}
    ]
  end

  defp dispatch(pid) do
    [
      {:_,
       [
         {"/ws", __MODULE__.TestSocket, [pid]}
       ]}
    ]
  end

  def receive_socket_pid do
    receive do
      pid when is_pid(pid) -> pid
    after
      500 -> raise "No Server Socket pid"
    end
  end

  def shutdown(ref) do
    Cowboy.shutdown(ref)
  end

  defp get_port do
    unless Process.whereis(__MODULE__), do: start_ports_agent()

    Agent.get_and_update(__MODULE__, fn port -> {port, port + 1} end)
  end

  defp start_ports_agent do
    Agent.start(fn -> Enum.random(50_000..63_000) end, name: __MODULE__)
  end

  defmodule TestHTTP do
    @moduledoc false
    use Plug.Router

    plug(Plug.Parsers,
      parsers: [:urlencoded, :json],
      pass: ["text/*", "application/*"],
      json_decoder: Jason
    )

    plug(:match)
    plug(:dispatch)

    defp get_creds([<<"Basic ", encoded::binary>>]) do
      encoded
      |> Base.decode64!()
      |> String.split(":")
    end

    get "/ari/:path/test_auth" do
      [un, pw] =
        conn
        |> get_req_header("authorization")
        |> get_creds()

      conn
      |> put_resp_content_type("application/json;charset=utf-8")
      |> send_resp(200, Jason.encode!(%{username: un, password: pw}))
    end

    get "/ari/:path/500" do
      conn
      |> put_resp_content_type("application/json;charset=utf-8")
      |> send_resp(500, Jason.encode!(%{error: "this is an error"}))
    end

    get "/ari/:path/*id" do
      query_params = conn.query_params

      conn
      |> put_resp_content_type("application/json;charset=utf-8")
      |> send_resp(200, Jason.encode!(%{path: path, id: id, query_params: query_params}))
    end

    post "/ari/:path/*id" do
      body_params = conn.body_params
      query_params = conn.query_params

      conn
      |> put_resp_content_type("application/json;charset=utf-8")
      |> send_resp(
        200,
        Jason.encode!(%{path: path, id: id, body_params: body_params, query_params: query_params})
      )
    end

    put "/ari/:path/*id" do
      body_params = conn.body_params
      query_params = conn.query_params

      conn
      |> put_resp_content_type("application/json;charset=utf-8")
      |> send_resp(
        200,
        Jason.encode!(%{path: path, id: id, body_params: body_params, query_params: query_params})
      )
    end

    delete "/ari/:path/*id" do
      conn
      |> put_resp_content_type("application/json;charset=utf-8")
      |> send_resp(200, Jason.encode!(%{path: path, id: id}))
    end
  end

  defmodule TestSocket do
    @moduledoc false
    @behaviour :cowboy_websocket

    def init(req, state) do
      {:cowboy_websocket, req, state}
    end

    def websocket_init([pid]) do
      server_pid = self()
      send(pid, server_pid)
      {:ok, %{test: pid}}
    end

    def websocket_handle({:text, message}, state) do
      {:reply, {:text, message}, state}
    end

    def websocket_info({:send_message, message}, state) do
      {:reply, {:text, Jason.encode!(message)}, state}
    end
  end
end
