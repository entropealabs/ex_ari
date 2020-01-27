defmodule ARI.ChannelRegistrar do
  @moduledoc """
  Agent to manage current Asterisk call channels -> PID registration
  """
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def put_channel(id, pid) do
    Agent.update(__MODULE__, fn state -> Map.put(state, id, pid) end)
  end

  def get_channel(id) do
    Agent.get(__MODULE__, fn state -> Map.get(state, id) end)
  end

  def delete_channel(id) do
    Agent.update(__MODULE__, fn state -> Map.delete(state, id) end)
  end
end
