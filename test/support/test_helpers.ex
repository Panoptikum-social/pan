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
    changes = Map.merge(%{
      title: "Category Title",
      parent_id: nil
    }, attrs)

    %Pan.Category{}
    |> Pan.Category.changeset(changes)
    |> Repo.insert!()
  end


  def insert_podcast(attrs \\ %{}) do
    changes = Map.merge(%{
      title: "Podcast Title",
      website: "https://panoptikum.io",
      last_build_date: ~N[2010-04-17 12:13:14],
      update_intervall: 1,
      next_update: "2010-04-17 14:00:00"
    }, attrs)

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


  def insert_feed(attrs \\ %{}) do
    changes = Map.merge(%{feed_generator: "Feed generator",
      first_page_url: "https://panoptikum.io/feed/first_page",
      hub_link_url: "https://panoptikum.io/feed/hub_link",
      last_page_url: "https://panoptikum.io/feed/last_page",
      next_page_url: "https://panoptikum.io/feed/next_page",
      prev_page_url: "https://panoptikum.io/feed/prev_page",
      self_link_title: "Feed self link title",
      self_link_url: "https://panoptikum.io/feed/self_link"
    }, attrs)

    %Pan.Feed{}
    |> Pan.Feed.changeset(changes)
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