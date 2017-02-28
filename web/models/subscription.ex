defmodule Pan.Subscription do
  use Pan.Web, :model
  alias Pan.Subscription
  alias Pan.Repo

  @required_fields ~w()
  @optional_fields ~w()

  schema "subscriptions" do
    belongs_to :user, Pan.User
    belongs_to :podcast, Pan.Podcast

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end


  def get_or_insert(user_id, podcast_id) do
    case Repo.get_by(Subscription, user_id:    user_id,
                                   podcast_id: podcast_id) do
      nil ->
        %Subscription{user_id: user_id, podcast_id: podcast_id}
        |> Repo.insert()
      subscription ->
        {:ok, subscription}
    end
  end
end