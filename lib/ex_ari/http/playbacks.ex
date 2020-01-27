defmodule ARI.HTTP.Playbacks do
  @moduledoc """
  HTTP Interface for CRUD operations on Playback objects

  REST Reference: https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+Playbacks+REST+API

  Playback Object: https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+REST+Data+Models#Asterisk16RESTDataModels-Playback
  """

  use ARI.HTTPClient, "/playbacks"
  alias ARI.HTTPClient.Response

  @spec get(String.t()) :: Response.t()
  def get(id) do
    GenServer.call(__MODULE__, {:get, id})
  end

  @spec stop(String.t()) :: Response.t()
  def stop(id) do
    GenServer.call(__MODULE__, {:stop, id})
  end

  @spec control(String.t(), String.t()) :: Response.t()
  def control(id, operation) do
    GenServer.call(__MODULE__, {:control, id, operation})
  end

  def handle_call({:get, id}, from, state) do
    {:noreply, request("GET", "/#{id}", from, state)}
  end

  def handle_call({:stop, id}, from, state) do
    {:noreply, request("DELETE", "/#{id}", from, state)}
  end

  def handle_call({:control, id, operation}, from, state) do
    {:noreply,
     request("POST", "/#{id}/control?#{encode_params(%{operation: operation})}", from, state)}
  end
end
