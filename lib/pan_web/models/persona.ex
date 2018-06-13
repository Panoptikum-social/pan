defmodule PanWeb.Persona do
  use Pan.Web, :model
  alias Pan.Repo
  alias PanWeb.{Engagement, Episode, Follow, Gig, Image, Like, Manifestation, Persona,
                Podcast, User}
  import Mogrify

  schema "personas" do
    field :pid, :string
    field :name, :string
    field :uri, :string
    field :email, :string
    field :description, :string
    field :long_description, :string
    field :image_url, :string
    field :image_title, :string
    field :elastic, :boolean

    belongs_to :redirect, Persona
    belongs_to :user, User
    has_many :engagements, Engagement
    has_many :gigs, Gig

    many_to_many :delegates, Persona,
                             join_through: "delegations",
                             join_keys: [persona_id: :id, delegate_id: :id]

    many_to_many :podcasts, Podcast, join_through: "engagements",
                                     on_delete: :delete_all

    many_to_many :episodes, Episode, join_through: "gigs",
                                     on_delete: :delete_all

    timestamps()
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:pid, :name, :uri, :email, :description, :image_url, :image_title,
                     :redirect_id, :long_description, :user_id, :elastic])
    |> validate_required([:pid, :name, :uri])
    |> unique_constraint(:pid)
  end


  def pro_user_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:pid, :name, :uri, :email, :description, :image_url, :image_title,
                     :long_description])
    |> validate_required([:pid, :name, :uri])
    |> unique_constraint(:pid)
  end


  def user_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :uri])
    |> validate_required([:pid, :name, :uri])
    |> unique_constraint(:pid)
  end


  def claiming_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :email])
  end


  def like(persona_id, current_user_id) do
    case Repo.get_by(Like, enjoyer_id: current_user_id,
                           persona_id: persona_id) do
      nil ->
        %Like{enjoyer_id: current_user_id, persona_id: persona_id}
        |> Repo.insert
      like ->
        {:ok, Repo.delete!(like)}
    end
  end


  def follow(persona_id, current_user_id) do
    case Repo.get_by(Follow, follower_id: current_user_id,
                             persona_id: persona_id) do
      nil ->
        %Follow{follower_id: current_user_id, persona_id: persona_id}
        |> Repo.insert
      follow ->
        {:ok, Repo.delete!(follow)}
    end
  end


  def follower_mailboxes(user_id) do
    Repo.all(from l in Follow, where: l.user_id == ^user_id,
                               select: [:follower_id])
    |> Enum.map(fn(user) ->  "mailboxes:" <> Integer.to_string(user.follower_id) end)
  end


  def likes(id) do
    from(l in Like, where: l.persona_id == ^id)
    |> Repo.aggregate(:count, :id)
    |> Integer.to_string
  end


  def follows(id) do
    from(f in Follow, where: f.persona_id == ^id)
    |> Repo.aggregate(:count, :id)
    |> Integer.to_string
  end

  def update_search_index(id) do
    persona = Repo.get(Persona, id)

    if persona.redirect_id do
      delete("http://localhost:9200/panoptikum_" <> Application.get_env(:pan, :environment) <>
             "/personas/" <> Integer.to_string(id))
      # fallback, in case Tirexs brakes again:
      # url = "http://localhost:9200/panoptikum_" <> Application.get_env(:pan, :environment) <> "/personas/" <> Integer.to_string(id)
      # :httpc.request(:delete, {to_charlist(url), [],'application/json', ""}, [], [])
    else
      put("/panoptikum_" <> Application.get_env(:pan, :environment) <> "/personas/" <> Integer.to_string(id),
          [name:             persona.name,
           pid:              persona.pid,
           uri:              persona.uri,
           description:      persona.description,
           long_description: persona.long_description,
           image_url:        persona.image_url,
           image_title:      persona.image_title,
           url:              persona_frontend_path(PanWeb.Endpoint, :show, id)])
    end
  end


  def update_search_all() do
    persona_ids = Repo.all(from p in Persona, select: p.id)

    for persona_id <- persona_ids do
      update_search_index(persona_id)
    end
  end


  def delete_search_index(id) do
    delete("http://127.0.0.1:9200/panoptikum_" <> Application.get_env(:pan, :environment) <>
           "/personas/" <> Integer.to_string(id))
  end


  def delete_search_index_orphans() do
    persona_ids = (from c in Persona, select: c.id)
                  |> Repo.all()

    max_persona_id = Enum.max(persona_ids)
    all_ids = Range.new(1, max_persona_id) |> Enum.to_list()
    deleted_ids = all_ids -- persona_ids

    for {deleted_id, index} <- Enum.with_index(deleted_ids) do
      IO.puts Integer.to_string((Enum.count(deleted_ids) - index))
      delete_search_index(deleted_id)
    end
  end


  def create_user_persona(user) do
    if user.podcaster == true and Enum.empty?(user.user_personas) do
      pid = UUID.uuid5(:url, Integer.to_string(user.id) <> user.username)

      {:ok, persona} = %Persona{user_id: user.id,
                                pid: pid,
                                name: user.name,
                                email: user.email}
                       |> Repo.insert()

      %Manifestation{persona_id: persona.id,
                     user_id: user.id}
      |> Repo.insert()
    end
  end


  def clear_image_url(persona) do
    persona
    |> Persona.changeset(%{image_url: nil,
                           uri: persona.uri || persona.pid})
    |> Repo.update()
  end


  def cache_thumbnail_image(persona) do
    target_dir = "/var/phoenix/pan-uploads/images/persona-#{persona.id}"

    if URI.parse(persona.image_url).host == nil do
      Persona.clear_image_url(persona)
    else
      case HTTPoison.get(persona.image_url) do
        {:ok, response} ->
          if response.body != "" do
            filename = response.request_url
                       |> URI.parse()
                       |> Map.get(:path)
                       |> Path.basename()

            File.mkdir_p(target_dir)
            File.write!(target_dir <> "/" <> filename, response.body)

            open(target_dir <> "/" <> filename)
            |> resize_to_limit("150x150")
            |> save(in_place: true)

            content_type = :proplists.get_value("Content-Type", response.headers, "unknown")

            {:ok, image} = %Image{content_type: content_type,
                                  filename: filename,
                                  path: "/thumbnails/persona-#{persona.id}/#{filename}",
                                  persona_id: persona.id}
                           |> Image.changeset()
                           |> Repo.insert()

            width = delete_if_defect(image)
            if width == 0, do: Persona.clear_image_url(persona)
          end

        {:error, _reason} -> Persona.clear_image_url(persona)
      end
    end
  end


  def cache_missing_thumbnail_images() do
    persona_ids = from(i in Image, group_by: i.persona_id,
                                   select:   i.persona_id)
                  |> Repo.all

    personas_missing_thumbnails = from(p in Persona, where: not is_nil(p.image_url) and
                                                            not p.id in ^persona_ids)
                                  |> Repo.all

    IO.puts Integer.to_string(length(personas_missing_thumbnails)) <> " missing images"

    for persona <- personas_missing_thumbnails do
      Persona.cache_thumbnail_image(persona)
    end
  end


  def delete_defect_thumbnails() do
    for image <- Repo.all(from(i in Image)) do
      delete_if_defect(image)
    end
  end


  def delete_if_defect(image) do
    target_dir = "/var/phoenix/pan-uploads/images/persona-#{image.persona_id}"

    width = try do
              Mogrify.open(target_dir <> "/" <> image.filename)
              |> Mogrify.verbose()
              |> Map.get(:width)
            rescue
              MatchError -> 0
              File.Error -> 0
            end

    unless width > 0 do
      File.rm(target_dir <> "/" <> image.filename)
      File.rmdir(target_dir)
      Repo.delete!(image)
    end

    width
  end
end
