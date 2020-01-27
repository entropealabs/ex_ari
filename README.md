# ARI

An Elixir Library for interfacing with [Asterisk](https://www.asterisk.org/) the Open Source Communications Software using [ARI](https://wiki.asterisk.org/wiki/pages/viewpage.action?pageId=29395573) the Asterisk REST Interface.

Documentation is available on [Hexdocs](https://citybase.hexdocs.pm/ex_ari)

An example application to get you started is available [here](https://github.com/citybaseinc/ex_ari_example). The example app also provides a lot of documentation on configuring Asterisk and setting up a local VOIP client.

This library has been tested against Asterisk version 15 and 16. The use of the `ARI.Router` module, which allows dynamic routing handled by your Elixir application, requires Asterisk 16 or above.

ARI provides a REST interface for controlling Asterisk resources as well as a WebSocket based event stream, for reacting to events. This library has full support for the REST interface as well as the WebSocket interface.

It's highly recommended that you read the full [ARI documentation](https://wiki.asterisk.org/wiki/pages/viewpage.action?pageId=29395573) to get a full understanding of the capabilities.

The end goal of this library is to be able to completely configure and control an Asterisk node, essentially making Asterisk a "dumb" VOIP/SIP frontend.

This library does not provide a supervisor by default, it is up to the user to decide what functionality is needed by their application. An example application that handles some basic functionality like audio playback and reacting to touch tone events might look something like this.

      defmodule ExARIExample.Application do
        use Application

        def start(_, _) do
          un = System.get_env("ASTERISK_USERNAME")
          pw = System.get_env("ASTERISK_PASSWORD")
          ws_host = System.get_env("ASTERISK_WS_HOST")
          rest_host = System.get_env("ASTERISK_REST_HOST")
          rest_port = System.get_env("ASTERISK_REST_PORT") |> String.to_integer()
          name = System.get_env("ASTERISK_NAME")
          transport = System.get_env("ASTERISK_TRANSPORT")
          context = System.get_env("ASTERISK_CONTEXT")
          channel_supervisor = ExARIExample.ChannelSupervisor

          children = [
            {DynamicSupervisor, strategy: :one_for_one, name: channel_supervisor},
            {ARI.ChannelRegistrar, []},
            {ARI.HTTP.Asterisk, [rest_host, rest_port, un, pw]},
            {ARI.HTTP.Channels, [rest_host, rest_port, un, pw]},
            {ARI.HTTP.Playbacks, [rest_host, rest_port, un, pw]},
            {ARI.Stasis, [channel_supervisor, %{
              name: "ex_ari", 
              module: ExARIExample.Client
            }, ws_host, un, pw]},
            {ARI.Stasis, [channel_supervisor, %{
              name: "router", 
              module: ARI.Router, 
              extensions: %{
                "ex_ari" => "ex_ari",
                "+15555550101" => "ex_ari"
              }
            }, ws_host, un, pw]},
            {ARI.Configurator, [name, transport, context, ExARIExample.Config]},
          ]

          opts = [strategy: :one_for_one, name: ExARIExample.Supervisor]
          Supervisor.start_link(children, opts)
        end
      end

The full example application is available [here](https://github.com/citybaseinc/ex_ari_example)

Be sure to read over the `ARI.Stasis` and the `ARI.Router` documentation

It may also be useful to review the [tests](https://github.com/CityBaseInc/ex_ari/tree/master/test), which implements a pseudo Asterisk WebSocket server for testing purposes.

Recording calls, transferring a call to another number and routing calls to their respective applications can be a bit tricky to manage with Asterisk. The `ex_ari` library provides some default [Stasis](https://wiki.asterisk.org/wiki/display/AST/Getting+Started+with+ARI) applications to help make that easier. `ARI.RecordCall`, `ARI.Transfer` and `ARI.Router`. When working on other complex workflows that involve joining multiple channels or snooping, these can be a good reference to refer to. These modules are all registered using an `ARI.Stasis` application like the `ARI.Router` registration in the application example above.

