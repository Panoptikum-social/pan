defmodule PanWeb.OpmlControllerTest do
  use PanWeb.ConnCase

  alias Pan.Repo
  alias PanWeb.{Opml, User}

  defp logged_in_admin(conn) do
    n = System.unique_integer([:positive])

    admin =
      Repo.insert!(%User{
        name: "Admin",
        username: "opml_#{n}",
        email: "opml_#{n}@example.com",
        admin: true
      })

    init_test_session(conn, %{"user_id" => admin.id, "admin" => true})
  end

  test "an upload without a user is a form error, not a crash", %{conn: conn} do
    file =
      Path.join(System.tmp_dir!(), "pan_opml_test_#{System.unique_integer([:positive])}.opml")

    File.write!(file, ~s(<?xml version="1.0"?><opml version="2.0"><body/></opml>))
    upload = %Plug.Upload{path: file, filename: "test.opml", content_type: "text/x-opml"}
    count = Repo.aggregate(Opml, :count)

    conn =
      post(logged_in_admin(conn), "/admin/opmls", %{
        "opml" => %{"file" => upload, "user_id" => ""}
      })

    assert html_response(conn, 200) =~ "can&#39;t be blank"
    assert Repo.aggregate(Opml, :count) == count
  end
end
