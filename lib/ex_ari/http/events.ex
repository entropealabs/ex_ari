defmodule ARI.HTTP.Events do
  @moduledoc """
  HTTP Interface for CRUD operations on Event objects

  There is only one function in this module to create a user event. All incoming events are handled by the `ARI.WebSocket` module

  REST Reference: https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+Events+REST+API

  Messages: https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+REST+Data+Models#Asterisk16RESTDataModels-Message
  """
  use ARI.HTTPClient, "/events"
  alias ARI.HTTPClient.Response

  @spec create(String.t(), String.t(), list(), map()) :: Response.t()
  def create(name, application, sources \\ [], variables \\ %{variables: %{}}) do
    GenServer.call(__MODULE__, {:create, name, application, sources, variables})
  end

  def handle_call({:create, name, application, sources, variables}, from, state) do
    {:noreply,
     request(
       "POST",
       "/user/#{name}?#{
         encode_params(%{application: application, source: Enum.join(sources, ",")})
       }",
       from,
       state,
       variables
     )}
  end
end
