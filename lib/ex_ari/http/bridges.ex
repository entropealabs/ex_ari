defmodule ARI.HTTP.Bridges do
  @moduledoc """
  HTTP Interface for CRUD operations on Bridge Objects

  REST Reference: https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+Bridges+REST+API

  Bridge Object: https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+REST+Data+Models#Asterisk16RESTDataModels-Bridge
  """
  use ARI.HTTPClient, "/bridges"
  alias ARI.HTTPClient.Response

  @spec list :: Response.t()
  def list do
    GenServer.call(__MODULE__, :list)
  end

  @spec get(String.t()) :: Response.t()
  def get(id) do
    GenServer.call(__MODULE__, {:get, id})
  end

  @spec create(String.t(), String.t(), list()) :: Response.t()
  def create(id, name, types \\ []) do
    GenServer.call(__MODULE__, {:create, types, id, name})
  end

  @spec update(String.t(), String.t(), String.t()) :: Response.t()
  def update(id, name, types) do
    GenServer.call(__MODULE__, {:update, types, id, name})
  end

  @spec delete(String.t()) :: Response.t()
  def delete(id) do
    GenServer.call(__MODULE__, {:delete, id})
  end

  @spec add_channels(String.t(), list(), String.t()) :: Response.t()
  def add_channels(id, channel_ids, role \\ "") do
    GenServer.call(__MODULE__, {:add_channels, id, channel_ids, role})
  end

  @spec remove_channels(String.t(), list()) :: Response.t()
  def remove_channels(id, channel_ids) do
    GenServer.call(__MODULE__, {:remove_channels, id, channel_ids})
  end

  @spec set_video_source(String.t(), String.t()) :: Response.t()
  def set_video_source(id, channel_id) do
    GenServer.call(__MODULE__, {:set_video_source, id, channel_id})
  end

  @spec clear_video_source(String.t()) :: Response.t()
  def clear_video_source(id) do
    GenServer.call(__MODULE__, {:clear_video_source, id})
  end

  @spec start_moh(String.t(), String.t()) :: Response.t()
  def start_moh(id, channel_id) do
    GenServer.call(__MODULE__, {:start_moh, id, channel_id})
  end

  @spec stop_moh(String.t()) :: Response.t()
  def stop_moh(id) do
    GenServer.call(__MODULE__, {:stop_moh, id})
  end

  @spec play(String.t(), String.t(), String.t(), String.t(), integer(), integer()) ::
          Response.t()
  def play(id, playback_id, media, lang \\ "en", offsetms \\ 0, skipms \\ 3000) do
    GenServer.call(__MODULE__, {:play, id, playback_id, media, lang, offsetms, skipms})
  end

  @spec record(
          String.t(),
          String.t(),
          String.t(),
          integer(),
          integer(),
          String.t(),
          String.t(),
          String.t()
        ) :: Response.t()
  def record(
        id,
        name,
        format,
        max_duration \\ 0,
        max_silence \\ 0,
        if_exists \\ "fail",
        beep \\ "no",
        terminate_on \\ "#"
      ) do
    GenServer.call(
      __MODULE__,
      {:record, id, name, format, max_duration, max_silence, if_exists, beep, terminate_on}
    )
  end

  def handle_call(:list, from, state) do
    {:noreply, request("GET", "", from, state)}
  end

  def handle_call({:get, id}, from, state) do
    {:noreply, request("GET", "/#{id}", from, state)}
  end

  def handle_call({:delete, id}, from, state) do
    {:noreply, request("DELETE", "/#{id}", from, state)}
  end

  def handle_call({:create, types, id, name}, from, state) do
    {:noreply,
     request(
       "POST",
       "?#{encode_params(%{type: Enum.join(types, ","), bridgeId: id, name: name})}",
       from,
       state
     )}
  end

  def handle_call({:update, types, id, name}, from, state) do
    {:noreply,
     request(
       "POST",
       "/#{id}?#{encode_params(%{type: Enum.join(types, ","), name: name})}",
       from,
       state
     )}
  end

  def handle_call({:add_channels, id, channel_ids, role}, from, state) do
    {:noreply,
     request(
       "POST",
       "/#{id}/addChannel?#{encode_params(%{channel: Enum.join(channel_ids, ","), role: role})}",
       from,
       state
     )}
  end

  def handle_call({:remove_channels, id, channel_ids}, from, state) do
    {:noreply,
     request(
       "POST",
       "/#{id}/removeChannel?#{encode_params(%{channel: Enum.join(channel_ids, ",")})}",
       from,
       state
     )}
  end

  def handle_call({:set_video_source, id, channel_id}, from, state) do
    {:noreply, request("POST", "/#{id}/videoSource/#{channel_id}", from, state)}
  end

  def handle_call({:clear_video_source, id}, from, state) do
    {:noreply, request("DELETE", "/#{id}/videoSource", from, state)}
  end

  def handle_call({:start_moh, id, channel_id}, from, state) do
    {:noreply,
     request("POST", "/#{id}/moh?#{encode_params(%{mohClass: channel_id})}", from, state)}
  end

  def handle_call({:stop_moh, id}, from, state) do
    {:noreply, request("DELETE", "/#{id}/moh", from, state)}
  end

  def handle_call({:play, id, playback_id, media, lang, offsetms, skipms}, from, state) do
    {:noreply,
     request(
       "POST",
       "/#{id}/play/#{playback_id}?#{
         encode_params(%{media: media, lang: lang, offsetms: offsetms, skipms: skipms})
       }",
       from,
       state
     )}
  end

  def handle_call(
        {:record, id, name, format, max_duration, max_silence, if_exists, beep, terminate_on},
        from,
        state
      ) do
    {:noreply,
     request(
       "POST",
       "/#{id}/record?#{
         encode_params(%{
           name: name,
           format: format,
           maxDurationSeconds: max_duration,
           maxSilenceSeconds: max_silence,
           ifExists: if_exists,
           beep: beep,
           terminateOn: terminate_on
         })
       }",
       from,
       state
     )}
  end
end
