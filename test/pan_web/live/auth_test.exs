defmodule PanWeb.Live.AuthTest do
  use Pan.DataCase

  alias Pan.Repo
  alias PanWeb.Live.Auth
  alias PanWeb.User

  defp insert_user(attrs) do
    n = System.unique_integer([:positive])

    %User{name: "Test", username: "auth_#{n}", email: "auth_#{n}@example.com"}
    |> struct(attrs)
    |> Repo.insert!()
  end

  defp mount_admin(session), do: Auth.on_mount(:admin, %{}, session, %Phoenix.LiveView.Socket{})

  describe "on_mount(:admin, ...)" do
    test "lets a current admin in" do
      admin = insert_user(admin: true)

      assert {:cont, socket} = mount_admin(%{"user_id" => admin.id, "admin" => true})
      assert socket.assigns.current_user_id == admin.id
      assert socket.assigns.admin
    end

    test "rejects a user who is not an admin, whatever the session says" do
      user = insert_user(%{})

      assert {:halt, _} = mount_admin(%{"user_id" => user.id, "admin" => true})
      assert {:halt, _} = mount_admin(%{"user_id" => user.id, "admin" => false})
      assert {:halt, _} = mount_admin(%{"user_id" => user.id})
    end

    test "rejects an admin whose rights were revoked after login" do
      admin = insert_user(admin: true)
      Repo.update!(Ecto.Changeset.change(admin, admin: false))

      assert {:halt, _} = mount_admin(%{"user_id" => admin.id, "admin" => true})
    end

    test "rejects a deleted user and an empty session" do
      admin = insert_user(admin: true)
      Repo.delete!(admin)

      assert {:halt, _} = mount_admin(%{"user_id" => admin.id, "admin" => true})
      assert {:halt, _} = mount_admin(%{})
    end
  end
end
