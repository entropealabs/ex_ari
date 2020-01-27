defmodule ARI.HTTP.Recordings do
  @moduledoc """
  HTTP Interface for CRUD operations on Recording objects

  REST Reference: https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+Recordings+REST+API

  Live Recording Object: https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+REST+Data+Models#Asterisk16RESTDataModels-LiveRecording

  Stored Recording Object: https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+REST+Data+Models#Asterisk16RESTDataModels-StoredRecording
  """

  use ARI.HTTPClient, "/recordings"
  alias ARI.HTTPClient.Response

  @spec list_stored :: Response.t()
  def list_stored do
    GenServer.call(__MODULE__, :list_stored)
  end

  @spec get_stored(String.t()) :: Response.t()
  def get_stored(name) do
    GenServer.call(__MODULE__, {:get_stored, name})
  end

  @spec get_stored_file(String.t()) :: Response.t()
  def get_stored_file(name) do
    GenServer.call(__MODULE__, {:get_stored_file, name})
  end

  @spec copy_stored(String.t(), String.t()) :: Response.t()
  def copy_stored(name, destination) do
    GenServer.call(__MODULE__, {:copy_stored, name, destination})
  end

  @spec delete_stored(String.t()) :: Response.t()
  def delete_stored(name) do
    GenServer.call(__MODULE__, {:delete_stored, name})
  end

  @spec get_live(String.t()) :: Response.t()
  def get_live(name) do
    GenServer.call(__MODULE__, {:get_live, name})
  end

  @spec cancel_live(String.t()) :: Response.t()
  def cancel_live(name) do
    GenServer.call(__MODULE__, {:cancel_live, name})
  end

  @spec stop_live(String.t()) :: Response.t()
  def stop_live(name) do
    GenServer.call(__MODULE__, {:stop_live, name})
  end

  @spec pause_live(String.t()) :: Response.t()
  def pause_live(name) do
    GenServer.call(__MODULE__, {:pause_live, name})
  end

  @spec unpause_live(String.t()) :: Response.t()
  def unpause_live(name) do
    GenServer.call(__MODULE__, {:unpause_live, name})
  end

  @spec mute_live(String.t()) :: Response.t()
  def mute_live(name) do
    GenServer.call(__MODULE__, {:mute_live, name})
  end

  @spec unmute_live(String.t()) :: Response.t()
  def unmute_live(name) do
    GenServer.call(__MODULE__, {:unmute_live, name})
  end

  def handle_call(:list_stored, from, state) do
    {:noreply, request("GET", "/stored", from, state)}
  end

  def handle_call({:get_stored, name}, from, state) do
    {:noreply, request("GET", "/stored/#{name}", from, state)}
  end

  def handle_call({:get_stored_file, name}, from, state) do
    {:noreply, request("GET", "/stored/#{name}/file", from, state)}
  end

  def handle_call({:copy_stored, name, destination}, from, state) do
    {:noreply,
     request(
       "POST",
       "/stored/#{name}/copy?#{encode_params(%{destinationRecordingName: destination})}",
       from,
       state
     )}
  end

  def handle_call({:delete_stored, name}, from, state) do
    {:noreply, request("DELETE", "/stored/#{name}", from, state)}
  end

  def handle_call({:get_live, name}, from, state) do
    {:noreply, request("GET", "/live/#{name}", from, state)}
  end

  def handle_call({:cancel_live, name}, from, state) do
    {:noreply, request("DELETE", "/live/#{name}", from, state)}
  end

  def handle_call({:stop_live, name}, from, state) do
    {:noreply, request("POST", "/live/#{name}/stop", from, state)}
  end

  def handle_call({:pause_live, name}, from, state) do
    {:noreply, request("POST", "/live/#{name}/pause", from, state)}
  end

  def handle_call({:unpause_live, name}, from, state) do
    {:noreply, request("DELETE", "/live/#{name}/pause", from, state)}
  end

  def handle_call({:mute_live, name}, from, state) do
    {:noreply, request("POST", "/live/#{name}/mute", from, state)}
  end

  def handle_call({:unmute_live, name}, from, state) do
    {:noreply, request("DELETE", "/live/#{name}/mute", from, state)}
  end
end
