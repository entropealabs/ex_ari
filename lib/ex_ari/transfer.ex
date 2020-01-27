defmodule ARI.Transfer do
  @moduledoc """
  A Stasis application to handle transferring calls to phone numbers outside of our system.

  ## Example

        Channels.originate(UUID.uuid4(), %{
          endpoint: "PJSIP/+15555550101@ivr",
          app: "transfer",
          appArgs: state.channel,
          callerId: "Citybase, Inc",
          originator: state.channel,
          context: "ivr"
        })

  This would be initiated in an event handler for your current call. The `state.channel` should be the ID of the incoming call.

  This will create a [Bridge](https://wiki.asterisk.org/wiki/display/AST/Bridges) and dial `+15555550101` connecting the original call with the dialed number. This example assumes you have registered the `ARI.Transfer` Stasis application with the name `transfer` like this.

        {ARI.Stasis, [sup, %{name: "transfer", module: ARI.Transfer}, ws_host, un, pw]}

  """
  use GenServer

  require Logger

  alias ARI.HTTP.Bridges
  alias ARI.Stasis

  @behaviour Stasis

  @derive Jason.Encoder

  @type t :: %__MODULE__{}

  defstruct [
    :channel,
    :caller,
    :start_event,
    :incoming_channel
  ]

  def start_link([state]) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    bridge_id = UUID.uuid4()
    Bridges.create(bridge_id, bridge_id, ["mixing", "dtmf_events"])

    Bridges.add_channels(bridge_id, [state.channel, state.incoming_channel])
    {:ok, state}
  end

  def handle_info(event, state) do
    Logger.debug("Transfer Event: #{inspect(event)}")
    {:noreply, state}
  end

  @spec state(String.t(), String.t(), list(), map(), map()) :: Stasis.channel_state()
  def state(channel, caller, [incoming_channel], start_event, _app_state) do
    Logger.debug("Starting Transfer with state: #{channel} - #{caller} - #{incoming_channel}")

    %__MODULE__{
      channel: channel,
      caller: caller,
      start_event: start_event,
      incoming_channel: incoming_channel
    }
  end
end
