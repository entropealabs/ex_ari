defmodule ARI.HTTP.Mailboxes do
  @moduledoc """
  HTTP Interface for CRUD operations on Mailbox objects

  REST Reference: https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+Mailboxes+REST+API

  Mailbox Object: https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+REST+Data+Models#Asterisk16RESTDataModels-Mailbox
  """

  use ARI.HTTPClient, "/mailboxes"
  alias ARI.HTTPClient.Response

  @spec list :: Response.t()
  def list do
    GenServer.call(__MODULE__, :list)
  end

  @spec get(String.t()) :: Response.t()
  def get(name) do
    GenServer.call(__MODULE__, {:get, name})
  end

  @spec update(String.t(), integer(), integer()) :: Response.t()
  def update(name, old_messages, new_messages) do
    GenServer.call(__MODULE__, {:update, name, old_messages, new_messages})
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

  def handle_call({:update, name, old_messages, new_messages}, from, state) do
    {:noreply,
     request(
       "PUT",
       "/#{name}?#{encode_params(%{oldMessages: old_messages, newMessages: new_messages})}",
       from,
       state
     )}
  end

  def handle_call({:delete, name}, from, state) do
    {:noreply, request("DELETE", "/#{name}", from, state)}
  end
end
