defmodule PanWeb.UserRetentionTest do
  use Pan.DataCase

  import Swoosh.TestAssertions

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

      assert unverified.username in usernames([:unverified])
      refute never.username in usernames([:unverified])

      assert never.username in usernames([:never_logged_in])
      refute active.username in usernames([:never_logged_in])

      assert usernames([:inactive]) == [inactive.username]

      assert marked.username in usernames([:marked])
      assert deletable.username in usernames([:marked])

      assert usernames([:deletable]) == [deletable.username]
    end

    test "never list admins or moderators" do
      admin = insert_user(admin: true)
      moderator = insert_user(moderator: true)
      regular = insert_user(%{})

      for filter <- User.retention_filters() do
        refute admin.username in usernames([filter])
        refute moderator.username in usernames([filter])
      end

      assert usernames([]) == [regular.username]
      assert User.count_retention_users([]) == 1
    end

    test "combine, every further filter restricts the result more" do
      unverified_marked = insert_user(email_verified: false, marked_for_deletion_at: days_ago(5))
      unverified = insert_user(email_verified: false)
      verified_marked = insert_user(email_verified: true, marked_for_deletion_at: days_ago(5))
      deletable = insert_user(email_verified: false, marked_for_deletion_at: days_ago(40))

      assert User.count_retention_users([]) == 4
      assert User.count_retention_users([:unverified]) == 3
      assert usernames([:unverified, :marked]) == [unverified_marked.username, deletable.username]
      assert usernames([:unverified, :deletable]) == [deletable.username]
      assert usernames([:marked, :deletable]) == [deletable.username]

      assert unverified.username in usernames([:unverified])
      refute unverified.username in usernames([:unverified, :marked])
      refute verified_marked.username in usernames([:unverified, :marked])
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

  describe "send_retention_notices/1" do
    defmodule RefusingAdapter do
      use Swoosh.Adapter

      def deliver(_email, _config), do: {:error, :refused}
    end

    test "mails a notice with the reasons and a login link, then marks the user" do
      inactive_unverified = insert_user(email_verified: false, last_login_at: days_ago(900))

      assert %{sent: 1, failed: 0} = User.send_retention_notices([inactive_unverified.id])

      assert_email_sent(fn email ->
        email.to == [{"", inactive_unverified.email}] and
          email.html_body =~ "logged in for more than two years" and
          email.html_body =~ "not verified your email address" and
          email.html_body =~ "/sessions/login_via_notice?token="
      end)

      assert Repo.get!(User, inactive_unverified.id).marked_for_deletion_at
    end

    test "names only the reasons that apply" do
      unverified = insert_user(email_verified: false)
      inactive = insert_user(email_verified: true, last_login_at: days_ago(900))

      User.send_retention_notices([unverified.id, inactive.id])

      assert_email_sent(fn email ->
        email.to == [{"", unverified.email}] and
          email.html_body =~ "not verified your email address" and
          not (email.html_body =~ "logged in for more than two years")
      end)

      assert_email_sent(fn email ->
        email.to == [{"", inactive.email}] and
          email.html_body =~ "logged in for more than two years" and
          not (email.html_body =~ "not verified your email address")
      end)
    end

    test "keeps an existing mark date, and skips admins" do
      marked_at = days_ago(20)
      marked = insert_user(marked_for_deletion_at: marked_at)
      admin = insert_user(admin: true)

      assert %{sent: 1} = User.send_retention_notices([marked.id, admin.id])

      assert NaiveDateTime.diff(Repo.get!(User, marked.id).marked_for_deletion_at, marked_at) == 0
      refute Repo.get!(User, admin.id).marked_for_deletion_at
      assert_email_sent(fn email -> email.to == [{"", marked.email}] end)
      refute_email_sent()
    end

    test "does not mark a user whose notice could not be sent" do
      user = insert_user(%{})
      original = Application.get_env(:pan, Pan.Mailer)
      Application.put_env(:pan, Pan.Mailer, adapter: RefusingAdapter)
      on_exit(fn -> Application.put_env(:pan, Pan.Mailer, original) end)

      assert %{sent: 0, failed: 1} = User.send_retention_notices([user.id])
      refute Repo.get!(User, user.id).marked_for_deletion_at
    end
  end
end
