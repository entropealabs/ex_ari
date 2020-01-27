defmodule ARI.Router do
  @moduledoc """
  A special Stasis application to handle dynamically routing incoming calls to their respective Stasis application. 

  The `t:ARI.Stasis.app_config/0` passed to the Router Stasis on startup must contain an `extensions` key with a map of extensions as strings to the name of the stasis application eg; 
      router_config = %{
        name: "router",
        module: ARI.Router,
        extensions: %{
          "+15555550101" => "my_registered_stasis_app"
        }
      }

  The use of this Stasis application isn't required, but it does allow you to manage all call routing from within your Elixir application, rather than having to update your Asterisk extensions. The example application at [https://github.com/citybaseinc/ex_ari_example](https://github.com/citybaseinc/ex_ari_example) defaults to using the router. The Asterisk config for extensions looks like this.

  ### extensions.conf
      [ex_ari]

      exten => _.,1,Answer()
      same => n,Stasis(router)
      same => n,Hangup()

  This is saying match all incoming calls `_.` and pass them to the `router` Stasis application.

  Assuming we use the config map above we would register our `ARI.Router` Stasis application like so.
      {ARI.Stasis, [sup, router_config, ws_host, un, pw]}

  And we have a Stasis application registered

      {ARI.Stasis, [sup, %{name: "my_registered_stasis_app", module: MyApp}, ws_host, un, pw]}

  All incoming calls to +15555550101 would be routed to our `MyApp` module. It's worth noting that a new process is spawned for each incoming call.

  If for some reason you don't want to use `ARI.Router` you can achieve the same thing with the Asterisk `extensions.conf` file

      [ex_ari]

      exten => +15555550101,1,Answer()
      same => n,Stasis(my_registered_stasis_app)
      same => n,Hangup()
  """
  use GenServer

  require Logger

  alias ARI.HTTP.Channels
  alias ARI.Stasis

  @behaviour Stasis

  @derive Jason.Encoder

  @type t :: %__MODULE__{}

  defstruct [
    :channel,
    :caller,
    :start_event,
    :extensions
  ]

  def start_link([state]) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    extensions = state.extensions
    incoming_extension = get_in(state.start_event, [:channel, :dialplan, :exten])
    Logger.debug("Incoming call with extension #{incoming_extension}")

    case Map.get(extensions, incoming_extension) do
      nil ->
        :noop

      app ->
        Logger.debug("Moving: #{state.channel} to app #{app}")
        Channels.move(state.channel, app)
    end

    {:ok, state}
  end

  def handle_info(event, state) do
    Logger.warn(
      "#{__MODULE__}: unhandled info event #{inspect(event)} with state #{inspect(state)}"
    )

    {:noreply, state}
  end

  @spec state(String.t(), String.t(), list(), map(), map()) :: Stasis.channel_state()
  def state(channel, caller, [], event, app_state) do
    Logger.debug("Starting router move: #{channel} - #{caller} - #{inspect(event)}")

    %__MODULE__{
      channel: channel,
      caller: caller,
      start_event: event,
      extensions: app_state.extensions
    }
  end
end
