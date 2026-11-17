defmodule PanWeb.UserEmailTest do
  use Pan.DataCase, async: true

  alias PanWeb.User

  @params %{
    "name" => "Test User",
    "username" => "test_user",
    "email" => " \tsomeone@example.com\r\n",
    "password" => "a-long-enough-password",
    "password_confirmation" => "a-long-enough-password",
    "bot_check" => "42"
  }

  test "registration_changeset trims whitespace around the email" do
    changeset = User.registration_changeset(%User{}, @params)
    assert changeset.valid?
    assert changeset.changes.email == "someone@example.com"
  end

  test "changeset trims whitespace around the email" do
    changeset = User.changeset(%User{}, @params)
    assert changeset.changes.email == "someone@example.com"
  end

  test "self_change_changeset trims whitespace around the email" do
    changeset = User.self_change_changeset(%User{}, @params)
    assert changeset.changes.email == "someone@example.com"
  end

  test "request_login_changeset trims whitespace around the email" do
    changeset = User.request_login_changeset(%User{}, @params)
    assert changeset.changes.email == "someone@example.com"
  end

  test "an email of only whitespace is still rejected as missing" do
    changeset = User.registration_changeset(%User{}, %{@params | "email" => "   "})
    refute changeset.valid?
    assert Keyword.has_key?(changeset.errors, :email)
  end

  # gen_smtp's parser raises on these instead of returning an error (#634)
  for email <- ["someone@example.com Foo", "someone@example.com Foo&"] do
    test "#{inspect(email)} is rejected as invalid, not a crash" do
      for changeset_fun <- [
            &User.registration_changeset/2,
            &User.changeset/2,
            &User.self_change_changeset/2
          ] do
        changeset = changeset_fun.(%User{}, %{@params | "email" => unquote(email)})
        refute changeset.valid?
        assert {"is not a valid email address", _} = changeset.errors[:email]
      end
    end
  end
end
