defmodule Pan.Gig do
  use Pan.Web, :model
  alias Pan.Gig
  alias Pan.Repo
  alias Pan.Manifestation

  schema "gigs" do
    field :from_in_s, :integer
    field :until_in_s, :integer
    field :comment, :string
    field :publishing_date, :naive_datetime
    field :role, :string
    field :self_proclaimed, :boolean
    belongs_to :persona, Pan.Persona
    belongs_to :episode, Pan.Episode

    timestamps()
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:publishing_date, :role, :from_in_s, :until_in_s, :comment,
                     :episode_id, :persona_id, :self_proclaimed])
    |> validate_required([:publishing_date, :role])
  end


  def find_self_proclaimed(persona_id, episode_id) do
    from(g in Gig, where: g.self_proclaimed == ^true and
                          g.persona_id == ^persona_id and
                          g.episode_id == ^episode_id)
    |> Repo.one
  end


  def proclaim(episode_id, persona_id, current_user_id) do
    with _ <- Repo.get_by(Manifestation, user_id: current_user_id,
                                      persona_id: persona_id) do
      case Repo.get_by(Gig, episode_id: episode_id,
                            persona_id: persona_id,
                            self_proclaimed: true) do
        nil ->
          %Gig{episode_id: episode_id,
               persona_id: persona_id,
               self_proclaimed: true,
               role: "contributor"}
          |> Repo.insert
        gig ->
          Repo.delete!(gig)
      end
    end
  end
end
