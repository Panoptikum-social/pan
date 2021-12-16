defmodule PanWeb.Gig do
  use PanWeb, :model
  alias Pan.Repo
  alias PanWeb.{Gig, Manifestation}

  schema "gigs" do
    field(:from_in_s, :integer)
    field(:until_in_s, :integer)
    field(:comment, :string)
    field(:publishing_date, :naive_datetime)
    field(:role, :string)
    field(:self_proclaimed, :boolean)
    belongs_to(:persona, PanWeb.Persona)
    belongs_to(:episode, PanWeb.Episode)

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :publishing_date,
      :role,
      :from_in_s,
      :until_in_s,
      :comment,
      :episode_id,
      :persona_id,
      :self_proclaimed
    ])
    |> validate_required([:publishing_date, :role])
  end

  def find_self_proclaimed(persona_id, episode_id) do
    from(g in Gig,
      where:
        g.self_proclaimed == ^true and
          g.persona_id == ^persona_id and
          g.episode_id == ^episode_id
    )
    |> Repo.one()
  end

  def proclaim(episode_id, persona_id, current_user_id) do
    case Repo.get_by(Manifestation, user_id: current_user_id, persona_id: persona_id) do
      %Manifestation{} ->
        case Repo.get_by(Gig, episode_id: episode_id, persona_id: persona_id) do
          nil ->
            %Gig{
              episode_id: episode_id,
              persona_id: persona_id,
              self_proclaimed: true,
              role: "contributor"
            }
            |> Repo.insert()

          gig ->
            {:ok, Repo.delete!(gig)}
        end

      _ ->
        {:error, "not your persona"}
    end
  end

  def get_by_persona_ids(persona_ids, page, per_page) do
    from(g in Gig,
      where: g.persona_id in ^persona_ids,
      join: e in assoc(g, :episode),
      order_by: [desc: e.publishing_date],
      select: g.id,
      limit: ^per_page,
      offset: (^page - 1) * ^per_page
    )
    |> Repo.all()
  end

  def grouped_gigs(gigs) do
    from(g in Gig,
      where: g.id in ^gigs,
      preload: [episode: :podcast]
    )
    |> Repo.all()
    |> Enum.group_by(&Map.get(&1, :episode))
  end
end
