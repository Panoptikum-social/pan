defmodule PanWeb.Live.Icon do
  # Tabler Icons, vendored in priv/icons/tabler (see the README there):
  # outline icons by name ("microphone"), filled ones as "<name>-filled".
  # Each SVG is read on first use and cached in :persistent_term.
  #
  # Icons have a fixed color each (@colors, Catppuccin accents, backlog.md
  # #438) unless the class sets a text color; on filled backgrounds a CSS rule
  # in app.css gives them the text color again.
  require Logger

  @colors %{
    "microphone" => "peach",
    "headphones" => "teal",
    "user-star" => "mauve",
    "woman" => "flamingo",
    "folder" => "maroon",
    "folder-open" => "maroon",
    "map" => "maroon",
    "calendar" => "blue",
    "stopwatch" => "sapphire",
    "photo" => "pink",
    "rss" => "peach",
    "news" => "red",
    "file-music" => "teal",
    "file-download" => "teal",
    "file-search" => "sapphire",
    "search" => "sky",
    "filter" => "sapphire",
    "adjustments-horizontal" => "sapphire",
    "settings" => "sapphire",
    "link" => "blue",
    "unlink" => "red",
    "arrow-right" => "blue",
    "refresh" => "blue",
    "sort-ascending" => "blue",
    "sort-descending" => "blue",
    "indent-increase" => "lavender",
    "user" => "lavender",
    "users" => "lavender",
    "user-circle" => "lavender",
    "user-filled" => "lavender",
    "user-plus" => "green",
    "user-minus" => "red",
    "spy" => "rosewater",
    "heart" => "red",
    "heart-filled" => "red",
    "thumb-up" => "green",
    "gift" => "pink",
    "flask" => "green",
    "messages" => "pink",
    "messages-filled" => "pink",
    "message" => "pink",
    "briefcase" => "blue",
    "pencil" => "yellow",
    "trash" => "red",
    "x" => "red",
    "login" => "green",
    "logout" => "red",
    "alert-triangle" => "yellow",
    "alert-circle" => "red",
    "info-circle" => "sky",
    "help-circle-filled" => "sky",
    "heart-handshake" => "pink",
    "lock" => "sapphire",
    "flag" => "maroon",
    "users-group" => "lavender",
    "api" => "teal",
    "id" => "blue",
    "presentation" => "peach",
    "help" => "sky",
    "book" => "blue",
    "book-2" => "green",
    "user-heart" => "flamingo",
    "robot" => "sapphire",
    "code" => "green",
    "sun" => "yellow",
    "moon" => "lavender",
    "device-desktop" => "sapphire"
  }

  # a text-* class that sets a color, not a size or alignment
  @text_color ~r/(?:^|\s)(?:[a-z-]+:)?text-(?!(?:xs|sm|base|lg|xl|\d+xl|left|center|right|justify|start|end|wrap|nowrap|balance|pretty|clip|ellipsis)(?:\s|$))/

  def to_string(name), do: to_string(name, class: "h-6 w-6 inline")

  def to_string(name, class: class) do
    case svg(name) do
      "" ->
        ""

      svg ->
        class_attribute =
          Phoenix.HTML.attributes_escape(class: with_color(class, name))
          |> Phoenix.HTML.safe_to_string()

        String.replace(svg, "<svg", "<svg" <> class_attribute, global: false)
    end
  end

  defp with_color(class, name) do
    case @colors[name] do
      color when is_binary(color) and is_binary(class) ->
        if class =~ @text_color, do: class, else: "#{class} text-ctp-#{color}"

      _ ->
        class
    end
  end

  def exists?(name), do: valid_name?(name) and File.exists?(path(name))

  # every icon name, sorted, for the category icon picker (backlog.md #439)
  def names do
    key = {__MODULE__, :names}

    case :persistent_term.get(key, nil) do
      nil ->
        names =
          Application.app_dir(:pan, "priv/icons/tabler")
          |> File.ls!()
          |> Enum.filter(&String.ends_with?(&1, ".svg"))
          |> Enum.map(&String.trim_trailing(&1, ".svg"))
          |> Enum.sort()

        :persistent_term.put(key, names)
        names

      names ->
        names
    end
  end

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
