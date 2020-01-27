defmodule ARI.HTTP.Devicestates do
  @moduledoc """
  HTTP Interface for CRUD operations on Devicestate objects

  REST Reference: https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+Devicestates+REST+API

  Devicestate Object: https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+REST+Data+Models#Asterisk16RESTDataModels-DeviceState
  """

  alias ARI.HTTPClient.Response
  use ARI.HTTPClient, "/deviceStates"

  @spec list :: Response.t()
  def list do
    GenServer.call(__MODULE__, :list)
  end

  @spec get(String.t()) :: Response.t()
  def get(name) do
    GenServer.call(__MODULE__, {:get, name})
  end

  @spec update(String.t(), String.t()) :: Response.t()
  def update(name, device_state) do
    GenServer.call(__MODULE__, {:update, name, device_state})
  end

  @spec delete(String.t()) :: Response.t()
  def delete(name) do
    GenServer.call(__MODULE__, {:delete, name})
  end

  def handle_call(:list, from, state) do
    {:noreply, request("GET", "", from, state)}
  end

  def handle_call({:get, name}, from, state) do
    {:noreply, request("GET", "/#{name}", from, state)}
  end

  def handle_call({:update, name, device_state}, from, state) do
    {:noreply,
     request("PUT", "/#{name}?#{encode_params(%{deviceState: device_state})}", from, state)}
  end

  def handle_call({:delete, name}, from, state) do
    {:noreply, request("DELETE", "/#{name}", from, state)}
  end
end
