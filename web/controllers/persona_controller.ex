defmodule Pan.PersonaController do
  use Pan.Web, :controller

  alias Pan.Persona
  alias Pan.Gig
  alias Pan.Contributor
  alias Pan.Engagement
  alias Pan.Like
  alias Pan.Follow
  alias Pan.Manifestation
  alias Pan.User
  alias Pan.Parser.Helpers

  def index(conn, _params) do
    personas = Repo.all(Persona)
    render(conn, "index.html", personas: personas)
  end


  def new(conn, _params) do
    changeset = Persona.changeset(%Persona{})
    render(conn, "new.html", changeset: changeset)
  end


  def create(conn, %{"persona" => persona_params}) do
    changeset = Persona.changeset(%Persona{}, persona_params)

    case Repo.insert(changeset) do
      {:ok, _persona} ->
        conn
        |> put_flash(:info, "Persona created successfully.")
        |> redirect(to: persona_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end


  def show(conn, %{"id" => id}) do
    persona = Repo.get!(Persona, id)
    render(conn, "show.html", persona: persona)
  end


  def edit(conn, %{"id" => id}) do
    persona = Repo.get!(Persona, id)
    changeset = Persona.changeset(persona)
    render(conn, "edit.html", persona: persona, changeset: changeset)
  end


  def update(conn, %{"id" => id, "persona" => persona_params}) do
    persona = Repo.get!(Persona, id)
    changeset = Persona.changeset(persona, persona_params)

    case Repo.update(changeset) do
      {:ok, persona} ->
        conn
        |> put_flash(:info, "Persona updated successfully.")
        |> redirect(to: persona_path(conn, :show, persona))
      {:error, changeset} ->
        render(conn, "edit.html", persona: persona, changeset: changeset)
    end
  end


  def delete(conn, %{"id" => id}) do
    persona = Repo.get!(Persona, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(persona)

    conn
    |> put_flash(:info, "Persona deleted successfully.")
    |> redirect(to: persona_path(conn, :index))
  end


  def transfer(conn, _params) do
    contributors = from(contributor in Contributor, preload: [:episodes, :podcasts])
                   |> Repo.all()

    for contributor <- contributors do
      {:ok, persona} = %Persona{name: contributor.name,
                                uri:  contributor.uri,
                                pid:  UUID.uuid5(:url, contributor.uri)}
                       |> Repo.insert()

      for episode <- contributor.episodes do
        %Gig{persona_id: persona.id,
             episode_id: episode.id,
             role: "contributor",
             publishing_date: episode.publishing_date}
        |> Repo.insert()
      end

      for podcast <- contributor.podcasts do
        %Engagement{persona_id: persona.id,
                    podcast_id: podcast.id,
                    role: "contributor"}
        |> Repo.insert()
      end
    end

    Repo.delete_all(Pan.ContributorEpisode)
    Repo.delete_all(Pan.ContributorPodcast)
    Repo.delete_all(Contributor)

    podcasts = from(p in Pan.Podcast, where: not is_nil(p.owner_id),
                                      preload: [:owner])
               |> Repo.all()

     for podcast <- podcasts do
      {:ok, persona} =
        case Repo.get_by(Pan.Persona, pid: UUID.uuid5(:url, podcast.owner.email)) do
          nil ->
            %Pan.Persona{name:  podcast.owner.name,
                         email: podcast.owner.email,
                         uri:   podcast.owner.email,
                         pid:   UUID.uuid5(:url, podcast.owner.email)}
            |> Repo.insert()
          persona ->
            Pan.Persona.changeset(persona, %{email: podcast.owner.email})
            |> Repo.update()

            {:ok, persona}
        end

      %Engagement{persona_id: persona.id,
                  podcast_id: podcast.id,
                  role: "owner"}
      |> Repo.insert()

      if podcast.owner.password_hash != nil do
        %Manifestation{persona_id: persona.id, user_id: podcast.owner_id}
        |> Repo.insert()
      end

      likes = from(l in Like, where: l.user_id == ^podcast.owner_id)
              |> Repo.all()

      for like <- likes do
        Like.changeset(like, %{user_id: nil, persona_id: persona.id})
        |> Repo.update()
      end

      follows = from(f in Follow, where: f.user_id == ^podcast.owner_id)
                |> Repo.all()

      for follow <- follows do
        follow = Follow.changeset(follow, %{user_id: nil, persona_id: persona.id})
                 |> Repo.update()
        Helpers.inspect follow
      end

      Pan.Podcast.changeset(podcast, %{owner_id: nil})
      |> Repo.update()
    end

    users = from(u in User, where: is_nil(u.password_hash))
            |> Repo.all()

    for user <- users do
      try do
        Repo.delete(user)
      rescue
        Ecto.ConstraintError -> "Error!"
      end
    end

    render(conn, "transfer.html")
  end

  def test(conn, _params) do

    render(conn, "test.html")
  end
end