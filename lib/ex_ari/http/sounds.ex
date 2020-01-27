defmodule ARI.HTTP.Sounds do
  @moduledoc """
  HTTP Interface for CRUD operations on Sound objects

  REST Reference: https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+Sounds+REST+API

  Sound Object: https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+REST+Data+Models#Asterisk16RESTDataModels-Sound
  """

  use ARI.HTTPClient, "/sounds"
  alias ARI.HTTPClient.Response

  @spec list :: Response.t()
  def list do
    GenServer.call(__MODULE__, :list)
  end

  @spec get(String.t()) :: Response.t()
  def get(id) do
    GenServer.call(__MODULE__, {:get, id})
  end

  def handle_call(:list, from, state) do
    {:noreply, request("GET", "", from, state)}
  end

  def handle_call({:get, id}, from, state) do
    {:noreply, request("GET", "/#{id}", from, state)}
  end
end
