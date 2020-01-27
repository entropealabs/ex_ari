defmodule ARI.RecordCall do
  @moduledoc """
  A Stasis application to handle recording phone calls. This uses the `ARI.HTTP.Channels.snoop/6` functionality of Asterisk to record the call.

  ## Example

      Channels.snoop(
        state.channel,
        UUID.uuid4(),
        "record_call",
        "in",
        "none",
        "originating_app_name,state.channel"
      )

  This would be initiated in an event handler for your current call. The `state.channel` should be the ID of the incoming call.

  The example above would only record the incoming audio, you could record incoming and outgoing audio by using "both" instead of "in".

  This assumes you registered the Stasis application under the name "record_call", like so.

        {ARI.Stasis, [sup, %{name: "record_call", module: ARI.RecordCall}, ws_host, un, pw]}

  This application will by default stop recording after 2 seconds of silence. Once recording is finished it pushes an event to the originating channel that looks like this.

        {:ari, %{type: "CommandCaptured", recording: "recording-id"}}

  By default the wav file will be recorded in the Asterisk spool directory, you can override this with Asterisk settings.
  """
  use GenServer

  require Logger

  alias ARI.HTTP.{Channels, Events}
  alias ARI.Stasis

  @behaviour Stasis

  @derive Jason.Encoder

  @type t :: %__MODULE__{}

  defstruct [
    :channel,
    :incoming_channel,
    :caller,
    :start_event,
    :max_duration,
    :max_silence,
    :terminate_on,
    :app
  ]

  def start_link([state]) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    Channels.record(
      state.channel,
      state.channel,
      "wav",
      state.max_duration,
      state.max_silence,
      "overwrite",
      "no",
      state.terminate_on
    )

    {:ok, state}
  end

  def handle_info({:ari, %{type: "RecordingFinished"}}, state) do
    Events.create("CommandCaptured", state.app, ["channel:#{state.incoming_channel}"], %{
      variables: %{recording: state.channel}
    })

    Channels.hangup(state.channel)

    {:noreply, state}
  end

  def handle_info(event, state) do
    Logger.debug("Snoop got event: #{inspect(event)}")
    {:noreply, state}
  end

  @spec state(String.t(), String.t(), list(), map(), map()) :: Stasis.channel_state()
  def state(
        channel,
        caller,
        [app, incoming_channel, max_duration, max_silence, terminate_on],
        start_event,
        _app_state
      ) do
    Logger.debug("Snooping Channel: #{app}/#{incoming_channel}")

    %__MODULE__{
      channel: channel,
      caller: caller,
      start_event: start_event,
      incoming_channel: incoming_channel,
      max_silence: max_silence,
      max_duration: max_duration,
      terminate_on: terminate_on,
      app: app
    }
  end
end
