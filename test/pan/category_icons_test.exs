defmodule Pan.CategoryIconsTest do
  use Pan.DataCase

  alias Pan.Repo
  alias PanWeb.Category

  defp insert_category(title, parent \\ nil, fields \\ []),
    do: Repo.insert!(struct(%Category{title: title, parent_id: parent && parent.id}, fields))

  test "fills empty icons and top level colors, keeps what is set" do
    music = insert_category(" music ")
    history = insert_category("Music History", music)
    interviews = insert_category("Music Interviews", music, icon: "microphone")
    stray = insert_category("Stray")
    science = insert_category("Science", nil, color: "red")

    assert %{icons: 3, colors: 1} = Pan.CategoryIcons.fill_missing()

    assert %{icon: "music", color: "lavender"} = Repo.reload(music)
    assert %{icon: "vinyl", color: nil} = Repo.reload(history)
    assert %{icon: "microphone"} = Repo.reload(interviews)
    assert %{icon: nil, color: nil} = Repo.reload(stray)
    assert %{icon: "flask", color: "red"} = Repo.reload(science)
  end
end
