defmodule Pan.UserTest do
  use Pan.ModelCase

  alias PanWeb.User

  @valid_attrs %{
    name: "John Doe",
    username: "jdoe",
    email: "john.doe@panoptikum.io",
    password: "supersecret",
    password_confirmation: "supersecret",
    admin: false,
    podcaster: false
  }

  describe "changeset" do
    test "is valid with valid attributes" do
      changeset = User.changeset(%User{}, @valid_attrs)
      assert changeset.valid?
    end

    test "is invalid without one of the required attributes" do
      name_attrs = Map.delete(@valid_attrs, :name)
      name_changeset = User.changeset(%User{}, name_attrs)
      refute name_changeset.valid?

      username_attrs = Map.delete(@valid_attrs, :username)
      username_changeset = User.changeset(%User{}, username_attrs)
      refute username_changeset.valid?

      email_attrs = Map.delete(@valid_attrs, :email)
      email_changeset = User.changeset(%User{}, email_attrs)
      refute email_changeset.valid?
    end

    test "is invalid with empty attributes" do
      changeset = User.changeset(%User{}, %{})
      refute changeset.valid?
    end
  end

  describe "self_change_changeset" do
    test "is valid with valid attributes" do
      self_change_changeset = User.self_change_changeset(%User{}, @valid_attrs)
      assert self_change_changeset.valid?
    end

    test "is invalid without one of the required attributes" do
      name_attrs = Map.delete(@valid_attrs, :name)
      name_changeset = User.self_change_changeset(%User{}, name_attrs)
      refute name_changeset.valid?

      username_attrs = Map.delete(@valid_attrs, :username)
      username_changeset = User.self_change_changeset(%User{}, username_attrs)
      refute username_changeset.valid?

      email_attrs = Map.delete(@valid_attrs, :email)
      email_changeset = User.self_change_changeset(%User{}, email_attrs)
      refute email_changeset.valid?
    end

    test "is invalid with empty attributes" do
      self_change_changeset = User.self_change_changeset(%User{}, %{})
      refute self_change_changeset.valid?
    end
  end

  describe "password_update_changeset" do
    test "is valid with valid attributes" do
      attrs = %{
        password: "supersecret",
        password_confirmation: "supersecret"
      }

      password_update_changeset = User.password_update_changeset(%User{}, attrs)
      assert password_update_changeset.valid?
    end

    test "is invalid with empty attributes" do
      password_update_changeset = User.password_update_changeset(%User{}, %{})
      refute password_update_changeset.valid?
    end

    test "is invalid with password length out of range 6..100" do
      long =
        "cupcake_ipsum_dolor_sit_amet_icing_chupa_chups_pie_carrot_cake_icing_gummies_pudding_chocolatebars_cocoa"

      long_attrs = %{password: long, password_confirmation: long}
      long_changeset = User.password_update_changeset(%User{}, long_attrs)
      refute long_changeset.valid?

      short_attrs = %{password: "sw0rd", password_confirmation: "sw0rd"}
      short_changeset = User.password_update_changeset(%User{}, short_attrs)
      refute short_changeset.valid?
    end

    test "is invalid with non matching password_confirmation" do
      attrs = %{password: "$w0rdf1$h", password_confirmation: "swordfish"}
      long_changeset = User.password_update_changeset(%User{}, attrs)
      refute long_changeset.valid?
    end
  end

  describe "request_login_changeset" do
    test "is valid with valid attributes" do
      request_login_changeset =
        User.request_login_changeset(%User{}, %{email: @valid_attrs.email})

      assert request_login_changeset.valid?
    end

    test "is invalid with empty attributes" do
      request_login_changeset = User.request_login_changeset(%User{}, %{})
      refute request_login_changeset.valid?
    end

    test "is invalid with email length out of range 3..100" do
      long =
        "cupcake_ipsum_dolor_sit_amet_icing_chupa_chups_pie_carrot_cake_icing_gummies_pudding@nonexistingsprovider.com"

      long_changeset = User.request_login_changeset(%User{}, %{email: long})
      refute long_changeset.valid?

      short_changeset = User.request_login_changeset(%User{}, %{email: "ab"})
      refute short_changeset.valid?
    end
  end

  describe "put_pass_hash" do
    test "does nothing when given an invalid changeset" do
      attrs = %{
        password: "supersecret",
        password_confirmation: "something else"
      }

      password_update_changeset = User.password_update_changeset(%User{}, attrs)
      assert is_nil(password_update_changeset.changes[:password_hash])
    end

    test "hashes password and puts it into password_hash in changeset" do
      attrs = %{
        password: "supersecret",
        password_confirmation: "supersecret"
      }

      password_update_changeset = User.password_update_changeset(%User{}, attrs)
      assert String.length(password_update_changeset.changes[:password_hash]) > 0
    end
  end
end
