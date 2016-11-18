defmodule Pan.Subscription do
  use Pan.Web, :model

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
    |> cast(params, [])
    |> validate_required([])
  end
end
