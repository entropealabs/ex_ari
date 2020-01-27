defmodule ARI.Config do
  @moduledoc """
  Behaviour to provide dynamic configuration for the Asterisk server. 

  Configuring Asterisk can be a complex endeavor. In general this library assumes usage of the [res_pjsip](https://wiki.asterisk.org/wiki/display/AST/Configuring+res_pjsip) SIP driver provided with newer versions of Asterisk. Rather than trying to replicate the configuration documentation for pjsip, I recommend reading the Asterisk documetation at [https://wiki.asterisk.org/wiki/display/AST/Configuring+res_pjsip](https://wiki.asterisk.org/wiki/display/AST/Configuring+res_pjsip).

  This article my provide some useful information as well [https://wiki.asterisk.org/wiki/display/AST/Endpoints+and+Location%2C+A+Match+Made+in+Heaven](https://wiki.asterisk.org/wiki/display/AST/Endpoints+and+Location%2C+A+Match+Made+in+Heaven)

  It's also worth looking at the configuration module for the example application at [https://github.com/CityBaseInc/ex_ari_example/blob/master/lib/ex_ari_example/config.ex](https://github.com/CityBaseInc/ex_ari_example/blob/master/lib/ex_ari_example/config.ex)
  """

  @type field :: %{attribute: String.t(), value: String.t()}

  @callback aor(String.t()) :: %{name: String.t(), fields: [field()]}
  @callback endpoint(String.t(), String.t(), String.t()) :: %{name: String.t(), fields: [field()]}
  @callback identify(String.t()) :: %{name: String.t(), fields: [field()]}
  @callback pjsip_config() :: :ok
end
