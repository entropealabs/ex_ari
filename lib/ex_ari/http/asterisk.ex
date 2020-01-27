defmodule ARI.HTTP.Asterisk do
  @moduledoc """
  HTTP Interface for CRUD operations on Asterisk

  REST Reference: https://wiki.asterisk.org/wiki/display/AST/Asterisk+16+Asterisk+REST+API
  """

  use ARI.HTTPClient, "/asterisk"
  alias ARI.HTTPClient.Response

  @spec info :: Response.t()
  def info do
    GenServer.call(__MODULE__, :info)
  end

  @spec get_config(String.t(), String.t(), String.t()) :: Response.t()
  def get_config(config_class, obj_type, id) do
    GenServer.call(__MODULE__, {:get_config, config_class, obj_type, id})
  end

  @spec put_config(String.t(), String.t(), String.t(), map()) :: Response.t()
  def put_config(config_class, obj_type, id, payload) do
    GenServer.call(__MODULE__, {:put_config, config_class, obj_type, id, payload})
  end

  @spec delete_config(String.t(), String.t(), String.t()) :: Response.t()
  def delete_config(config_class, obj_type, id) do
    GenServer.call(__MODULE__, {:delete_config, config_class, obj_type, id})
  end

  @spec get_logging :: Response.t()
  def get_logging do
    GenServer.call(__MODULE__, :get_logging)
  end

  @spec add_logging(String.t()) :: Response.t()
  def add_logging(channel) do
    GenServer.call(__MODULE__, {:add_logging, channel})
  end

  @spec delete_logging(String.t()) :: Response.t()
  def delete_logging(channel) do
    GenServer.call(__MODULE__, {:delete_logging, channel})
  end

  @spec rotate_logging(String.t()) :: Response.t()
  def rotate_logging(channel) do
    GenServer.call(__MODULE__, {:rotate_logging, channel})
  end

  @spec get_modules :: Response.t()
  def get_modules do
    GenServer.call(__MODULE__, :get_modules)
  end

  @spec get_module(String.t()) :: Response.t()
  def get_module(name) do
    GenServer.call(__MODULE__, {:get_module, name})
  end

  @spec load_module(String.t()) :: Response.t()
  def load_module(name) do
    GenServer.call(__MODULE__, {:load_module, name})
  end

  @spec reload_module(String.t()) :: Response.t()
  def reload_module(name) do
    GenServer.call(__MODULE__, {:reload_module, name})
  end

  @spec unload_module(String.t()) :: Response.t()
  def unload_module(name) do
    GenServer.call(__MODULE__, {:unload_module, name})
  end

  @spec get_variable(String.t()) :: Response.t()
  def get_variable(name) do
    GenServer.call(__MODULE__, {:get_variable, name})
  end

  @spec set_variable(String.t(), String.t()) :: Response.t()
  def set_variable(name, value) do
    GenServer.call(__MODULE__, {:set_variable, name, value})
  end

  def handle_call({:get_variable, name}, from, state) do
    {:noreply, request("GET", "/variable?#{encode_params(%{variable: name})}", from, state)}
  end

  def handle_call({:set_variable, name, value}, from, state) do
    {:noreply,
     request("POST", "/variable?#{encode_params(%{variable: name, value: value})}", from, state)}
  end

  def handle_call({:rotate_logging, channel}, from, state) do
    {:noreply, request("PUT", "/logging/#{channel}/rotate", from, state)}
  end

  def handle_call({:delete_logging, channel}, from, state) do
    {:noreply, request("DELETE", "/logging/#{channel}", from, state)}
  end

  def handle_call({:add_logging, channel}, from, state) do
    {:noreply, request("POST", "/logging/#{channel}", from, state)}
  end

  def handle_call(:get_logging, from, state) do
    {:noreply, request("GET", "/logging", from, state)}
  end

  def handle_call(:get_modules, from, state) do
    {:noreply, request("GET", "/modules", from, state)}
  end

  def handle_call({:get_module, name}, from, state) do
    {:noreply, request("GET", "/modules/#{name}", from, state)}
  end

  def handle_call({:load_module, name}, from, state) do
    {:noreply, request("POST", "/modules/#{name}", from, state)}
  end

  def handle_call({:reload_module, name}, from, state) do
    {:noreply, request("PUT", "/modules/#{name}", from, state)}
  end

  def handle_call({:unload_module, name}, from, state) do
    {:noreply, request("DELETE", "/modules/#{name}", from, state)}
  end

  def handle_call(:info, from, state) do
    {:noreply, request("GET", "/info", from, state)}
  end

  def handle_call({:get_config, config_class, obj_type, id}, from, state) do
    {:noreply, request("GET", "/config/dynamic/#{config_class}/#{obj_type}/#{id}", from, state)}
  end

  def handle_call({:put_config, config_class, obj_type, id, payload}, from, state) do
    {:noreply,
     request(
       "PUT",
       "/config/dynamic/#{config_class}/#{obj_type}/#{id}",
       from,
       state,
       payload
     )}
  end

  def handle_call({:delete_config, config_class, obj_type, id}, from, state) do
    {:noreply,
     request("DELETE", "/config/dynamic/#{config_class}/#{obj_type}/#{id}", from, state)}
  end
end
