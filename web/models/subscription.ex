defmodule Pan.Subscription do
  use Pan.Web, :model
  alias Pan.Subscription
  alias Pan.Repo

  schema "subscriptions" do
    belongs_to :user, Pan.User
    belongs_to :podcast, Pan.Podcast

    timestamps()
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :podcast_id])
    |> validate_required([:user_id, :podcast_id])
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