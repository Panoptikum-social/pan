defmodule PanWeb.Surface.Admin.Naming do
  alias PanWeb.Router.Helpers, as: Routes

  def model_from_resource(resource) do
    module_string =
      resource
      |> String.split("_")
      |> Enum.map(&String.capitalize(&1))
      |> Enum.join("")

    String.to_atom("Elixir.PanWeb." <> module_string)
  end

  def application() do
    {:ok, application} = :application.get_application(PanWeb.Surface.Admin.Naming)
    application
  end

  def modules do
    {:ok, modules} = :application.get_key(application(), :modules)
    modules
  end

  def schemas() do
    Enum.filter(modules(), &({:__schema__, 1} in &1.__info__(:functions)))
  end

  def model_from_join_through(join_through) do
    Enum.filter(schemas(), &(&1.__schema__(:source) == join_through))
    |> List.first()
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
      String.last(word) == "y" -> String.replace_suffix(word, "y", "ies")
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
      _ -> nil
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

  def title_from_record(record) do
    cond do
      Map.has_key?(record, :title) ->
        record.title

      Map.has_key?(record, :name) ->
        record.name

      Map.has_key?(record, :username) ->
        record.username

      Map.has_key?(record, :id) ->
        record.id

      true ->
        first_key = Map.keys(record) |> List.first()
        Map.get(record, first_key)
    end
  end

  def module_without_namespace(model) do
    model
    |> to_string()
    |> String.split(".")
    |> List.last()
  end
end
