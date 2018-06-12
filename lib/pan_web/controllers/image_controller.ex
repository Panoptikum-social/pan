defmodule PanWeb.ImageController do
  use Pan.Web, :controller
  alias PanWeb.Image

  def index(conn, _params) do
    images = Repo.all(Image)
    render(conn, "index.html", images: images)
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
end
