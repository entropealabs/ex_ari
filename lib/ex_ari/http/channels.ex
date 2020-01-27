defmodule ARI.HTTP.Channels do
  @moduledoc """
  HTTP Interface for CRUD operations on Channel objects

  REST Reference: https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+Channels+REST+API

  Channel Object: https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+REST+Data+Models#Asterisk16RESTDataModels-Channel
  """
  use ARI.HTTPClient, "/channels"
  alias ARI.HTTPClient.Response

  @spec list :: Response.t()
  def list do
    GenServer.call(__MODULE__, :list)
  end

  @spec get(String.t()) :: Response.t()
  def get(id) do
    GenServer.call(__MODULE__, {:get, id})
  end

  @spec get(map()) :: Response.t()
  def originate(%{endpoint: _} = payload) do
    GenServer.call(__MODULE__, {:originate, payload})
  end

  @spec originate(binary(), map()) :: Response.t()
  def originate(id, %{endpoint: _} = payload) do
    GenServer.call(__MODULE__, {:originate, id, payload})
  end

  @spec create(map()) :: Response.t()
  def create(%{endpoint: _, app: _} = payload) do
    GenServer.call(__MODULE__, {:create, payload})
  end

  @spec hangup(String.t()) :: Response.t()
  def hangup(id) do
    GenServer.call(__MODULE__, {:hangup, id})
  end

  @spec continue_in_dialplan(String.t(), String.t(), String.t(), String.t(), String.t()) ::
          Response.t()
  def continue_in_dialplan(id, context, extension, priority, label) do
    GenServer.call(__MODULE__, {:continue_in_dialplan, id, context, extension, priority, label})
  end

  @spec redirect(String.t(), String.t()) :: Response.t()
  def redirect(id, endpoint) do
    GenServer.call(__MODULE__, {:redirect, id, endpoint})
  end

  @spec answer(String.t()) :: Response.t()
  def answer(id) do
    GenServer.call(__MODULE__, {:answer, id})
  end

  @spec ring(String.t()) :: Response.t()
  def ring(id) do
    GenServer.call(__MODULE__, {:ring, id})
  end

  @spec ring_stop(String.t()) :: Response.t()
  def ring_stop(id) do
    GenServer.call(__MODULE__, {:ring_stop, id})
  end

  @spec send_dtmf(String.t(), String.t(), integer(), integer(), integer(), integer()) ::
          Response.t()
  def send_dtmf(id, dtmf, before \\ 100, between \\ 100, duration \\ 100, after_ms \\ 100) do
    GenServer.call(__MODULE__, {:send_dtmf, id, dtmf, before, between, duration, after_ms})
  end

  @spec mute(String.t(), String.t()) :: Response.t()
  def mute(id, direction \\ "both") do
    GenServer.call(__MODULE__, {:mute, id, direction})
  end

  @spec unmute(String.t(), String.t()) :: Response.t()
  def unmute(id, direction \\ "both") do
    GenServer.call(__MODULE__, {:unmute, id, direction})
  end

  @spec hold(String.t()) :: Response.t()
  def hold(id) do
    GenServer.call(__MODULE__, {:hold, id})
  end

  @spec unhold(String.t()) :: Response.t()
  def unhold(id) do
    GenServer.call(__MODULE__, {:unhold, id})
  end

  @spec start_moh(String.t(), String.t()) :: Response.t()
  def start_moh(id, moh_class) do
    GenServer.call(__MODULE__, {:start_moh, id, moh_class})
  end

  @spec stop_moh(String.t()) :: Response.t()
  def stop_moh(id) do
    GenServer.call(__MODULE__, {:stop_moh, id})
  end

  @spec start_silence(String.t()) :: Response.t()
  def start_silence(id) do
    GenServer.call(__MODULE__, {:start_silence, id})
  end

  @spec stop_silence(String.t()) :: Response.t()
  def stop_silence(id) do
    GenServer.call(__MODULE__, {:stop_silence, id})
  end

  @spec play(String.t(), String.t(), String.t(), String.t(), integer(), integer()) ::
          Response.t()
  def play(id, playback_id, media, lang \\ "en", offsetms \\ 0, skipms \\ 3000) do
    GenServer.call(__MODULE__, {:play, id, playback_id, media, lang, offsetms, skipms})
  end

  @spec move(String.t(), String.t(), String.t()) :: Response.t()
  def move(id, app, args \\ "") do
    GenServer.call(__MODULE__, {:move, id, app, args})
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

  @spec get_var(String.t(), String.t()) :: Response.t()
  def get_var(id, name) do
    GenServer.call(__MODULE__, {:get_var, id, name})
  end

  @spec set_var(String.t(), String.t(), String.t()) :: Response.t()
  def set_var(id, name, value) do
    GenServer.call(__MODULE__, {:set_var, id, name, value})
  end

  @spec snoop(String.t(), String.t(), String.t(), String.t(), String.t(), String.t()) ::
          Response.t()
  def snoop(id, snoop_id, app, spy \\ "none", whisper \\ "none", app_args \\ "") do
    GenServer.call(__MODULE__, {:snoop, id, snoop_id, spy, whisper, app, app_args})
  end

  @spec dial(String.t(), String.t(), integer()) :: Response.t()
  def dial(id, caller \\ "", timeout \\ 1000) do
    GenServer.call(__MODULE__, {:dial, id, caller, timeout})
  end

  def handle_call(:list, from, state) do
    {:noreply, request("GET", "", from, state)}
  end

  def handle_call({:get, id}, from, state) do
    {:noreply, request("GET", "/#{id}", from, state)}
  end

  def handle_call({:originate, payload}, from, state) do
    {:noreply, request("POST", "", from, state, payload)}
  end

  def handle_call({:originate, id, payload}, from, state) do
    {:noreply, request("POST", "/#{id}", from, state, payload)}
  end

  def handle_call({:create, payload}, from, state) do
    {:noreply, request("POST", "/create?#{encode_params(payload)}", from, state)}
  end

  def handle_call({:hangup, id}, from, state) do
    {:noreply, request("DELETE", "/#{id}", from, state)}
  end

  def handle_call({:continue_in_dialplan, id, context, extension, priority, label}, from, state) do
    {:noreply,
     request(
       "POST",
       "/#{id}/continue?#{
         encode_params(%{context: context, extension: extension, priority: priority, label: label})
       }",
       from,
       state
     )}
  end

  def handle_call({:redirect, id, endpoint}, from, state) do
    {:noreply,
     request("POST", "/#{id}/redirect?#{encode_params(%{endpoint: endpoint})}", from, state)}
  end

  def handle_call({:move, id, app, args}, from, state) do
    {:noreply,
     request("POST", "/#{id}/move?#{encode_params(%{app: app, appArgs: args})}", from, state)}
  end

  def handle_call({:answer, id}, from, state) do
    {:noreply, request("POST", "/#{id}/answer", from, state)}
  end

  def handle_call({:ring, id}, from, state) do
    {:noreply, request("POST", "/#{id}/ring", from, state)}
  end

  def handle_call({:ring_stop, id}, from, state) do
    {:noreply, request("DELETE", "/#{id}/ring", from, state)}
  end

  def handle_call({:send_dtmf, id, dtmf, before, between, duration, after_ms}, from, state) do
    {:noreply,
     request(
       "POST",
       "/#{id}/dtmf?#{
         encode_params(%{
           dtmf: dtmf,
           before: before,
           between: between,
           duration: duration,
           after: after_ms
         })
       }",
       from,
       state
     )}
  end

  def handle_call({:mute, id, direction}, from, state) do
    {:noreply,
     request("POST", "/#{id}/mute?#{encode_params(%{direction: direction})}", from, state)}
  end

  def handle_call({:unmute, id, direction}, from, state) do
    {:noreply,
     request("DELETE", "/#{id}/mute?#{encode_params(%{direction: direction})}", from, state)}
  end

  def handle_call({:hold, id}, from, state) do
    {:noreply, request("POST", "/#{id}/hold", from, state)}
  end

  def handle_call({:unhold, id}, from, state) do
    {:noreply, request("DELETE", "/#{id}/hold", from, state)}
  end

  def handle_call({:start_moh, id, moh_class}, from, state) do
    {:noreply,
     request("POST", "/#{id}/moh?#{encode_params(%{mohClass: moh_class})}", from, state)}
  end

  def handle_call({:stop_moh, id}, from, state) do
    {:noreply, request("DELETE", "/#{id}/moh", from, state)}
  end

  def handle_call({:start_silence, id}, from, state) do
    {:noreply, request("POST", "/#{id}/silence", from, state)}
  end

  def handle_call({:stop_silence, id}, from, state) do
    {:noreply, request("DELETE", "/#{id}/silence", from, state)}
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

  def handle_call({:get_var, id, name}, from, state) do
    {:noreply, request("GET", "/#{id}/variable?#{encode_params(%{variable: name})}", from, state)}
  end

  def handle_call({:set_var, id, name, value}, from, state) do
    {:noreply,
     request(
       "POST",
       "/#{id}/variable?#{encode_params(%{variable: name, value: value})}",
       from,
       state
     )}
  end

  def handle_call(
        {:snoop, id, snoop_id, spy, whisper, app, app_args},
        from,
        state
      ) do
    {:noreply,
     request(
       "POST",
       "/#{id}/snoop/#{snoop_id}?#{
         encode_params(%{spy: spy, whisper: whisper, app: app, appArgs: app_args})
       }",
       from,
       state
     )}
  end

  def handle_call({:dial, id, caller, timeout}, from, state) do
    {:noreply,
     request(
       "POST",
       "/#{id}/dial?#{encode_params(%{caller: caller, timeout: timeout})}",
       from,
       state
     )}
  end
end
