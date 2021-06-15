defmodule ARI.HTTP.Applications do
  @moduledoc """
  HTTP Interface for CRUD operations on Application objects

  REST Reference: https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+Applications+REST+API

  Application Object: https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+REST+Data+Models#Asterisk16RESTDataModels-Application
  """
  use ARI.HTTPClient, "/applications"

  alias ARI.HTTPClient.Response

  @spec list :: Response.t()
  def list do
    GenServer.call(__MODULE__, :list)
  end

  @spec get(String.t()) :: Response.t()
  def get(name) do
    GenServer.call(__MODULE__, {:get, name})
  end

  @spec subscribe(String.t()) :: Response.t()
  def subscribe(name) do
    GenServer.call(__MODULE__, {:subscribe, name})
  end

  @spec unsubscribe(String.t()) :: Response.t()
  def unsubscribe(name) do
    GenServer.call(__MODULE__, {:unsubscribe, name})
  end

  def handle_call(:list, from, state) do
    {:noreply, request("GET", "", from, state)}
  end

  def handle_call({:get, name}, from, state) do
    {:noreply, request("GET", "/#{name}", from, state)}
  end

  def handle_call({:subscribe, name}, from, state) do
    {:noreply, request("POST", "/#{name}/subscription", from, state)}
  end

  def handle_call({:subscribe, name, subscriptions}, from, state) do
    params =
      case parse_subscription_event(subscriptions) do
        nil -> nil
        any -> %{eventSource: any}
      end

    {:noreply, request("POST", "/#{name}/subscription", from, state, params)}
  end

  def handle_call({:unsubscribe, name}, from, state) do
    {:noreply, request("DELETE", "/#{name}/subscription", from, state)}
  end

  defp parse_subscription_event(data) when is_map(data),
    do: data |> Enum.reduce([], &(&2 ++ [parse_subscription_event(&1)])) |> Enum.join(",")

  defp parse_subscription_event(channel: c_id) when is_bitstring(c_id), do: "channel:#{c_id}"
  defp parse_subscription_event(bridge: b_id) when is_bitstring(b_id), do: "bridge:#{b_id}"

  defp parse_subscription_event(endpoint: %{resource: r, tech: t})
       when is_bitstring(r) and is_bitstring(t),
       do: "endpoint:#{t}[/#{r}]"

  defp parse_subscription_event(deviceState: d_n) when is_bitstring(d_n), do: "deviceState:#{d_n}"
  defp parse_subscription_event(_), do: nil
end
