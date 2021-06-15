defmodule ARI.Additions do
  alias ARI.Stasis.State
  require Logger

  def check_for_event_listener(%State{} = state) do
    {:ok, state}
  end

  def check(%State{listener: listener} = state, count \\ 0) do
    running = {"Event Listener is alive!", ansi_color: :green}
    retrying = {"Event Listener not alive, retrying"}
    failed = {"Event Listener NOT REGISTERED."}

    running? = Process.alive?(listener)
    retry? = count <= 5

    {running?, retry?}
    |> case do
      {true, true} ->
        Logger.info(fn -> running end)
        {1, state}

      {true, false} ->
        Logger.error(fn -> failed end)
        {0, %{state | listener: nil}}

      {false, true} ->
        Logger.warn(fn -> retrying end)
        {2, state}
    end
  end

  def check_async(frm, state, count \\ 0) do
    Task.start(fn ->
      state
      |> check(count)
      |> case do
        {2, _} -> send(self(), {:retry, state, count + 1})
        {0, _} -> Logger.error("Retried for #{count} times.")
        {1, _} -> send(frm, {:listener_alive, state})
      end

      receive do
        {:retry, state, count} ->
          state
          |> check(count)
          |> case do
            {2, _} -> send(self(), {:retry, state, count + 1})
            {0, _} -> Logger.error("Retried for #{count} times.")
            {1, _} -> send(frm, {:listener_alive, state})
          end

          # code
      end
    end)

    state
  end
end
