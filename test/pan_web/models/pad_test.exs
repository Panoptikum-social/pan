defmodule PanWeb.PadTest do
  use Pan.DataCase

  alias Pan.Repo
  alias PanWeb.{Category, Community, Follow, Moderation, Pad, PadSnapshot, User}

  doctest PanWeb.Pad

  defp insert_user do
    n = System.unique_integer([:positive])

    Repo.insert!(%User{name: "Test", username: "pad_#{n}", email: "pad_#{n}@example.com"})
  end

  defp insert_community do
    category = Repo.insert!(%Category{title: "Pad category #{System.unique_integer()}"})

    Repo.insert!(%Community{
      title: "Pad community",
      slug: "pad-community-#{category.id}",
      category_id: category.id
    })
  end

  describe "slugify/1" do
    test "spells out umlauts, drops accents and joins words with dashes" do
      assert Pad.slugify("Ärger über Öl & Spaß") == "aerger-ueber-oel-spass"
      assert Pad.slugify("Café crème, déjà vu") == "cafe-creme-deja-vu"
      assert Pad.slugify("--Meeting   notes 2026--") == "meeting-notes-2026"
    end

    test "keeps letters of non-Latin scripts" do
      assert Pad.slugify("Заметки встречи") == "заметки-встречи"
    end
  end

  describe "changeset/2" do
    test "sets the slug from the trimmed title" do
      changeset = Pad.changeset(%Pad{}, %{"title" => "  Meeting notes  "})

      assert changeset.valid?
      assert get_change(changeset, :title) == "Meeting notes"
      assert get_change(changeset, :slug) == "meeting-notes"
    end

    test "rejects a title without letters or digits" do
      refute Pad.changeset(%Pad{}, %{"title" => "?!"}).valid?
    end
  end

  test "titles with the same slug clash within a community, not across communities" do
    community = insert_community()

    assert {:ok, _} = Pad.create(community.id, %{"title" => "Meeting notes"})
    assert {:error, changeset} = Pad.create(community.id, %{"title" => "meeting NOTES!"})
    assert %{title: [_]} = errors_on(changeset)

    assert {:ok, _} = Pad.create(insert_community().id, %{"title" => "Meeting notes"})
  end

  describe "permissions/2" do
    test "followers read, followers who moderate also manage, moderating alone gives nothing" do
      community = insert_community()
      follower = insert_user()
      moderator = insert_user()
      moderator_not_following = insert_user()

      for user <- [follower, moderator] do
        Repo.insert!(%Follow{follower_id: user.id, community_id: community.id})
      end

      for user <- [moderator, moderator_not_following] do
        Repo.insert!(%Moderation{user_id: user.id, community_id: community.id})
      end

      assert Pad.permissions(follower.id, community.id) == %{read: true, manage: false}
      assert Pad.permissions(moderator.id, community.id) == %{read: true, manage: true}

      assert Pad.permissions(moderator_not_following.id, community.id) ==
               %{read: false, manage: false}

      assert Pad.permissions(insert_user().id, community.id) == %{read: false, manage: false}
      assert Pad.permissions(nil, community.id) == %{read: false, manage: false}
    end
  end

  describe "deleting" do
    test "a community deletes its pads and their snapshots" do
      community = insert_community()
      {:ok, pad} = Pad.create(community.id, %{"title" => "Notes"})
      snapshot = Repo.insert!(%PadSnapshot{pad_id: pad.id, markdown: "# Notes"})

      Repo.delete!(community)

      refute Repo.get(Pad, pad.id)
      refute Repo.get(PadSnapshot, snapshot.id)
    end

    test "a user keeps their saved versions, without author" do
      user = insert_user()
      {:ok, pad} = Pad.create(insert_community().id, %{"title" => "Notes"})
      snapshot = Repo.insert!(%PadSnapshot{pad_id: pad.id, markdown: "x", user_id: user.id})

      Repo.delete!(user)

      assert %PadSnapshot{user_id: nil} = Repo.get(PadSnapshot, snapshot.id)
    end
  end
end
