defmodule Pan.Persona do
  use Pan.Web, :model
  alias Pan.Like
  alias Pan.Repo
  alias Pan.Follow

  schema "personas" do
    field :pid, :string
    field :name, :string
    field :uri, :string
    field :email, :string
    field :description, :string
    field :image_url, :string
    field :image_title, :string

    has_many :engagements, Pan.Engagement
    has_many :gigs, Pan.Gig

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:pid, :name, :uri, :email, :description, :image_url, :image_title], [])
    |> validate_required([:pid, :name, :uri])
  end


  def like(persona_id, current_user_id) do
    case Repo.get_by(Like, enjoyer_id: current_user_id,
                           persona_id: persona_id) do
      nil ->
        %Like{enjoyer_id: current_user_id, persona_id: persona_id}
        |> Repo.insert
      like ->
        Repo.delete!(like)
    end
  end


  def follow(persona_id, current_user_id) do
    case Repo.get_by(Follow, follower_id: current_user_id,
                             persona_id: persona_id) do
      nil ->
        %Follow{follower_id: current_user_id, persona_id: persona_id}
        |> Repo.insert
      like ->
        Repo.delete!(like)
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
end