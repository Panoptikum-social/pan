defmodule PanWeb.UserApiController do
  use Pan.Web, :controller
  use JaSerializer
  alias PanWeb.User
  alias PanWeb.MyUserApiView


  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def index(conn, params, _user) do
    page = Map.get(params, "page", %{})
           |> Map.get("number", "1")
           |> String.to_integer
    size = Map.get(params, "page", %{})
           |> Map.get("size", "10")
           |> String.to_integer
    offset = (page - 1) * size

    total = from(u in User, where: (is_nil(u.admin) or u.admin == false))
            |> Repo.aggregate(:count, :id)
    total_pages = div(total - 1, size) + 1

    links = JaSerializer.Builder.PaginationLinks.build(%{number: page,
                                                         size: size,
                                                         total: total_pages,
                                                         base_url: user_api_url(conn,:index)}, conn)

    users = from(u in User, order_by: :name,
                            limit: ^size,
                            offset: ^offset,
                            where: (is_nil(u.admin) or u.admin == false))
            |> Repo.all()

    render conn, "index.json-api", data: users,
                                   opts: [page: links]
  end

  def show(conn, %{"id" => id}, _user) do
    user = Repo.get(User, id)
           |> Repo.preload([:categories_i_like, :users_i_like])

    include_string = "categories_i_like,users_i_like"

    {user, include_string} =
      if user.share_subscriptions do
        {Repo.preload(user, :podcasts_i_subscribed), include_string <> ",podcasts_i_subscribed"}
      else
        {user, include_string}
      end

    {user, include_string} =
      if user.share_follows do
        {Repo.preload(user, :podcasts_i_follow), include_string <> ",podcasts_i_follow"}
      else
        {user, include_string}
      end

    render conn, "show.json-api", data: user,
                                  opts: [include: include_string]
  end


  def my(conn, _params, user) do
    user = Repo.get(User, user.id)
           |> Repo.preload(:personas)

    conn
    |> put_view(MyUserApiView)
    |> render("show.json-api", data: user,
                               opts: [include: "personas"])
  end
end
