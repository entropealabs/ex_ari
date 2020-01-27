defmodule ARI.HTTP.Endpoints do
  @moduledoc """
  HTTP Interface for CRUD operations on Endpoint objects

  REST Reference: https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+Endpoints+REST+API

  Endpoint Object: https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+REST+Data+Models#Asterisk16RESTDataModels-Endpoint
  """
  use ARI.HTTPClient, "/endpoints"
  alias ARI.HTTPClient.Response

  @spec list :: Response.t()
  def list do
    GenServer.call(__MODULE__, :list)
  end

  @spec list_by_tech(String.t()) :: Response.t()
  def list_by_tech(tech) do
    GenServer.call(__MODULE__, {:list, tech})
  end

  @spec get(String.t(), String.t()) :: Response.t()
  def get(tech, id) do
    GenServer.call(__MODULE__, {:get, tech, id})
  end

  @spec send_message(String.t(), String.t(), String.t(), %{variables: %{}}) ::
          Response.t()
  def send_message(to, from, body \\ "", variables \\ %{variables: %{}}) do
    GenServer.call(__MODULE__, {:send_message, to, from, body, variables})
  end

  @spec send_message_to_endpoint(String.t(), String.t(), String.t(), String.t(), %{variables: %{}}) ::
          Response.t()
  def send_message_to_endpoint(tech, id, from, body \\ "", variables \\ %{variables: %{}}) do
    GenServer.call(__MODULE__, {:send_message_to_endpoint, tech, id, from, body, variables})
  end

  def handle_call(:list, from, state) do
    {:noreply, request("GET", "", from, state)}
  end

  def handle_call({:list, tech}, from, state) do
    {:noreply, request("GET", "/#{tech}", from, state)}
  end

  def handle_call({:get, tech, id}, from, state) do
    {:noreply, request("GET", "/#{tech}/#{id}", from, state)}
  end

  def handle_call({:send_message, to, is_from, body, variables}, from, state) do
    {:noreply,
     request(
       "PUT",
       "/sendMessage?#{encode_params(%{to: to, from: is_from, body: body})}",
       from,
       state,
       variables
     )}
  end

  def handle_call({:send_message_to_endpoint, tech, id, is_from, body, variables}, from, state) do
    {:noreply,
     request(
       "PUT",
       "/#{tech}/#{id}/sendMessage?#{encode_params(%{from: is_from, body: body})}",
       from,
       state,
       variables
     )}
  end
end
