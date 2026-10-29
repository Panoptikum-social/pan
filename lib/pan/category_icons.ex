defmodule Pan.CategoryIcons do
  @moduledoc """
  Proposed Tabler icons per category and Catppuccin colors per top level
  category (subcategories use their parent's color), see backlog.md #439.
  Keys are "Title" for top level and "Parent › Title" for subcategories,
  matched trimmed and case-insensitively.

  `fill_missing/0` sets only empty icons and colors, so whatever was changed
  in the admin stays. Categories without an icon get the folder icon when
  rendered. There are no country flags in Tabler, so the nationalities under
  International share one icon.
  """
  import Ecto.Query
  alias Pan.Repo
  alias PanWeb.Category

  @icons %{
    "Arts" => "palette",
    "Arts › Books" => "book",
    "Arts › Design" => "vector-bezier",
    "Arts › Entertainment" => "confetti",
    "Arts › Fashion & Beauty" => "shirt",
    "Arts › Food" => "tools-kitchen-2",
    "Arts › Performing Arts" => "masks-theater",
    "Arts › Spoken Word" => "quote",
    "Arts › Visual Arts" => "brush",
    "Business" => "briefcase",
    "Business › Careers" => "stairs-up",
    "Business › Entrepreneurship" => "rocket",
    "Business › Investing" => "chart-line",
    "Business › Management" => "hierarchy",
    "Business › Management & Marketing" => "presentation",
    "Business › Marketing" => "speakerphone",
    "Business › Non-Profit" => "heart-handshake",
    "Business › Shopping" => "shopping-cart",
    "Comedy" => "mood-happy",
    "Comedy › Comedy Interviews" => "messages",
    "Comedy › Improv" => "mood-wink",
    "Comedy › Stand-Up" => "microphone-2",
    "Education" => "school",
    "Education › Courses" => "certificate",
    "Education › Educational Technology" => "device-laptop",
    "Education › Higher Education" => "building-arch",
    "Education › How To" => "tool",
    "Education › K-12" => "backpack",
    "Education › Language Learning" => "language",
    "Education › Self-Improvement" => "trending-up",
    "Education › Training" => "chalkboard",
    "Fiction" => "book-2",
    "Fiction › Comedy Fiction" => "mood-smile-beam",
    "Fiction › Drama" => "heart-broken",
    "Fiction › Science Fiction" => "ufo",
    "Government" => "building-bank",
    "Government › Local" => "map-pin",
    "Government › National" => "flag",
    "Government › Regional" => "map",
    "Health & Fitness" => "heartbeat",
    "Health & Fitness › Alternative Health" => "leaf",
    "Health & Fitness › Fitness" => "barbell",
    "Health & Fitness › Fitness & Nutrition" => "salad",
    "Health & Fitness › Medicine" => "stethoscope",
    "Health & Fitness › Mental Health" => "brain",
    "Health & Fitness › Nutrition" => "apple",
    "Health & Fitness › Sexuality" => "gender-genderqueer",
    "History" => "hourglass",
    "International" => "world",
    "International › Brazilian" => "flag-2",
    "International › Canadian" => "flag-2",
    "International › Dutch" => "flag-2",
    "International › French" => "flag-2",
    "International › German" => "flag-2",
    "International › Italian" => "flag-2",
    "International › Japanese" => "flag-2",
    "Kids & Family" => "baby-carriage",
    "Kids & Family › Education for Kids" => "abc",
    "Kids & Family › Parenting" => "mood-kid",
    "Kids & Family › Pets & Animals" => "paw",
    "Kids & Family › Stories for Kids" => "moon-stars",
    "Leisure" => "beach",
    "Leisure › Animation & Manga" => "pokeball",
    "Leisure › Audio" => "headphones",
    "Leisure › Automotive" => "car",
    "Leisure › Aviation" => "plane",
    "Leisure › Crafts" => "needle-thread",
    "Leisure › Games" => "dice-5",
    "Leisure › Hobbies" => "puzzle",
    "Leisure › Home & Garden" => "plant",
    "Leisure › Video Games" => "device-gamepad-2",
    "Music" => "music",
    "Music › Music Commentary" => "playlist",
    "Music › Music History" => "vinyl",
    "Music › Music Interviews" => "message-user",
    "News" => "news",
    "News › Business News" => "chart-bar",
    "News › Daily News" => "calendar-event",
    "News › Entertainment News" => "star",
    "News › News Commentary" => "message-circle",
    "News › Politics" => "scale",
    "News › Sports News" => "trophy",
    "News › Tech News" => "robot",
    "Radio" => "radio",
    "Radio › Audio Blogs" => "headset",
    "Radio › Talk Radio" => "antenna",
    "Religion & Spirituality" => "pray",
    "Religion & Spirituality › Buddhism" => "yin-yang",
    "Religion & Spirituality › Christianity" => "cross",
    "Religion & Spirituality › Hinduism" => "om",
    "Religion & Spirituality › Islam" => "building-mosque",
    "Religion & Spirituality › Judaism" => "menorah",
    "Religion & Spirituality › Religion" => "building-church",
    "Religion & Spirituality › Spirituality" => "sparkles",
    "Science" => "flask",
    "Science › Astronomy" => "telescope",
    "Science › Chemistry" => "flask-2",
    "Science › Earth Sciences" => "mountain",
    "Science › Life Sciences" => "dna",
    "Science › Mathematics" => "math",
    "Science › Natural Sciences" => "microscope",
    "Science › Nature" => "trees",
    "Science › Physics" => "atom",
    "Science › Social Sciences" => "affiliate",
    "Society & Culture" => "users",
    "Society & Culture › Digital Culture" => "world-www",
    "Society & Culture › Documentary" => "video",
    "Society & Culture › Personal Journals" => "notebook",
    "Society & Culture › Philosophy" => "bulb",
    "Society & Culture › Places & Travel" => "map-2",
    "Society & Culture › Relationships" => "hearts",
    "Sports" => "medal",
    "Sports › Amateur" => "medal-2",
    "Sports › Baseball" => "ball-baseball",
    "Sports › Basketball" => "ball-basketball",
    "Sports › College & High School" => "school-bell",
    "Sports › Cricket" => "cricket",
    "Sports › Fantasy Sports" => "wand",
    "Sports › Football" => "ball-american-football",
    "Sports › Golf" => "golf",
    "Sports › Hockey" => "ice-skating",
    "Sports › Professional" => "award",
    "Sports › Rugby" => "users-group",
    "Sports › Running" => "run",
    "Sports › Skateboard" => "skateboarding",
    "Sports › Soccer" => "ball-football",
    "Sports › Swimming" => "swimming",
    "Sports › Tennis" => "ball-tennis",
    "Sports › Volleyball" => "ball-volleyball",
    "Sports › Wilderness" => "tent",
    "Sports › Wrestling" => "karate",
    "Technology" => "cpu",
    "Technology › Computers" => "device-desktop",
    "Technology › Development" => "code",
    "Technology › Gadgets" => "device-watch",
    "Technology › Information Technology" => "server",
    "Technology › Linux" => "terminal-2",
    "Technology › Operating Systems" => "app-window",
    "Technology › Podcasting" => "broadcast",
    "Technology › Software How-To" => "help",
    "Technology › Software Testing" => "bug",
    "True Crime" => "fingerprint",
    "TV & Film" => "device-tv",
    "TV & Film › After Shows" => "player-track-next",
    "TV & Film › Film History" => "camera",
    "TV & Film › Film Interviews" => "chair-director",
    "TV & Film › Film Reviews" => "star-half",
    "TV & Film › TV Reviews" => "device-tv-old",
    "Unsorted" => "folder-question"
  }

  @colors %{
    "Arts" => "pink",
    "Business" => "blue",
    "Comedy" => "yellow",
    "Education" => "teal",
    "Fiction" => "mauve",
    "Government" => "sapphire",
    "Health & Fitness" => "green",
    "History" => "peach",
    "International" => "sky",
    "Kids & Family" => "flamingo",
    "Leisure" => "maroon",
    "Music" => "lavender",
    "News" => "red",
    "Radio" => "rosewater",
    "Religion & Spirituality" => "mauve",
    "Science" => "teal",
    "Society & Culture" => "peach",
    "Sports" => "green",
    "Technology" => "blue",
    "True Crime" => "red",
    "TV & Film" => "yellow"
  }

  @doc "Fills empty icons and colors from the proposals, returns the counts."
  def fill_missing do
    icons = normalize_keys(@icons)
    colors = normalize_keys(@colors)

    from(c in Category, where: is_nil(c.icon) or (is_nil(c.parent_id) and is_nil(c.color)))
    |> preload(:parent)
    |> Repo.all()
    |> Enum.reduce(%{icons: 0, colors: 0}, fn category, counts ->
      key = normalize(name(category))

      changes =
        %{}
        |> put_missing(:icon, category.icon, icons[key])
        # only top level categories get a color
        |> put_missing(:color, category.parent_id || category.color, colors[key])

      if changes != %{}, do: category |> Ecto.Changeset.change(changes) |> Repo.update!()

      %{
        icons: counts.icons + if(Map.has_key?(changes, :icon), do: 1, else: 0),
        colors: counts.colors + if(Map.has_key?(changes, :color), do: 1, else: 0)
      }
    end)
  end

  defp name(%Category{parent: %Category{title: parent}, title: title}),
    do: String.trim(parent) <> " › " <> String.trim(title)

  defp name(%Category{title: title}), do: title

  defp put_missing(changes, field, nil, value) when is_binary(value),
    do: Map.put(changes, field, value)

  defp put_missing(changes, _field, _present, _value), do: changes

  defp normalize_keys(map), do: Map.new(map, fn {key, value} -> {normalize(key), value} end)

  defp normalize(name), do: name |> String.trim() |> String.downcase()
end
