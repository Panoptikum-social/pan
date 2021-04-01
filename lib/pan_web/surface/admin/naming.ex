defmodule PanWeb.Surface.Admin.Naming do
  alias PanWeb.Router.Helpers, as: Routes

  def model_from_resource(resource) do
    module_string =
      resource
      |> String.split("_")
      |> Enum.map(&String.capitalize(&1))
      |> Enum.join(" ")

    String.to_atom("Elixir.PanWeb." <> module_string)
  end

  def model_in_plural(model), do: model |> title_from_model() |> pluralize()

  def title_from_field(field) do
    field
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize(&1))
    |> Enum.join(" ")
  end

  def title_from_model(model) do
    model
    |> Phoenix.Naming.resource_name()
    |> to_string()
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
    resource.__schema__(:type, field)
  end

  def index_fields(model) do
    resource =
      model
      |> Phoenix.Naming.resource_name()

    case resource do
      "podcast" ->
        [
          :id,
          :title,
          :update_paused,
          :updated_at,
          :update_intervall,
          :next_update,
          :failure_count,
          :website,
          :episodes_count
        ]

      "episode" ->
        [:id, :guid, :publishing_date, :title, :podcast_id]
    end
  end

  def path(%{socket: socket, model: model, method: method, path_helper: nil, record: record}) do
    Routes.databrowser_path(socket, method, Phoenix.Naming.resource_name(model), record.id)
  end

  def path(%{socket: socket, model: _, method: method, path_helper: path_helper, record: record}) do
    Function.capture(Routes, path_helper, 3).(socket, method, record.id)
  end

  def path(%{socket: socket, model: model, method: method, path_helper: nil}) do
    Routes.databrowser_path(socket, method, Phoenix.Naming.resource_name(model))
  end

  def path(%{socket: socket, model: _, method: method, path_helper: path_helper}) do
    Function.capture(Routes, path_helper, 2).(socket, method)
  end
end
