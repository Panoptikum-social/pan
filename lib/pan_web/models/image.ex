defmodule PanWeb.Image do
  use PanWeb, :model
  alias PanWeb.{Image, Persona, Podcast}
  alias Pan.Repo
  require Logger

  schema "images" do
    field(:filename, :string)
    field(:content_type, :string)
    field(:path, :string)
    belongs_to(:podcast, PanWeb.Podcast)
    belongs_to(:persona, PanWeb.Persona)

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:filename, :content_type, :path, :podcast_id, :persona_id])
    |> validate_required([:filename, :path])
  end

  def delete_defect_thumbnails() do
    for image <- Repo.all(from(i in Image)) do
      delete_if_defect(image)
    end
  end

  def delete_if_defect(image) do
    target_dir =
      String.replace(image.path, "thumbnails", "var/phoenix/pan-uploads/images")
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
      delete_asset(image)
      {:error, "error"}
    else
      {:ok, width}
    end
  end

  def delete_asset(image) do
    target_dir =
      String.replace(image.path, "thumbnails", "var/phoenix/pan-uploads/images")
      |> Path.dirname()

    File.rm(target_dir <> "/" <> image.filename)
    File.rmdir(target_dir)
    Repo.delete!(image)
  end

  def download_thumbnail(type, id, url) do
    id_part =
      id
      |> Integer.to_string()
      |> String.replace(~r/(.)/, "\\1/")

    target_dir = "/var/phoenix/pan-uploads/images/#{type}/#{id_part}"
    asset_path = "/thumbnails/#{type}/#{id_part}"

    with {:ok, _} <- not_empty(URI.parse(url).host),
         {:ok, url} <- starts_with_http(url),
         {:ok, response} <- URI.encode(url) |> Pan.Parser.Download.get(),
         {:ok, _} <- not_empty(response.body),
         {:ok, path} <- extract_path(response),
         {:ok, filename} <- not_empty(Path.basename(path)) do
      File.mkdir_p(target_dir)
      File.write!(target_dir <> "/" <> filename, response.body)

      Logger.info("=== Mogrifying image with id #{id} ===")

      try do
        (target_dir <> "/" <> filename)
        |> Mogrify.open()
        |> Mogrify.resize_to_limit("150x150")
        |> Mogrify.save(in_place: true)
      catch
        # We fail silently, as we did before mogrify raised errors.
        kind, {error, {message, _}} ->
          Logger.info("=== Image with id #{id} #{kind}:#{error} (#{message}) ===")

        kind, {error, message} ->
          Logger.info("=== Image with id #{id} #{kind}:#{error} (#{message}) ===")
      end

      content_type = :proplists.get_value("Content-Type", response.headers, "unknown")

      {:ok, image} =
        %Image{
          content_type: content_type,
          filename: filename,
          path: asset_path,
          persona_id: (type == "persona" && id) || nil,
          podcast_id: (type == "podcast" && id) || nil
        }
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

  def cache_missing() do
    Persona.cache_missing_thumbnail_images()
    Podcast.cache_missing_thumbnail_images()
    Logger.info("=== Thumbnail image caching job finished ===")
  end

  def get_by_podcast_id(podcast_id) do
    Repo.get_by(Image, podcast_id: podcast_id)
  end

  def get_by_persona_id(persona_id) do
    Repo.get_by(Image, persona_id: persona_id)
  end
end
