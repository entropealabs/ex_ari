defmodule ARI.Listener.Behaviour do
  @type payload() :: map()
  @type event() :: bitstring()
  @callback handle_payload(payload(), any) :: {:noreply, any()}
  @callback handle_error(any(), any()) :: {:noreply, any()}
  @callback bootloader(any, any) :: {:ok, any}
  @callback handle_after_start(any(), any()) :: {:noreply, any()}
end

defmodule ARI.Listener do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      use GenServer
      require Logger
      @behaviour ARI.Listener.Behaviour

      def start_link(opts) do
        GenServer.start_link(__MODULE__, opts, name: __MODULE__)
      end

      def init(opts) do
        {:ok, opts} =
          self()
          |> Process.info()
          |> bootloader(opts)

        opts = Keyword.merge(opts, debug_logs: true)
        {:ok, opts, 0}
      end

      def handle_info(:timeout, state) do
        Process.flag(:trap_exit, true)

        Logger.info(fn ->
          {"Listener: #{__MODULE__} started successfully!", [ansi_color: :green]}
        end)

        send(self(), {:after_start, self()})
        {:noreply, state}
      end

      def handle_info({:DOWN, _ref, :process, _data, reason}, state) do
        Logger.error("Listener: #{__MODULE__} is exiting: #{reason}")
        {:stop, :error, state}
      end

      def handle_info({:EXIT, _from, reason}, state) do
        Logger.error("Listener: #{__MODULE__} is exiting: #{reason}")
        {:stop, :error, state}
      end

      def handle_info({:event, payload}, state) do
        handle_payload(payload, state)
        {:noreply, state}
      end

      def handle_info({:after_start, pid}, state) do
        handle_after_start(pid, state)
        {:noreply, state}
      end

      def handle_info(any, state) do
        handle_error(any, state)
        {:noreply, state}
      end

      def handle_payload(payload, state) do
        msg = """
        \n[#{__MODULE__}]
        Unhandled Event
        #{inspect(payload, pretty: true)}

        Define a `handle_info/2` function in the listener module to handle this,
        Filter out unwanted topics in the `subscriptions` list when configuring :comm_box,
        such that only listen for topics you expect to get messages from.
        """

        state
        |> Keyword.get(:debug_logs, false)
        |> case do
          false -> :ok
          true -> Logger.warn(msg)
        end

        {:noreply, state}
      end

      def handle_error(message, state) do
        err_msg = """
        [#{__MODULE__}] ERROR!
        #{inspect(message, pretty: true)}
        """

        state
        |> Keyword.get(:debug_logs, false)
        |> case do
          false -> :ok
          true -> Logger.error(err_msg)
        end

        {:noreply, state}
      end

      def bootloader(_info, args) do
        """
        [#{__MODULE__}]
        bootloader/2 not set!

        bootloader/2 function can be used to setup the listener initial parameters.
        Require out must be an okay tuple `{:ok, [_|_] = args}` and a keyword list as the startup arguments.
        """
        |> Logger.warn()

        {:ok, args}
      end

      def handle_after_start(pid, state) do
        """
        [#{__MODULE__}]
        handle_after_start/2 not set!

        handle_after_start/2 callback function called after the listener has completed initial bootup sequence.
        Should always return `{:noreply, state}`
        """
        |> Logger.warn()

        {:noreply, state}
      end

      defoverridable ARI.Listener.Behaviour
    end
  end
end
