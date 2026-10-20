defmodule PanWeb.PadChannelTest do
  use PanWeb.ChannelCase

  alias Pan.Repo

  alias PanWeb.{
    Category,
    Community,
    Follow,
    Moderation,
    Pad,
    PadChannel,
    PadServer,
    PadSnapshot,
    User,
    UserSocket
  }

  alias Yex.Sync

  defp insert_user do
    n = System.unique_integer([:positive])
    Repo.insert!(%User{name: "Test", username: "padch_#{n}", email: "padch_#{n}@example.com"})
  end

  setup do
    category = Repo.insert!(%Category{title: "Pad channel category #{System.unique_integer()}"})
    community = Repo.insert!(%Community{title: "Pad channel community", category_id: category.id})
    {:ok, pad} = Pad.create(community.id, %{"title" => "Notes"})

    follower = insert_user()
    Repo.insert!(%Follow{follower_id: follower.id, community_id: community.id})

    %{community: community, pad: pad, follower: follower}
  end

  # a browser: its own Yjs document, joined to the pad's channel
  defp join_pad(user, pad) do
    {:ok, reply, socket} =
      UserSocket
      |> socket(nil, %{user_id: user.id})
      |> subscribe_and_join(PadChannel, "pad:#{pad.id}")

    {reply, socket}
  end

  defp sync_step1(doc) do
    {:ok, step1} = Sync.get_sync_step1(doc)
    Sync.message_encode!({:sync, step1})
  end

  defp edit(doc, text) do
    {:ok, before} = Yex.encode_state_vector(doc)
    doc |> Yex.Doc.get_text(PadServer.text_name()) |> Yex.Text.insert(0, text)
    {:ok, update} = Yex.encode_state_as_update(doc, before)
    Sync.message_encode!({:sync, {:sync_update, update}})
  end

  # the answer to a sync step 1 is the server's own step 1 and step 2, in
  # no fixed order; step 2 carries the document
  defp receive_step2 do
    assert_push("yjs", {:binary, message})

    case Sync.message_decode!(message) do
      {:sync, {:sync_step2, diff}} -> diff
      _other -> receive_step2()
    end
  end

  # the next document update, skipping what is left of the initial sync
  defp receive_update do
    assert_push("yjs", {:binary, message})

    case Sync.message_decode!(message) do
      {:sync, {:sync_update, update}} -> update
      _other -> receive_update()
    end
  end

  defp text(doc), do: doc |> Yex.Doc.get_text(PadServer.text_name()) |> Yex.Text.to_string()

  # leaves the channels first, so the pad process doesn't get restarted, then
  # stops it, which saves the pad
  defp close_all(sockets, pad) do
    for socket <- sockets do
      Process.unlink(socket.channel_pid)
      close(socket)
    end

    server = PadServer.whereis(pad.id)
    if server, do: DynamicSupervisor.terminate_child(Pan.PadSupervisor, server)
  end

  describe "connecting" do
    test "needs a valid token", %{follower: follower} do
      assert {:ok, _socket} =
               connect(UserSocket, %{"token" => UserSocket.sign_token(follower.id)})

      assert :error = connect(UserSocket, %{"token" => "forged"})
      assert :error = connect(UserSocket, %{})
    end
  end

  describe "joining" do
    test "is refused for non-followers, moderators who don't follow and missing pads",
         %{community: community, pad: pad} do
      moderator = insert_user()
      Repo.insert!(%Moderation{user_id: moderator.id, community_id: community.id})

      for user <- [insert_user(), moderator] do
        assert {:error, %{reason: "not found"}} =
                 UserSocket
                 |> socket(nil, %{user_id: user.id})
                 |> subscribe_and_join(PadChannel, "pad:#{pad.id}")
      end

      assert {:error, _} =
               UserSocket
               |> socket(nil, %{user_id: insert_user().id})
               |> subscribe_and_join(PadChannel, "pad:0")
    end

    test "tells a follower whether the pad is read only", %{pad: pad, follower: follower} do
      {reply, socket} = join_pad(follower, pad)
      assert reply == %{read_only: false}
      close_all([socket], pad)
    end
  end

  test "an edit in one browser reaches the other, and is saved", %{pad: pad, follower: follower} do
    {_reply, socket_a} = join_pad(follower, pad)
    {_reply, socket_b} = join_pad(follower, pad)
    doc_b = Yex.Doc.new()

    push(socket_a, "yjs", {:binary, edit(Yex.Doc.new(), "# Hello pad")})

    assert_push("yjs", {:binary, message})
    {:ok, {:sync, {:sync_update, update}}} = Sync.message_decode(message)
    :ok = Yex.apply_update(doc_b, update)
    assert text(doc_b) == "# Hello pad"

    close_all([socket_a, socket_b], pad)

    saved = Repo.get!(Pad, pad.id)
    assert saved.markdown == "# Hello pad"
    assert saved.yjs_state
  end

  test "the rendered preview reaches every browser", %{pad: pad, follower: follower} do
    {_reply, socket_a} = join_pad(follower, pad)
    {_reply, socket_b} = join_pad(follower, pad)
    # on joining, of the still empty pad
    assert_push("preview", %{html: ""})
    assert_push("preview", %{html: ""})

    push(socket_a, "yjs", {:binary, edit(Yex.Doc.new(), "# Hello pad")})
    # rendered 300 ms after the edit
    assert_push("preview", %{html: html}, 1000)
    # with source positions, for the selection highlight
    assert html =~ ~s(<h1 data-sourcepos="1:1-1:11">Hello pad</h1>)
    assert_push("preview", %{html: ^html})

    # a browser joining now gets the current text, not the last save
    {_reply, socket_c} = join_pad(follower, pad)
    assert_push("preview", %{html: ^html})

    close_all([socket_a, socket_b, socket_c], pad)
  end

  test "the last one leaving takes a snapshot, unless the text is unchanged",
       %{pad: pad, follower: follower} do
    {_reply, socket} = join_pad(follower, pad)
    push(socket, "yjs", {:binary, edit(Yex.Doc.new(), "Version one")})
    push(socket, "yjs_sync", {:binary, sync_step1(Yex.Doc.new())})
    receive_step2()
    server = PadServer.whereis(pad.id)

    Process.unlink(socket.channel_pid)
    close(socket)
    # the pad process has handled the channel's going away
    :sys.get_state(server)
    assert [%{markdown: "Version one", user_id: nil, note: nil}] = Repo.all(PadSnapshot)

    {_reply, socket} = join_pad(follower, pad)
    Process.unlink(socket.channel_pid)
    close(socket)
    :sys.get_state(server)
    assert Repo.aggregate(PadSnapshot, :count) == 1

    close_all([], pad)
  end

  test "a restore reaches the open editors", %{pad: pad, follower: follower} do
    {_reply, socket} = join_pad(follower, pad)
    doc = Yex.Doc.new()
    push(socket, "yjs_sync", {:binary, sync_step1(doc)})
    :ok = Yex.apply_update(doc, receive_step2())

    # the preview on joining, of the still empty pad
    assert_push("preview", %{html: ""})
    :ok = PadServer.restore(pad.id, "Restored text")

    :ok = Yex.apply_update(doc, receive_update())
    assert text(doc) == "Restored text"
    assert_push("preview", %{html: html}, 1000)
    assert html =~ "Restored text"

    close_all([socket], pad)
  end

  test "a browser joining later gets the saved text", %{pad: pad, follower: follower} do
    {_reply, socket} = join_pad(follower, pad)
    push(socket, "yjs", {:binary, edit(Yex.Doc.new(), "Kept")})
    # the answer to a sync step 1 shows that the update has been applied
    push(socket, "yjs_sync", {:binary, sync_step1(Yex.Doc.new())})
    receive_step2()
    close_all([socket], pad)
    refute PadServer.whereis(pad.id)

    {_reply, socket} = join_pad(follower, pad)
    doc = Yex.Doc.new()
    push(socket, "yjs_sync", {:binary, sync_step1(doc)})
    :ok = Yex.apply_update(doc, receive_step2())
    assert text(doc) == "Kept"

    close_all([socket], pad)
  end

  test "a read only pad drops edits but tells the browsers", %{pad: pad, follower: follower} do
    {_reply, socket_a} = join_pad(follower, pad)
    {_reply, socket_b} = join_pad(follower, pad)

    pad = pad |> Pad.read_only_changeset(true) |> Repo.update!()
    PadChannel.broadcast_read_only(pad)
    assert_push("read_only", %{read_only: true})
    assert_push("read_only", %{read_only: true})

    push(socket_a, "yjs", {:binary, edit(Yex.Doc.new(), "Not allowed")})
    refute_push("yjs", _, 200)

    close_all([socket_a, socket_b], pad)
    assert Repo.get!(Pad, pad.id).markdown == ""
  end

  test "deleting the pad closes the open editors", %{pad: pad, follower: follower} do
    {_reply, socket} = join_pad(follower, pad)
    Process.unlink(socket.channel_pid)
    ref = Process.monitor(socket.channel_pid)

    Repo.delete!(pad)
    PadChannel.broadcast_deleted(pad)

    assert_push("deleted", %{})
    assert_receive {:DOWN, ^ref, :process, _pid, :normal}
    close_all([], pad)
  end
end
