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

    %PanWeb.User{}
    |> PanWeb.User.registration_changeset(changes)
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

    %PanWeb.User{}
    |> PanWeb.User.changeset(changes)
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

    %PanWeb.User{}
    |> PanWeb.User.changeset(changes)
    |> Repo.insert!()
  end


  def insert_category(attrs \\ %{}) do
    changes = Map.merge(%{
      title: "Category Title",
      parent_id: nil
    }, attrs)

    %PanWeb.Category{}
    |> PanWeb.Category.changeset(changes)
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

    %PanWeb.Podcast{}
    |> PanWeb.Podcast.changeset(changes)
    |> Repo.insert!()
  end


  def insert_episode(attrs \\ %{}) do
    changes = Map.merge(%{title: "Episode Title",
                          link: "https://panoptikum.io",
                          publishing_date: ~N[2010-04-17 12:13:14]}, attrs)

    %PanWeb.Episode{}
    |> PanWeb.Episode.changeset(changes)
    |> Repo.insert!()
  end


  def insert_chapter(attrs \\ %{}) do
    changes = Map.merge(%{start: "01:02:03.456",
                          title: "Chatter title"}, attrs)

    %PanWeb.Chapter{}
    |> PanWeb.Chapter.changeset(changes)
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

    %PanWeb.Feed{}
    |> PanWeb.Feed.changeset(changes)
    |> Repo.insert!()
  end


  def insert_persona(attrs \\ %{}) do
    changes = Map.merge(%{pid: "persona pid",
                          name: "persona name",
                          uri: "persona uri"}, attrs)

    %PanWeb.Persona{}
    |> PanWeb.Persona.changeset(changes)
    |> Repo.insert!()
  end


  def insert_recommendation(attrs \\ %{}) do
    changes = Map.merge(%{pid: "persona pid",
                          name: "persona name",
                          uri: "persona uri"}, attrs)

    %PanWeb.Recommendation{comment: "recommendation comment text"}
    |> PanWeb.Recommendation.changeset(changes)
    |> Repo.insert!()
  end


  def assign_podcast_to_category(podcast, category) do
    podcast = Repo.preload(podcast, :categories)

    podcast
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:categories, podcast.categories ++ [category])
    |> Repo.update!
  end
end