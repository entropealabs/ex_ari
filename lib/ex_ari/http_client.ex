defmodule ARI.HTTPClient do
  @moduledoc false
  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{}
    defstruct [:host, :port, :username, :password, requests: []]
  end

  defmodule Response do
    @moduledoc """
    Response returned from all REST calls
    """
    @type t :: %__MODULE__{}
    defstruct [:status, :error, :data, headers: [], data: "", json: %{}, completed: false]
  end

  defmacro __using__(path) do
    quote location: :keep do
      use GenServer
      require Logger

      @path unquote(path)

      def start_link([host, port, un, pw]) do
        GenServer.start_link(__MODULE__, {host, port, un, pw}, name: __MODULE__)
      end

      def init({host, port, un, pw}) do
        {:ok, %State{host: host, port: port, username: un, password: pw}}
      end

      def handle_info({:tcp, _p, data} = msg, state) do
        requests =
          state.requests
          |> Enum.map(fn {from, conn, res} = req ->
            case Mint.HTTP.stream(conn, msg) do
              :unknown ->
                req

              {:ok, c, responses} ->
                handle_responses(c, responses, req)

              {:error, _http, error, _} = er ->
                Logger.error("#{inspect(er)}")
                res = %Response{res | error: error, completed: true}
                GenServer.reply(from, res)
                {from, conn, res}
            end
          end)
          |> Enum.reject(fn {_, _, res} -> res.completed end)

        {:noreply, %State{state | requests: requests}}
      end

      defp handle_responses(conn, [{:status, _r, status_code} | t], {from, _c, res}) do
        handle_responses(conn, t, {from, conn, %Response{res | status: status_code}})
      end

      defp handle_responses(conn, [{:headers, _r, headers} | t], {from, _c, res}) do
        handle_responses(conn, t, {from, conn, %Response{res | headers: headers}})
      end

      defp handle_responses(conn, [{:data, _r, data} | t], {from, _c, res}) do
        handle_responses(conn, t, {from, conn, %Response{res | data: res.data <> data}})
      end

      defp handle_responses(conn, [{:error, _r, reason} | t], {from, _c, res}) do
        handle_responses(conn, t, {from, conn, %Response{res | error: reason}})
      end

      defp handle_responses(conn, [{:done, _r}], {from, _c, res} = req) do
        res = %Response{res | completed: true, json: handle_json(res.data)}
        debug("HTTP Response: #{inspect(res)}")
        rep = GenServer.reply(from, res)
        Mint.HTTP.close(conn)
        {from, conn, res}
      end

      defp handle_json(<<>>) do
        nil
      end

      defp handle_json(data) do
        Jason.decode!(data, keys: :atoms)
      end

      defp do_connect(host, port) do
        Mint.HTTP.connect(:http, host, port)
      end

      defp auth_header(un, pw) do
        credentials = "#{un}:#{pw}" |> Base.encode64()
        [{"Authorization", "Basic #{credentials}"}]
      end

      @spec request(String.t(), String.t(), GenServer.from(), State.t(), map() | String.t() | nil) ::
              State.t()
      def request(method, path, from, state, body \\ nil)

      def request(method, path, from, state, body) when is_map(body) do
        request(method, path, from, state, Jason.encode!(body))
      end

      def request(method, path, from, state, body) do
        {:ok, conn} = do_connect(state.host, state.port)
        headers = auth_header(state.username, state.password)
        headers = [{"Content-Type", "application/json;charset=utf-8"} | headers]
        path = "/ari#{@path}#{path}"
        debug("#{method} to #{path} with body #{body}")
        {:ok, conn, request_ref} = Mint.HTTP.request(conn, method, path, headers, body)
        %State{state | requests: [{from, conn, %Response{}} | state.requests]}
      end

      defp encode_params(%{} = params) do
        URI.encode_query(params)
      end

      defp debug(msg) do
        Logger.debug(fn -> "#{__MODULE__} - #{msg}" end)
      end
    end
  end
end
