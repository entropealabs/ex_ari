defmodule ARI.Configurator do
  @moduledoc """
  GenServer to create dynamic asterisk configuration
  """
  use GenServer
  alias ARI.HTTP.Asterisk
  alias ARI.HTTPClient.Response
  import ARI.Util, only: [config_diff: 2]

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec init(name: String.t(), transport: String.t(), context: String.t(), config_module: atom()) ::
          :ignore
  def init([name, transport, context, config_module]) do
    :ok = config_module.pjsip_config()
    Asterisk.reload_module("res_pjsip")
    put_config({"aor", config_module.aor(name)})
    put_config({"endpoint", config_module.endpoint(name, context, transport)})
    put_config({"identify", config_module.identify(name)})
    :ignore
  end

  defp put_config({type, config}) when is_list(config) do
    config
    |> Enum.each(fn c -> put_config({type, c}) end)
  end

  defp put_config({type, %{name: name, fields: fields}}) do
    %Response{json: existing_config} = Asterisk.get_config("res_pjsip", type, name)

    case config_diff(existing_config, fields) do
      [] ->
        :noop

      fields ->
        Logger.info("Creating/Updating #{type} Asterisk Config: #{inspect(fields)}")
        Asterisk.put_config("res_pjsip", type, name, %{fields: fields})
    end
  end
end
