defmodule PanWeb.Live.Icon do
  # Tabler Icons, vendored in priv/icons/tabler (see the README there):
  # outline icons by name ("microphone"), filled ones as "<name>-filled".
  # Each SVG is read on first use and cached in :persistent_term.
  require Logger

  def to_string(name), do: to_string(name, class: "h-6 w-6 inline")

  def to_string(name, class: class) do
    case svg(name) do
      "" ->
        ""

      svg ->
        class_attribute =
          Phoenix.HTML.attributes_escape(class: class) |> Phoenix.HTML.safe_to_string()

        String.replace(svg, "<svg", "<svg" <> class_attribute, global: false)
    end
  end

  def exists?(name), do: valid_name?(name) and File.exists?(path(name))

  defp svg(name) do
    key = {__MODULE__, name}

    case :persistent_term.get(key, nil) do
      nil ->
        svg = load(name)
        :persistent_term.put(key, svg)
        svg

      svg ->
        svg
    end
  end

  defp load(name) do
    if exists?(name) do
      path(name)
      |> File.read!()
      |> String.replace(~r/\s+(width|height|class)="[^"]*"/, "", global: true)
      |> String.replace(~r/>\s+</, "><")
      |> String.replace(~r/\s+/, " ")
      |> String.trim()
    else
      Logger.warning("Unknown icon #{inspect(name)}")
      ""
    end
  end

  # keeps names from the database (category icons) inside the icon directory
  defp valid_name?(name), do: is_binary(name) and name =~ ~r/\A[a-z0-9-]+\z/

  defp path(name), do: Application.app_dir(:pan, "priv/icons/tabler/#{name}.svg")
end
