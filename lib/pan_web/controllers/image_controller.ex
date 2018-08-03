defmodule PanWeb.ImageController do
  use Pan.Web, :controller
  alias PanWeb.Image

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

    records_total = Repo.aggregate(Image, :count, :id)

    query =
      if search != "" do
        from(i in Image, where: ilike(fragment("cast (? as text)", i.persona_id), ^searchfrag) or
                                ilike(fragment("cast (? as text)", i.episode_id), ^searchfrag) or
                                ilike(fragment("cast (? as text)", i.podcast_id), ^searchfrag) or
                                ilike(fragment("cast (? as text)", i.id), ^searchfrag))
      else
        from(i in Image)
      end

    records_filtered = query
                       |> Repo.aggregate(:count, :id)

    images = from(i in query, limit: ^limit,
                                offset: ^offset,
                                order_by: ^order_by,
                                select: %{id:           i.id,
                                          filename:     i.filename,
                                          content_type: i.content_type,
                                          path:         i.path,
                                          podcast_id:   i.podcast_id,
                                          episode_id:   i.episode_id,
                                          persona_id:   i.persona_id})
           |> Repo.all()

    render(conn, "datatable.json", images: images,
                                   draw: draw,
                                   records_total: records_total,
                                   records_filtered: records_filtered)
  end


  def new(conn, _params) do
    changeset = Image.changeset(%Image{})
    render(conn, "new.html", changeset: changeset)
  end


  def create(conn, %{"image" => image_params}) do
    record_slug =
      cond do
        image_params["podcast_id"] -> "persona-" <> image_params["podcast_id"]
        image_params["episode_id"] -> "episode-" <> image_params["episode_id"]
        image_params["persona_id"] -> "persona-" <> image_params["persona_id"]
      end

    destination_path =
      if upload = image_params["file"] do
        File.mkdir_p("/var/phoenix/pan-uploads/images/#{record_slug}")
        path = "/var/phoenix/pan-uploads/images/#{record_slug}/#{upload.filename}"
        File.cp(upload.path, path)
        path
      else
        ""
      end

    changeset =
      if upload do
        Image.changeset(%Image{content_type: upload.content_type,
                                   filename: upload.filename,
                                   path: destination_path,
                                   podcast_id: image_params["podcast_id"],
                                   episode_id: image_params["episode_id"],
                                   persona_id: image_params["persona_id"]})
      else
        Image.changeset(%Image{content_type: nil,
                                   filename: nil,
                                   path: destination_path,
                                   podcast_id: image_params["podcast_id"],
                                   episode_id: image_params["episode_id"],
                                   persona_id: image_params["persona_id"]})
      end

    case Repo.insert(changeset) do
      {:ok, _image} ->
        conn
        |> put_flash(:info, "Image uploaded successfully.")
        |> redirect(to: image_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end


  def show(conn, %{"id" => id}) do
    image = Repo.get!(Image, id)
    render(conn, "show.html", image: image)
  end


  def edit(conn, %{"id" => id}) do
    image = Repo.get!(Image, id)
    changeset = Image.changeset(image)
    render(conn, "edit.html", image: image, changeset: changeset)
  end


  def update(conn, %{"id" => id, "image" => image_params}) do
    image = Repo.get!(Image, id)
    changeset = Image.changeset(image, image_params)

    case Repo.update(changeset) do
      {:ok, image} ->
        conn
        |> put_flash(:info, "Image updated successfully.")
        |> redirect(to: image_path(conn, :show, image))
      {:error, changeset} ->
        render(conn, "edit.html", image: image, changeset: changeset)
    end
  end


  def delete(conn, %{"id" => id}) do
    image = Repo.get!(Image, id)

    File.rm(image.path)
    Repo.delete!(image)

    conn
    |> put_flash(:info, "Image deleted successfully.")
    |> redirect(to: image_path(conn, :index))
  end


  def cache_missing(conn, _params) do
    PanWeb.Image.cache_missing()
    render(conn, "done.html")
  end


  def remove_duplicates(conn, _params) do
    duplicate_images = from(i in Image, group_by: [i.episode_id],
                                        having: count(i.episode_id) > 1,
                                        select: i.episode_id)
                       |> Repo.all()

    for episode_id <- duplicate_images do
      from(i in Image, where: i.episode_id == ^episode_id,
                       limit: 1)
      |> Repo.all()
      |> List.first()
      |> Repo.delete()
    end

    duplicate_images = from(i in Image, group_by: [i.podcast_id],
                                        having: count(i.podcast_id) > 1,
                                        select: i.podcast_id)
                       |> Repo.all()

    for podcast_id <- duplicate_images do
      from(i in Image, where: i.podcast_id == ^podcast_id,
                       limit: 1)
      |> Repo.all()
      |> List.first()
      |> Repo.delete()
    end

    duplicate_images = from(i in Image, group_by: [i.persona_id],
                                        having: count(i.persona_id) > 1,
                                        select: i.persona_id)
                       |> Repo.all()

    for persona_id <- duplicate_images do
      from(i in Image, where: i.persona_id == ^persona_id,
                       limit: 1)
      |> Repo.all()
      |> List.first()
      |> Repo.delete()
    end

    render(conn, "done.html")
  end
end
