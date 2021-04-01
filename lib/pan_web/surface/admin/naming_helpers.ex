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

  def pluralize(word) do
    cond do
      true -> word <> "s"
    end
  end
end
