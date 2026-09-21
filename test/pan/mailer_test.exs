defmodule Pan.MailerTest do
  use Pan.DataCase

  import Swoosh.Email
  import Swoosh.TestAssertions

  alias Pan.Repo
  alias PanWeb.Journal

  defmodule RefusingAdapter do
    use Swoosh.Adapter

    def deliver(_email, _config), do: {:error, {:permanent_failure, "relay said no"}}
  end

  defp email(from) do
    new(to: "someone@example.com", from: from, subject: "Hello", text_body: "Hi")
  end

  test "sets the bounce address as sender, leaving From alone" do
    assert {:ok, _} = Pan.Mailer.deliver(email("noreply@panoptikum.social"))

    assert_email_sent(fn sent ->
      sent.headers["Sender"] == "bounces@panoptikum.social" and
        sent.from == {"", "noreply@panoptikum.social"}
    end)
  end

  test "journals a refused mail and returns the error" do
    assert {:error, {:permanent_failure, _}} =
             Pan.Mailer.deliver(email("noreply@panoptikum.social"), adapter: RefusingAdapter)

    assert [entry] = Repo.all(Journal)
    assert entry.method == "deliver"
    assert entry.text =~ "someone@example.com"
    assert entry.after =~ "relay said no"
  end

  test "does not journal a refused error notification" do
    assert {:error, _} =
             Pan.Mailer.deliver(email("robot@informatom.com"), adapter: RefusingAdapter)

    assert Repo.all(Journal) == []
  end
end
