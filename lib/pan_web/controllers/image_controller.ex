defmodule PanWeb.ImageController do
  use PanWeb, :controller
  alias PanWeb.{PageFrontendView, Image}

  def create(conn, %{"image" => image_params}) do
    record_slug =
      cond do
        image_params["podcast_id"] -> "persona-" <> image_params["podcast_id"]
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
        Image.changeset(%Image{
          content_type: upload.content_type,
          filename: upload.filename,
          path: destination_path,
          podcast_id: image_params["podcast_id"],
          persona_id: image_params["persona_id"]
        })
      else
        Image.changeset(%Image{
          content_type: nil,
          filename: nil,
          path: destination_path,
          podcast_id: image_params["podcast_id"],
          persona_id: image_params["persona_id"]
        })
      end

    case Repo.insert(changeset) do
      {:ok, _image} ->
        conn
        |> put_flash(:info, "Image uploaded successfully.")
        |> redirect(to: databrowser_path(conn, :index, "image"))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def cache_missing(conn, _params) do
    Task.start(fn -> PanWeb.Image.cache_missing() end)
    render(conn, PageFrontendView, "started.html")
  end

  def remove_duplicates(conn, _params) do
    duplicate_images =
      from(i in Image,
        group_by: [i.podcast_id],
        having: count(i.podcast_id) > 1,
        select: i.podcast_id
      )
      |> Repo.all()

    for podcast_id <- duplicate_images do
      from(i in Image,
        where: i.podcast_id == ^podcast_id,
        limit: 1
      )
      |> Repo.all()
      |> List.first()
      |> Repo.delete()
    end

    duplicate_images =
      from(i in Image,
        group_by: [i.persona_id],
        having: count(i.persona_id) > 1,
        select: i.persona_id
      )
      |> Repo.all()

    for persona_id <- duplicate_images do
      from(i in Image,
        where: i.persona_id == ^persona_id,
        limit: 1
      )
      |> Repo.all()
      |> List.first()
      |> Repo.delete()
    end

    render(conn, PageFrontendView, "done.html")
  end
end
