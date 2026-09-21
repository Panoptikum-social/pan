defmodule PanWeb.UserRetentionTest do
  use Pan.DataCase

  alias Pan.Repo
  alias PanWeb.User

  defp days_ago(days), do: NaiveDateTime.add(Pan.Parser.MyDateTime.now(), -days, :day)

  defp insert_user(attrs) do
    n = System.unique_integer([:positive])

    %User{name: "Test", username: "retention_#{n}", email: "retention_#{n}@example.com"}
    |> struct(attrs)
    |> Repo.insert!()
  end

  defp usernames(filter) do
    filter |> User.retention_users(:id, :asc, 100, 0) |> Enum.map(& &1.username)
  end

  describe "filters" do
    test "select the groups of the retention policy" do
      unverified = insert_user(email_verified: false)
      never = insert_user(email_verified: true)
      active = insert_user(email_verified: true, last_login_at: days_ago(10))
      inactive = insert_user(email_verified: true, last_login_at: days_ago(800))
      marked = insert_user(marked_for_deletion_at: days_ago(5))
      deletable = insert_user(marked_for_deletion_at: days_ago(40))

      assert unverified.username in usernames(:unverified)
      refute never.username in usernames(:unverified)

      assert never.username in usernames(:never_logged_in)
      refute active.username in usernames(:never_logged_in)

      assert usernames(:inactive) == [inactive.username]

      assert marked.username in usernames(:marked)
      assert deletable.username in usernames(:marked)

      assert usernames(:deletable) == [deletable.username]
    end

    test "never list admins or moderators" do
      admin = insert_user(admin: true)
      moderator = insert_user(moderator: true)
      regular = insert_user(%{})

      for filter <- User.retention_filters() do
        refute admin.username in usernames(filter)
        refute moderator.username in usernames(filter)
      end

      assert regular.username in usernames(:all)
      assert User.count_retention_users(:all) == 1
    end
  end

  describe "mark_for_deletion/1 and unmark_for_deletion/1" do
    test "mark regular users only and keep an existing mark date" do
      regular = insert_user(%{})
      admin = insert_user(admin: true)
      already = insert_user(marked_for_deletion_at: days_ago(20))

      assert User.mark_for_deletion([regular.id, admin.id, already.id]) == 1

      assert Repo.get!(User, regular.id).marked_for_deletion_at
      refute Repo.get!(User, admin.id).marked_for_deletion_at

      assert NaiveDateTime.diff(Repo.get!(User, already.id).marked_for_deletion_at, days_ago(20)) ==
               0
    end

    test "unmark clears the mark" do
      user = insert_user(marked_for_deletion_at: days_ago(3))

      assert User.unmark_for_deletion([user.id]) == 1
      refute Repo.get!(User, user.id).marked_for_deletion_at
    end
  end

  describe "delete_deletable/1" do
    test "deletes only users marked for longer than the grace period" do
      deletable = insert_user(marked_for_deletion_at: days_ago(40))
      too_recent = insert_user(marked_for_deletion_at: days_ago(5))
      unmarked = insert_user(%{})
      admin = insert_user(admin: true, marked_for_deletion_at: days_ago(40))

      ids = Enum.map([deletable, too_recent, unmarked, admin], & &1.id)

      assert User.delete_deletable(ids) == 1

      refute Repo.get(User, deletable.id)
      assert Repo.get(User, too_recent.id)
      assert Repo.get(User, unmarked.id)
      assert Repo.get(User, admin.id)
    end
  end
end
