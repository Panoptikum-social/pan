defmodule PanWeb.CategoryIconTest do
  use ExUnit.Case, async: true
  alias PanWeb.Category

  test "takes a Tabler icon and a Catppuccin accent" do
    changeset = Category.changeset(%Category{}, %{title: "Music", icon: "music", color: "mauve"})

    assert changeset.valid?
  end

  test "rejects unknown icons and colors" do
    changeset =
      Category.changeset(%Category{}, %{title: "Music", icon: "../../mix", color: "beige"})

    assert {"is not a Tabler icon", _} = changeset.errors[:icon]
    assert {"is invalid", _} = changeset.errors[:color]
  end
end
