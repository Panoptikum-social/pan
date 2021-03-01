defmodule PanWeb.Persona do
  use PanWeb, :model
  alias Pan.Repo

  alias PanWeb.{
    Engagement,
    Episode,
    Follow,
    Gig,
    Image,
    Like,
    Manifestation,
    Persona,
    Podcast,
    User
  }

  schema "personas" do
    field(:pid, :string)
    field(:name, :string)
    field(:uri, :string)
    field(:email, :string)
    field(:description, :string)
    field(:long_description, :string)
    field(:image_url, :string)
    field(:image_title, :string)
    field(:elastic, :boolean)
    field(:thumbnailed, :boolean)
    field(:fediverse_address, :string)

    belongs_to(:redirect, Persona)
    belongs_to(:user, User)
    has_many(:engagements, Engagement)
    has_many(:gigs, Gig)
    has_many(:thumbnails, Image, on_delete: :delete_all)

    many_to_many(:delegates, Persona,
      join_through: "delegations",
      join_keys: [persona_id: :id, delegate_id: :id]
    )

    many_to_many(:podcasts, Podcast,
      join_through: "engagements",
      on_delete: :delete_all
    )

    many_to_many(:episodes, Episode,
      join_through: "gigs",
      on_delete: :delete_all
    )

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :pid,
      :name,
      :uri,
      :email,
      :description,
      :image_url,
      :image_title,
      :redirect_id,
      :long_description,
      :user_id,
      :elastic,
      :thumbnailed,
      :fediverse_address
    ])
    |> validate_required([:pid, :name, :uri])
    |> unique_constraint(:pid)
  end

  def pro_user_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :pid,
      :name,
      :uri,
      :email,
      :description,
      :image_url,
      :image_title,
      :long_description,
      :fediverse_address
    ])
    |> validate_required([:pid, :name, :uri])
    |> unique_constraint(:pid)
    |> unique_constraint(:uri)
  end

  def user_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :uri])
    |> validate_required([:pid, :name, :uri])
    |> unique_constraint(:pid)
    |> unique_constraint(:uri)
  end

  def claiming_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :email])
  end

  def like(persona_id, current_user_id) do
    case Repo.get_by(Like,
           enjoyer_id: current_user_id,
           persona_id: persona_id
         ) do
      nil ->
        %Like{enjoyer_id: current_user_id, persona_id: persona_id}
        |> Repo.insert()

      like ->
        {:ok, Repo.delete!(like)}
    end
  end

  def follow(persona_id, current_user_id) do
    case Repo.get_by(Follow,
           follower_id: current_user_id,
           persona_id: persona_id
         ) do
      nil ->
        %Follow{follower_id: current_user_id, persona_id: persona_id}
        |> Repo.insert()

      follow ->
        {:ok, Repo.delete!(follow)}
    end
  end

  def follower_mailboxes(user_id) do
    Repo.all(
      from(l in Follow,
        where: l.user_id == ^user_id,
        select: [:follower_id]
      )
    )
    |> Enum.map(fn user -> "mailboxes:" <> Integer.to_string(user.follower_id) end)
  end

  def likes(id) do
    from(l in Like, where: l.persona_id == ^id)
    |> Repo.aggregate(:count)
    |> Integer.to_string()
  end

  def follows(id) do
    from(f in Follow, where: f.persona_id == ^id)
    |> Repo.aggregate(:count)
    |> Integer.to_string()
  end

  def update_search_index(id) do
    persona = Repo.get(Persona, id)

    if persona.redirect_id do
      delete(
        "http://localhost:9200/panoptikum_" <>
          Application.get_env(:pan, :environment) <>
          "/personas/" <> Integer.to_string(id)
      )

      # fallback, in case Tirexs brakes again:
      # url = "http://localhost:9200/panoptikum_" <> Application.get_env(:pan, :environment) <> "/personas/" <> Integer.to_string(id)
      # :httpc.request(:delete, {to_charlist(url), [],'application/json', ""}, [], [])
    else
      put(
        "/panoptikum_" <>
          Application.get_env(:pan, :environment) <> "/personas/" <> Integer.to_string(id),
        name: persona.name,
        pid: persona.pid,
        uri: persona.uri,
        description: persona.description,
        long_description: persona.long_description,
        image_url: persona.image_url,
        image_title: persona.image_title,
        url: persona_frontend_path(PanWeb.Endpoint, :show, id)
      )
    end
  end

  def update_search_all() do
    persona_ids = Repo.all(from(p in Persona, select: p.id))

    for persona_id <- persona_ids do
      update_search_index(persona_id)
    end
  end

  def delete_search_index(id) do
    delete(
      "http://127.0.0.1:9200/panoptikum_" <>
        Application.get_env(:pan, :environment) <>
        "/personas/" <> Integer.to_string(id)
    )
  end

  def delete_search_index_orphans() do
    persona_ids =
      from(c in Persona, select: c.id)
      |> Repo.all()

    max_persona_id = Enum.max(persona_ids)
    all_ids = Range.new(1, max_persona_id) |> Enum.to_list()
    deleted_ids = all_ids -- persona_ids

    for deleted_id <- deleted_ids, do: delete_search_index(deleted_id)
  end

  def create_user_persona(user) do
    if user.podcaster and Enum.empty?(user.user_personas) do
      case Repo.one(from(p in Persona, where: p.email == ^user.email)) do
        nil ->
          pid = UUID.uuid5(:url, Integer.to_string(user.id) <> user.username)

          {:ok, persona} =
            %Persona{user_id: user.id, pid: pid, name: user.name, email: user.email}
            |> Repo.insert()

          %Manifestation{persona_id: persona.id, user_id: user.id}
          |> Repo.insert()

        persona ->
          persona
          |> PanWeb.Persona.changeset(%{user_id: user.id})
          |> Repo.update()

          {:ok, persona}
      end
    end
  end

  def cache_missing_thumbnail_images() do
    persona_ids =
      from(p in Persona,
        where:
            not p.thumbnailed and
            not is_nil(p.image_url),
        limit: 250,
        select: p.id
      )
      |> Repo.all()

    personas =
      from(p in Persona, where: p.id in ^persona_ids)
      |> Repo.all()

    for persona <- personas, do: Persona.cache_thumbnail_image(persona)

    from(e in Persona, where: e.id in ^persona_ids)
    |> Repo.update_all(set: [thumbnailed: true])
  end

  def cache_thumbnail_image(persona) do
    with {:error, _} <- Image.download_thumbnail("persona", persona.id, persona.image_url) do
      Persona.clear_image_url(persona)
    end
  end

  def clear_image_url(persona) do
    persona
    |> Persona.changeset(%{image_url: nil, uri: persona.uri || persona.pid})
    |> Repo.update()
  end
end
