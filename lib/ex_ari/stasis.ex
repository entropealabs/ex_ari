defmodule ARI.Stasis do
  @moduledoc """
  The `ARI.Stasis` module is used to register a [Stasis](https://wiki.asterisk.org/wiki/pages/viewpage.action?pageId=29395573#AsteriskRESTInterface(ARI)-WhatisStasis?) application with the Asterisk server. It connects to the Asterisk server using a websocket.

  The host, username and password are configured in the Asterisk configuration file [ari.conf](https://wiki.asterisk.org/wiki/display/AST/Asterisk+Configuration+for+ARI). The name that is registered is provided in the `t:ARI.Stasis.app_config/0` as `name`.

  Once registered it receives all events for all [channels](https://wiki.asterisk.org/wiki/display/AST/Channels) associated with a Stasis application. Here's an example application, you can see the Stasis app configured for the built-in `ARI.Router` application as well as a custom application, in the list of children.

  ### Example
      defmodule ExARIExample.Application do
          use Application
          alias ARI.{ChannelRegistrar, Configurator, HTTP, Stasis}

          def start(_, _) do
            un = System.get_env("ASTERISK_USERNAME")
            pw = System.get_env("ASTERISK_PASSWORD")
            ws_host = System.get_env("ASTERISK_WS_HOST")
            rest_host = System.get_env("ASTERISK_REST_HOST")
            rest_port = System.get_env("ASTERISK_REST_PORT") |> String.to_integer()
            name = System.get_env("ASTERISK_NAME")
            transport = System.get_env("ASTERISK_TRANSPORT")
            context = System.get_env("ASTERISK_CONTEXT")
            channel_supervisor = ExARIExample.ChannelSupervisor
            config_module = ExARIExample.Config
            client_config = %{name: "ex_ari", module: ExARIExample.Client}
            router_config = %{
              name: "router",
              module: ARI.Router,
              extensions: %{
                "ex_ari" => "ex_ari",
                "+15555550101" => "ex_ari"
              }
            }

            children = [
              ChannelRegistrar,
              {DynamicSupervisor, strategy: :one_for_one, name: channel_supervisor},
              {HTTP.Asterisk, [rest_host, rest_port, un, pw]},
              {HTTP.Channels, [rest_host, rest_port, un, pw]},
              {HTTP.Playbacks, [rest_host, rest_port, un, pw]},
              {Stasis, [channel_supervisor, client_config, ws_host, un, pw]},
              {Stasis, [channel_supervisor, router_config, ws_host, un, pw]},
              {Configurator, [name, transport, context, config_module]},
            ]

            opts = [strategy: :one_for_one, name: ExARIExample.Supervisor]
            Supervisor.start_link(children, opts)
          end
        end

  Using this example, all calls to `+15555550101` will have a `ExARIExample.Client` process spawned and subsequent call events will be passed to the indivdual process. More explicitly, each call has a unique process spawned that is supervised by the DynamicSupervisor passed to `ARI.Stasis`.

  For the full example check out the [ex_ari_example application](https://github.com/citybaseinc/ex_ari_example), which will get you up and running with making calls on your local machine.

  There are two very important events that `ARI.Stasis` receives that drive an `ex_ari` application `StasisStart` and `StasisEnd`.

  ## StasisStart

  When a [StasisStart](https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+REST+Data+Models#Asterisk16RESTDataModels-StasisStart) event is received it will spawn a new process under the supervisor provided as the `channel_supervisor`, this needs to be a `DynamicSupervisor`, to the `ARI.Stasis.start_link/5` function. The process that is spawned is provided in the `t:ARI.Stasis.app_config/0` as the `module`.

  Before actually spawning the app process the WebSocket process will call the function `c:state/5` on the app module with the id of the incoming channel, the caller id (a string of the number that is calling), a list of any arguments passed to the application (an empty list for standard stasis applications), the initial StasisStart event and the `t:ARI.Stasis.app_config/0` that was passed to the `ARI.Stasis` module on startup. The `ARI.Router` application provided with `ex_ari` makes special use of the `t:ARI.Stasis.app_config/0` by pulling extensions from the config to route incoming calls to their respective applications. The `c:state/5` behaviour function is expected to return `t:ARI.Stasis.channel_state/0` a struct or map containing at a minimum `:channel`, `:caller` and `:start_event` keys populated with the data passed to the `c:state/5` function. The rest of the keys can be whatever is needed by your application. This data is then passed to the `GenServer.start_link/2` function of your app module in the form `[state]` and should be used as your processes state for the lifetime of the process.

  To map channel ids to pids there is an Agent process that maintains the mappings, `ARI.ChannelRegistrar`. This is provided by the `ex_ari` library, but needs to be explicitly started by your application.

  ## StasisEnd

  Upon receiving a [StasisEnd](https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+REST+Data+Models#Asterisk16RESTDataModels-StasisEnd) event the `ARI.Stasis` module will begin tearing down the process associated with the channel id. It kills the process by calling `DynamicSupervisor.terminate_child/3` and deregistering the pid from the `ARI.ChannelRegistrar` Agent process.

  ## Other Events

  The `ARI.Stasis` process does its best to extract out the channel id from several different types of events in order to route the event to the correct process. All events are sent using `send/2` in the form of `{:ari, event}` where event is the JSON event deserialized with atom keys. Events that are not routable are handled with a `Logger.warn/1` message.
  """
  use WebSockex
  alias ARI.{ChannelRegistrar, Additions}
  require Logger

  @type app_config :: %{
          optional(:extensions) => map(),
          name: String.t(),
          module: module()
        }

  @type channel_state :: %{
          optional(atom()) => any(),
          channel: String.t(),
          caller: String.t(),
          start_event: map()
        }

  @doc """
  Called when an incoming call is received.
  Arguments are `Channel ID`, `Caller ID`, `Args`, `StasisStart Event` and `App Config`
  """
  @callback state(String.t(), String.t(), list(), map(), map()) :: channel_state()

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{}

    @derive {Jason.Encoder, only: [:connected, :url, :status, :type]}
    defstruct [
      :connected,
      :url,
      :status,
      :channel_supervisor,
      :listener,
      reconnection_attempts: 0,
      app: %{}
    ]
  end

  def child_spec([_, app_config, _, _, _] = opts) do
    %{
      id: :"#{app_config.name}",
      start: {__MODULE__, :start_link, opts},
      restart: :transient
    }
  end

  @spec start_link(module(), app_config(), String.t(), String.t(), String.t()) ::
          {:ok, pid} | {:error, term}
  def start_link(channel_supervisor, app_config, host, un, pw) do
    subscriptions =
      case app_config[:subscriptions] do
        :all -> "&subscribeAll=true"
        true -> "&subscribeAll=true"
        _ -> ""
      end

    url = "#{host}?api_key=#{un}:#{pw}&app=#{app_config.name}" <> subscriptions
    uri = URI.parse(url)
    conn = WebSockex.Conn.new(uri)

    debug("Connecting: #{inspect(uri, pretty: true)}")

    WebSockex.start_link(
      conn,
      __MODULE__,
      %State{url: url, app: app_config, channel_supervisor: channel_supervisor},
      handle_initial_conn_failure: true,
      async: true,
      name: :"#{__MODULE__}.#{String.capitalize(app_config.name)}"
    )
  end

  @impl WebSockex
  def handle_connect(_conn, state) do
    state = %State{
      state
      | connected: true,
        reconnection_attempts: 0
    }

    debug("Connected: #{inspect(state, pretty: true)}")

    state
    |> Additions.check_for_event_listener()
    |> case do
      {:ok, state} -> {:ok, state}
      _ -> {:ok, state}
    end
  end

  @impl WebSockex
  def handle_disconnect(status, state) do
    state = %State{
      state
      | connected: false,
        status: status,
        reconnection_attempts: state.reconnection_attempts + 1
    }

    debug("Disconnected: #{inspect(state, pretty: true)}")

    case state.reconnection_attempts do
      ra when ra < 10 ->
        timeout = 1000 * ra
        debug("Sleeping for #{timeout}")
        Process.sleep(timeout)

        {:reconnect, state}

      ra when ra >= 10 ->
        {:ok, state}

      _ ->
        {:ok, state}
    end
  end

  @impl WebSockex
  def handle_info({:DOWN, _ref, :process, object, reason}, state) do
    Logger.error(
      "Channel process #{inspect(object, pretty: true)} is down because #{
        inspect(reason, pretty: true)
      }"
    )

    {:ok, state}
  end

  def handle_info({:listener, pid}, state) when is_pid(pid) do
    {:ok, %{state | listener: pid}}
  end

  @impl WebSockex
  def handle_frame({:text, payload}, state) do
    {:ok, state} =
      payload
      |> Jason.decode!(keys: :atoms)
      |> handle_payload(state)

    {:ok, state}
  end

  defp handle_payload(
         %{type: "StasisStart", args: args, channel: %{id: id, caller: %{number: number}}} =
           event,
         state
       ) do
    debug("Got StasisStart event: #{inspect(event, pretty: true)}")
    call_state = get_state(state, id, number, args, event, state.app)

    {:ok, pid} =
      DynamicSupervisor.start_child(state.channel_supervisor, {
        state.app.module,
        [call_state]
      })

    Process.monitor(pid)
    debug("Started #{state.app.module} for channel #{id}")
    ChannelRegistrar.put_channel(id, pid)
    {:ok, state}
  end

  defp handle_payload(%{application: "router", type: "StasisEnd", channel: %{id: id}}, state) do
    debug("Received Router Stasis End")
    handle_stasis_end(id, false, state)
  end

  defp handle_payload(%{type: "StasisEnd", channel: %{id: id}}, state) do
    debug("Received App Stasis End")
    handle_stasis_end(id, true, state)
  end

  defp handle_payload(%{playback: %{target_uri: <<"channel:", id::binary>>}} = payload, state) do
    debug("Received Playback Event #{inspect(payload, pretty: true)}")
    send(state.app.listener, {:event, payload})

    id
    |> ChannelRegistrar.get_channel()
    |> do_send({:ari, payload})

    {:ok, state}
  end

  defp handle_payload(%{recording: %{target_uri: <<"channel:", id::binary>>}} = payload, state) do
    debug("Received Recording Event #{inspect(payload, pretty: true)}")
    send(state.app.listener, {:event, payload})

    id
    |> ChannelRegistrar.get_channel()
    |> do_send({:ari, payload})

    {:ok, state}
  end

  defp handle_payload(%{channel: %{id: id}} = payload, state) do
    debug("Received Event: #{inspect(payload, pretty: true)}")
    send(state.app.listener, {:event, payload})

    id
    |> ChannelRegistrar.get_channel()
    |> do_send({:ari, payload})

    {:ok, state}
  end

  defp handle_payload(payload, %{app: %{listener: listener}} = state) when is_pid(listener) do
    debug("Pushing Unhandled payload to Listener: : #{inspect(payload, pretty: true)}")
    send(listener, {:event, payload})
    {:ok, state}
  rescue
    err ->
      err |> inspect() |> Logger.error()
      {:ok, state}
  end

  defp handle_payload(payload, state) do
    debug(
      "Pushing Unhandled payload to Listener: : #{inspect(payload, pretty: true)} State: #{
        inspect(state, pretty: true)
      }"
    )

    send(state.app.listener, {:event, payload})

    {:ok, state}
  end

  @spec get_state(State.t(), String.t(), String.t(), list(), map(), map()) :: channel_state()
  defp get_state(state, id, number, args, start_event, app_state) do
    state.app.module.state(id, number, args, start_event, app_state)
  end

  defp handle_stasis_end(id, deregister, state) do
    case ChannelRegistrar.get_channel(id) do
      nil ->
        :noop

      pid ->
        if deregister do
          Logger.debug("Removed Channel: #{id}")
          ChannelRegistrar.delete_channel(id)
        end

        DynamicSupervisor.terminate_child(
          state.channel_supervisor,
          pid
        )
    end

    {:ok, state}
  end

  defp do_send(nil, _msg), do: :noop

  defp do_send(pid, msg) when is_pid(pid) do
    send(pid, msg)
  end

  defp do_send(_pid, _msg), do: :noop

  defp debug(msg) do
    Logger.debug(fn -> "#{__MODULE__} - #{msg}" end)
  end
end
