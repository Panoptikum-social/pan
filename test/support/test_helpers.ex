defmodule Pan.TestHelpers do
  alias Pan.Repo

  def insert_user(attrs \\ %{}) do
    changes = Map.merge(%{
      name: "John Doe",
      username: "jdoe" ,
      email: "john.doe@panoptikum.io",
      password: "supersecret",
      password_confirmation: "supersecret",
      admin: false,
      podcaster: false
    }, attrs)

    %Pan.User{}
    |> Pan.User.registration_changeset(changes)
    |> Repo.insert!()
  end


  def insert_admin(attrs \\ %{}) do
    changes = Map.merge(%{
      name: "Jane Admin",
      username: "jadmin" ,
      email: "jane.admin@panoptikum.io",
      password: "supersecret",
      password_confirmation: "supersecret",
      admin: true,
      podcaster: false
    }, attrs)

    %Pan.User{}
    |> Pan.User.registration_changeset(changes)
    |> Repo.insert!()
  end


  def insert_category(attrs \\ %{}) do
    changes = Map.merge(%{title: "Category Title"}, attrs)

    %Pan.Category{}
    |> Pan.Category.changeset(changes)
    |> Repo.insert!()
  end
end