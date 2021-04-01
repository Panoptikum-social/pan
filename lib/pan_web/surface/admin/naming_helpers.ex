defmodule PanWeb.Surface.Admin.Naming do
  def model_in_plural(model) do
    model
    |> Phoenix.Naming.resource_name()
    |> to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize(&1))
    |> Enum.join(" ")
    |> pluralize()
  end

  def title_from_field(field) do
    field
    |> String.split("_")
    |> Enum.map(&String.capitalize(&1))
    |> Enum.join(" ")
  end

  def pluralize(word) do
    cond do
      true -> word <> "s"
    end
  end

  def type_of_field(resource, field) do
    String.to_atom(resource).__schema__(:type, String.to_atom(field))
  end

  def index_fields(model) do
    resource =
      model
      |> Phoenix.Naming.resource_name()

    case resource do
      "podcast" -> ["id",
                    "title",
                    "update_paused",
                    "updated_at",
                    "update_intervall",
                    "next_update",
                    "failure_count",
                    "website",
                    "episodes_count"]
    end
  end
end
