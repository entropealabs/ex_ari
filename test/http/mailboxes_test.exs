defmodule ARI.HTTP.MailboxesTest do
  use ExUnit.Case, async: true

  require Logger

  alias ARI.HTTP.Mailboxes
  alias ARI.TestServer

  @username "username1"
  @password "password2"

  setup_all do
    host = "localhost"
    {:ok, {_server_ref, <<"http://localhost:", port::binary>>}} = TestServer.start()

    Mailboxes.start_link([host, String.to_integer(port), @username, @password])

    []
  end

  test "list" do
    resp = Mailboxes.list()
    assert resp.json.path == "mailboxes" && resp.json.id == []
  end

  test "get" do
    resp = Mailboxes.get("my-mailbox")
    assert resp.json.path == "mailboxes" && resp.json.id == ["my-mailbox"]
  end

  test "update" do
    resp = Mailboxes.update("my-mailbox", 100, 99)

    assert resp.json.path == "mailboxes" &&
             resp.json.id == ["my-mailbox"] &&
             resp.json.query_params.oldMessages == "100" &&
             resp.json.query_params.newMessages == "99"
  end

  test "delete" do
    resp = Mailboxes.delete("my-mailbox")
    assert resp.json.path == "mailboxes" && resp.json.id == ["my-mailbox"]
  end
end
