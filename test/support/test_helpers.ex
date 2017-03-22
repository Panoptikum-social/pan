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


  def insert_podcaster(attrs \\ %{}) do
    changes = Map.merge(%{
      name: "Jane Podcaster",
      username: "jpodcaster" ,
      email: "jane.podcasterdoe@panoptikum.io",
      password: "supersecret",
      password_confirmation: "supersecret",
      admin: false,
      podcaster: true
    }, attrs)

    %Pan.User{}
    |> Pan.User.changeset(changes)
    |> Repo.insert!()
  end


  def insert_admin_user(attrs \\ %{}) do
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
    |> Pan.User.changeset(changes)
    |> Repo.insert!()
  end


  def insert_category(attrs \\ %{}) do
    changes = Map.merge(%{title: "Category Title"}, attrs)

    %Pan.Category{}
    |> Pan.Category.changeset(changes)
    |> Repo.insert!()
  end


  def insert_podcast(attrs \\ %{}) do
    changes = Map.merge(%{title: "Podcast Title",
                          website: "https://panoptikum.io",
                          last_build_date: ~N[2010-04-17 12:13:14]}, attrs)

    %Pan.Podcast{}
    |> Pan.Podcast.changeset(changes)
    |> Repo.insert!()
  end

  def insert_episode(attrs \\ %{}) do
    changes = Map.merge(%{title: "Episode Title",
                          link: "https://panoptikum.io",
                          publishing_date: ~N[2010-04-17 12:13:14]}, attrs)

    %Pan.Episode{}
    |> Pan.Episode.changeset(changes)
    |> Repo.insert!()
  end


  def insert_persona(attrs \\ %{}) do
    changes = Map.merge(%{pid: "persona pid",
                          name: "persona name",
                          uri: "persona uri"}, attrs)

    %Pan.Persona{}
    |> Pan.Persona.changeset(changes)
    |> Repo.insert!()
  end
end