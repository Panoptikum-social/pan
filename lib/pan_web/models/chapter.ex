defmodule PanWeb.Chapter do
  use PanWeb, :model
  alias Pan.Repo
  alias PanWeb.Like

  schema "chapters" do
    field(:start, :string)
    field(:title, :string)
    timestamps()

    belongs_to(:episode, PanWeb.Episode)

    has_many(:recommendations, PanWeb.Recommendation, on_delete: :delete_all)
    has_many(:likes, PanWeb.Like, on_delete: :delete_all)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:start, :title, :episode_id])
    |> validate_required([:start, :title])
  end

  def like(chapter_id, user_id) do
    case Repo.get_by(Like,
           enjoyer_id: user_id,
           chapter_id: chapter_id
         ) do
      nil ->
        %Like{enjoyer_id: user_id, chapter_id: chapter_id}
        |> Repo.insert()

      like ->
        {:ok, Repo.delete!(like)}
    end
  end

  def likes(id) do
    from(l in Like, where: l.chapter_id == ^id)
    |> Repo.aggregate(:count)
    |> Integer.to_string()
  end

  def get_by_id(id) do
    Repo.get!(Chapter, id)
  end
end
