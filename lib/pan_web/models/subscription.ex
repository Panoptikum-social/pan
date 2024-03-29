defmodule PanWeb.Subscription do
  use PanWeb, :model
  alias Pan.Repo
  alias PanWeb.Subscription

  schema "subscriptions" do
    belongs_to(:user, PanWeb.User)
    belongs_to(:podcast, PanWeb.Podcast)

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :podcast_id])
    |> validate_required([:user_id, :podcast_id])
  end

  def get_or_insert(user_id, podcast_id) do
    case Repo.get_by(Subscription,
           user_id: user_id,
           podcast_id: podcast_id
         ) do
      nil ->
        %Subscription{user_id: user_id, podcast_id: podcast_id}
        |> Repo.insert()

      subscription ->
        {:ok, subscription}
    end
  end

  def find_podcast_subscription(user_id, podcast_id) do
    Repo.get_by(PanWeb.Subscription,
      user_id: user_id,
      podcast_id: podcast_id
    )
  end
end
