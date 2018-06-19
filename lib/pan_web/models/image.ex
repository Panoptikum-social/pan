defmodule PanWeb.Image do
  use Pan.Web, :model
  alias PanWeb.Image
  alias Pan.Repo

  schema "images" do
    field :filename, :string
    field :content_type, :string
    field :path, :string
    belongs_to :podcast, PanWeb.Podcast
    belongs_to :episode, PanWeb.Episode
    belongs_to :persona, PanWeb.Persona

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:filename, :content_type, :path, :podcast_id, :episode_id, :persona_id])
    |> validate_required([:filename, :path])
  end


  def delete_defect_thumbnails() do
    for image <- Repo.all(from(i in Image)) do
      delete_if_defect(image)
    end
  end


  def delete_if_defect(image) do
    target_dir = String.replace(image.path, "thumbnails", "var/phoenix/pan-uploads/images")
                 |> Path.dirname()

    width =
      try do
        Mogrify.open(target_dir <> "/" <> image.filename)
        |> Mogrify.verbose()
        |> Map.get(:width)
      rescue
        MatchError -> 0
        File.Error -> 0
        Protocol.UndefinedError -> 0
      end

    if width == 0 do
      File.rm(target_dir <> "/" <> image.filename)
      File.rmdir(target_dir)
      Repo.delete!(image)
      {:error, "error"}
    else
      {:ok, width}
    end
  end


  def download_thumbnail(type, id, url) do
    target_dir = "/var/phoenix/pan-uploads/images/#{type}-#{id}"

    with {:ok, _} <- not_empty(URI.parse(url).host),
         {:ok, url} <- starts_with_http(url),
         {:ok, response} <- HTTPoison.get(url),
         {:ok, _} <- not_empty(response.body),
         {:ok, path} <- extract_path(response) do
      filename = Path.basename(path)
      File.mkdir_p(target_dir)
      File.write!(target_dir <> "/" <> filename, response.body)

      target_dir <> "/" <> filename
      |> Mogrify.open()
      |> Mogrify.resize_to_limit("150x150")
      |> Mogrify.save(in_place: true)

      content_type = :proplists.get_value("Content-Type", response.headers, "unknown")

      {:ok, image} = %Image{content_type: content_type,
                            filename: filename,
                            path: "/thumbnails/persona-#{id}/#{filename}",
                            persona_id: type == "persona" && id || nil,
                            podcast_id: type == "podcast" && id || nil,
                            episode_id: type == "episode" && id || nil}
                     |> Image.changeset()
                     |> Repo.insert()

      Image.delete_if_defect(image)
    else
      {:error, error} -> {:error, error}
      {:ok, []} -> {:error, "empty response"}
    end
  end

  def not_empty(string) when string == nil or string == "", do: {:error, "empty"}
  def not_empty(string), do: {:ok, string}


  def starts_with_http(url) do
    cond do
     String.starts_with?(url, "http") -> {:ok, url}
     String.starts_with?(url, "//") -> {:ok, "https:" <> url}
     true -> {:error, "error"}
    end
  end


  def extract_path(response) do
    URI.parse(response.request_url)
    |> Map.get(:path)
    |> not_empty()
  end
end
