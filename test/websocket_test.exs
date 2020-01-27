defmodule ARI.WebSocketTest do
  use ExUnit.Case, async: true

  require Logger

  alias ARI.{ChannelRegistrar, Stasis, TestServer}

  @channel_sup ARI.TestSupervisor

  setup_all do
    ChannelRegistrar.start_link([])
    DynamicSupervisor.start_link(strategy: :one_for_one, name: @channel_sup)
    []
  end

  setup do
    test_pid = self()

    {:ok, {server_ref, url}} = TestServer.start(test_pid)

    on_exit(fn -> TestServer.shutdown(server_ref) end)

    client_pid = Stasis.start_link(@channel_sup, get_config(:ari_test), url, "", "")

    server_pid = TestServer.receive_socket_pid()

    channel = 10_000..999_999_999 |> Enum.random() |> Integer.to_string()

    base64_pid = test_pid |> :erlang.term_to_binary() |> Base.encode64()

    payload = %{
      type: "StasisStart",
      args: [base64_pid],
      channel: %{
        id: channel,
        caller: %{number: "+15555555555"}
      }
    }

    send(server_pid, {:send_message, payload})

    [
      channel: channel,
      client_pid: client_pid,
      url: url,
      server_pid: server_pid,
      server_ref: server_ref,
      test_pid: test_pid,
      base64_pid: base64_pid
    ]
  end

  defp get_config(client) do
    :ex_ari
    |> Application.get_env(:clients)
    |> Map.get(client)
  end

  defmodule TestClient do
    @moduledoc false
    use GenServer

    @behaviour Stasis

    defstruct [
      :channel,
      :caller,
      :start_event,
      :args,
      :test_pid
    ]

    def start_link([state]) do
      GenServer.start_link(__MODULE__, state)
    end

    @impl GenServer
    def init(state) do
      [pid] = state.args
      test_pid = pid |> Base.decode64!() |> :erlang.binary_to_term()
      state = %__MODULE__{state | test_pid: test_pid}
      Process.flag(:trap_exit, true)
      Process.send_after(self(), :started, 0)
      {:ok, state}
    end

    @impl Stasis
    def state(channel, caller, args, start_event, _app_state) do
      %__MODULE__{channel: channel, caller: caller, args: args, start_event: start_event}
    end

    @impl GenServer
    def handle_info(:started, state) do
      send(state.test_pid, {:channel_process_started, state})
      {:noreply, state}
    end

    @impl GenServer
    def handle_info(event, state) do
      send(state.test_pid, event)
      {:noreply, state}
    end

    @impl GenServer
    def terminate(_reason, state) do
      send(state.test_pid, {:terminated, state})
      :ok
    end
  end

  test "channel process is started with StasisStart event", ctx do
    channel = ctx.channel
    assert_receive({:channel_process_started, %{channel: ^channel}})
  end

  test "channel process is killed with StasisEnd event", ctx do
    channel = ctx.channel
    server_pid = ctx.server_pid

    end_payload = %{
      type: "StasisEnd",
      args: [],
      channel: %{
        id: channel
      }
    }

    send(server_pid, {:send_message, end_payload})

    assert_receive({:terminated, %{channel: ^channel}})

    assert ChannelRegistrar.get_channel(channel) == nil
  end

  test "router channel process is NOT killed with StasisEnd event", ctx do
    channel = ctx.channel
    server_pid = ctx.server_pid

    end_payload = %{
      type: "StasisEnd",
      application: "router",
      args: [],
      channel: %{
        id: channel
      }
    }

    send(server_pid, {:send_message, end_payload})

    assert_receive({:terminated, %{channel: ^channel}})

    refute ChannelRegistrar.get_channel(channel) == nil
  end

  test "playback events propagate to correct channel", ctx do
    channel = ctx.channel
    server_pid = ctx.server_pid
    target_uri = "channel:#{channel}"

    payload = %{
      type: "PlaybackStarted",
      playback: %{
        target_uri: target_uri
      }
    }

    send(server_pid, {:send_message, payload})

    assert_receive({:ari, %{playback: %{target_uri: ^target_uri}}})
  end

  test "recording events propagate to correct channel", ctx do
    channel = ctx.channel
    server_pid = ctx.server_pid
    target_uri = "channel:#{channel}"

    payload = %{
      type: "RecordingStarted",
      recording: %{
        target_uri: target_uri
      }
    }

    send(server_pid, {:send_message, payload})

    assert_receive({:ari, %{recording: %{target_uri: ^target_uri}}})
  end

  test "anything with a channel property propagates to the correct channel process", ctx do
    channel = ctx.channel
    server_pid = ctx.server_pid

    payload = %{
      type: "Anything!!",
      channel: %{
        id: channel
      }
    }

    send(server_pid, {:send_message, payload})

    assert_receive({:ari, %{channel: %{id: ^channel}}})
  end

  test "an event without a known channel id will not propagate to a channel process", ctx do
    channel = ctx.channel
    server_pid = ctx.server_pid

    payload = %{
      type: "Anything!!"
    }

    send(server_pid, {:send_message, payload})

    refute_receive({:ari, %{channel: %{id: ^channel}}})
  end

  test "an event with an unregistered id won't blow up", ctx do
    server_pid = ctx.server_pid

    payload = %{
      type: "Anything!!",
      channel: %{
        id: "unknown_id"
      }
    }

    send(server_pid, {:send_message, payload})

    refute_receive({:ari, %{channel: %{id: "unknown_id"}}})
  end
end
