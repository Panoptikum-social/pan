defmodule PanWeb.Curatorship do
  use PanWeb, :model
  alias Pan.Repo
  alias PanWeb.{Community, Curatorship, User}

  @primary_key false

  # Assigns a curator to a community. The users.curator flag only gates who can
  # be assigned: clearing it later leaves existing curatorships active.
  schema "curatorships" do
    belongs_to(:user, PanWeb.User, primary_key: true)
    belongs_to(:community, PanWeb.Community, primary_key: true)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :community_id])
    |> validate_required([:user_id, :community_id])
    |> unique_constraint([:user_id, :community_id])
  end

  @doc "Assigns a user to a community as curator; only users with the curator flag qualify."
  def assign(community_id, user_id) do
    case Repo.get(User, user_id) do
      %{curator: true} ->
        %Curatorship{}
        |> changeset(%{user_id: user_id, community_id: community_id})
        |> Repo.insert(on_conflict: :nothing)

      _ ->
        {:error, :not_a_curator}
    end
  end

  @doc """
  Moderators add curators by username in one step: sets the curator flag if
  needed and assigns the user to the community. Clearing the flag stays with
  admins.
  """
  def make_curator_and_assign(community_id, username) do
    case Repo.get_by(User, username: String.trim(username)) do
      nil ->
        {:error, :user_not_found}

      user ->
        if !user.curator, do: user |> change(curator: true) |> Repo.update!()
        assign(community_id, user.id)
    end
  end

  def count_by_community_id(community_id) do
    from(c in Curatorship, where: c.community_id == ^community_id)
    |> Repo.aggregate(:count)
  end

  def unassign(community_id, user_id) do
    from(c in Curatorship, where: c.community_id == ^community_id and c.user_id == ^user_id)
    |> Repo.delete_all()
  end

  @doc """
  The given communities (all of them for `:all`) with their curators preloaded,
  plus the flagged curators that can still be assigned to each of them.
  """
  def assignment_list(community_ids) do
    candidates = from(u in User, where: u.curator, order_by: u.username) |> Repo.all()

    community_ids
    |> communities_query()
    |> Repo.all()
    |> Repo.preload(curators: from(u in User, order_by: u.username))
    |> Enum.map(fn community ->
      assigned_ids = Enum.map(community.curators, & &1.id)
      %{community: community, candidates: Enum.reject(candidates, &(&1.id in assigned_ids))}
    end)
  end

  defp communities_query(:all), do: from(c in Community, order_by: c.title)

  defp communities_query(ids),
    do: from(c in Community, where: c.id in ^ids, order_by: c.title)
end
