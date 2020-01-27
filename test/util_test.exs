defmodule ARI.UtilTest do
  use ExUnit.Case, async: true

  require Logger

  alias ARI.Util

  @config [
    %{attribute: "identify_by", value: "ip"},
    %{attribute: "transport", value: "udp"},
    %{attribute: "dtmf_mode", value: "rfc4733"},
    %{attribute: "context", value: "ivr"},
    %{attribute: "disallow", value: "all"},
    %{attribute: "allow", value: "ulaw"},
    %{attribute: "direct_media", value: "false"},
    %{attribute: "force_rport", value: "true"},
    %{attribute: "rewrite_contact", value: "true"},
    %{attribute: "aors", value: "citybase-ivr"},
    %{attribute: "media_address", value: "127.0.0.1"}
  ]

  describe "Asterisk config diffs are properly recognized" do
    test "new fields are recognized" do
      assert Util.config_diff(%{}, @config) == @config
    end

    test "single attribute is diffed" do
      {missing, old_config} = List.pop_at(@config, Enum.random(0..(length(@config) - 1)))

      assert Util.config_diff(old_config, @config) == [missing]
    end

    test "no diff" do
      assert Util.config_diff(@config, @config) == []
    end
  end

  describe "cidr_to_netmask peoperly creates netmasks from cidrs" do
    test "cidrs to netmask" do
      assert Util.cidr_to_netmask("10.2.10.0/32") == "10.2.10.0/255.255.255.255"
      assert Util.cidr_to_netmask("192.168.15.12/24") == "192.168.15.12/255.255.255.0"
      assert Util.cidr_to_netmask("5.5.5.5/12") == "5.5.5.5/255.0.0.0"
      assert Util.cidr_to_netmask("0.0.0.0/0") == "0.0.0.0/0.0.0.0"
      assert Util.cidr_to_netmask("184.56.244.13/16") == "184.56.244.13/255.255.0.0"
    end
  end
end
