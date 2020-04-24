defmodule PanWeb.GigController do
  use Pan.Web, :controller
  alias PanWeb.Gig

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def datatable(conn, params) do
    search = params["search"]["value"]
    searchfrag = "%#{params["search"]["value"]}%"

    limit = String.to_integer(params["length"])
    offset = String.to_integer(params["start"])
    draw = String.to_integer(params["draw"])

    columns = params["columns"]

    order_by = Enum.map(params["order"], fn({_key, value}) ->
                 column_number = value["column"]
                 {String.to_atom(value["dir"]), String.to_atom(columns[column_number]["data"])}
               end)

    records_total = Repo.aggregate(Gig, :count, :id)

    query =
      if search != "" do
        from(g in Gig, join: p in assoc(g, :persona),
                       join: e in assoc(g, :episode),
                       where: ilike(g.comment, ^searchfrag) or
                              ilike(g.role, ^searchfrag) or
                              ilike(p.name, ^searchfrag) or
                              ilike(e.title, ^searchfrag) or
                              ilike(fragment("cast (? as text)", g.id), ^searchfrag) or
                              ilike(fragment("cast (? as text)", g.episode_id), ^searchfrag) or
                              ilike(fragment("cast (? as text)", g.persona_id), ^searchfrag))
      else
        from(g in Gig)
      end

    records_filtered = query
                       |> Repo.aggregate(:count)

    gigs = from(g in query, limit: ^limit,
                            offset: ^offset,
                            order_by: ^order_by,
                            join: p in assoc(g, :persona),
                            join: e in assoc(g, :episode),
                            select: %{id:              g.id,
                                      persona_id:      g.persona_id,
                                      persona_name:    p.name,
                                      episode_id:      g.episode_id,
                                      episode_title:   e.title,
                                      from_in_s:       g.from_in_s,
                                      until_in_s:      g.until_in_s,
                                      comment:         g.comment,
                                      publishing_date: g.publishing_date,
                                      role:            g.role,
                                      self_proclaimed: g.self_proclaimed})
           |> Repo.all()

    render(conn, "datatable.json", gigs: gigs,
                                   draw: draw,
                                   records_total: records_total,
                                   records_filtered: records_filtered)
  end

  def new(conn, _params) do
    changeset = Gig.changeset(%Gig{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"gig" => gig_params}) do
    changeset = Gig.changeset(%Gig{}, gig_params)

    case Repo.insert(changeset) do
      {:ok, _gig} ->
        conn
        |> put_flash(:info, "Gig created successfully.")
        |> redirect(to: gig_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    gig = Repo.get!(Gig, id)
    render(conn, "show.html", gig: gig)
  end

  def edit(conn, %{"id" => id}) do
    gig = Repo.get!(Gig, id)
    changeset = Gig.changeset(gig)
    render(conn, "edit.html", gig: gig, changeset: changeset)
  end

  def update(conn, %{"id" => id, "gig" => gig_params}) do
    gig = Repo.get!(Gig, id)
    changeset = Gig.changeset(gig, gig_params)

    case Repo.update(changeset) do
      {:ok, gig} ->
        conn
        |> put_flash(:info, "Gig updated successfully.")
        |> redirect(to: gig_path(conn, :show, gig))
      {:error, changeset} ->
        render(conn, "edit.html", gig: gig, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    gig = Repo.get!(Gig, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(gig)

    conn
    |> put_flash(:info, "Gig deleted successfully.")
    |> redirect(to: gig_path(conn, :index))
  end
end
